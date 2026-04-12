"""
Runtime helpers for data lifecycle archive/purge jobs (identifier safety, eligibility SQL, resolve flat table).
"""
from __future__ import annotations

import logging
import re
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from classes.postgres_db import PostgresDB

logger = logging.getLogger("noolva_api.utils.data_lifecycle_sync")

_SAFE_IDENT = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def validate_sql_identifier(name: str, label: str = "identifier") -> str:
    n = (name or "").strip()
    if not n or not _SAFE_IDENT.match(n):
        raise ValueError(f"Invalid {label}: {name!r} (use letters, digits, underscore; start with letter or _)")
    return n


def quote_ident(name: str) -> str:
    n = validate_sql_identifier(name)
    return f'"{n.replace(chr(34), chr(34) + chr(34))}"'


def lifecycle_destination_table(archive_physical_name: str) -> str:
    return f"archived_{(archive_physical_name or '').strip()}"


async def resolve_archive_physical_table(
    root_table: str,
    archive_source_override: Optional[str],
) -> str:
    """Physical source table for archive reads: explicit override, else flattening target, else root."""
    o = (archive_source_override or "").strip()
    if o:
        return validate_sql_identifier(o, "archive_source_table")
    row = await PostgresDB.fetchrow(
        """
        SELECT COALESCE(NULLIF(TRIM(target_table_name), ''), '') AS ttn
        FROM public.flattening_table_policy
        WHERE table_name = $1 AND COALESCE(is_active, true)
        LIMIT 1
        """,
        validate_sql_identifier(root_table, "table_name"),
    )
    if row and (row.get("ttn") or "").strip():
        return validate_sql_identifier(row["ttn"].strip(), "flattening target_table_name")
    return validate_sql_identifier(root_table, "table_name")


async def table_exists(schema: str, table: str) -> bool:
    sch = validate_sql_identifier(schema, "schema")
    tbl = validate_sql_identifier(table, "table")
    ex = await PostgresDB.fetchrow(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = $1 AND table_name = $2
        """,
        sch,
        tbl,
    )
    return ex is not None


def _enum_tail(v: Any) -> str:
    if v is None:
        return ""
    s = str(v)
    return s.rsplit(".", 1)[-1]


def build_eligibility_sql(policy: Dict[str, Any]) -> Tuple[str, List[Any]]:
    """
    Build WHERE fragment (without leading AND) and asyncpg args for time/filter transfer modes.
    filter_condition is trusted admin SQL (fragment only).
    """
    mode = _enum_tail(policy.get("transfer_mode")) or "time_based"
    sync_strat = _enum_tail(policy.get("sync_strategy")) or "FULL"
    parts: List[str] = []
    args: List[Any] = []

    if mode in ("time_based", "time_and_condition"):
        tc = validate_sql_identifier(policy.get("time_column") or "idate", "time_column")
        qtc = quote_ident(tc)
        if sync_strat == "INCREMENTAL":
            lpv = policy.get("last_processed_value")
            if lpv is not None and str(lpv).strip():
                try:
                    if hasattr(lpv, "isoformat"):
                        args.append(lpv)
                    else:
                        args.append(datetime.fromisoformat(str(lpv).replace("Z", "+00:00")))
                except Exception:
                    args.append(lpv)
                parts.append(f"{qtc} > ${len(args)}::timestamptz")
        parts.append(f"{qtc} IS NOT NULL AND {qtc} <= now()")

    if mode in ("condition_based", "time_and_condition"):
        fc = (policy.get("filter_condition") or "").strip()
        if not fc:
            raise ValueError("filter_condition is required for this transfer_mode")
        parts.append(f"({fc})")

    if not parts:
        raise ValueError("Could not build eligibility SQL for transfer_mode")
    return " AND ".join(parts), args


async def ensure_archive_table_like_source(dest_table: str, src_table: str) -> None:
    """Create public archive table with same shape as source if missing."""
    qdest = quote_ident(dest_table)
    qsrc = quote_ident(src_table)
    await PostgresDB.execute(
        f"""
        CREATE TABLE IF NOT EXISTS public.{qdest} (LIKE public.{qsrc} INCLUDING DEFAULTS)
        """
    )


async def pick_eligible_pk_batch(
    policy: Dict[str, Any],
    src_physical: str,
    dest_table_for_dedupe: Optional[str],
    batch: int,
) -> Tuple[List[Any], str, str]:
    """Returns (pk_values, pk_quoted_ident, qsrc_quoted_ident)."""
    pk = quote_ident(validate_sql_identifier(policy.get("pk_column") or "id", "pk_column"))
    qsrc = quote_ident(src_physical)
    where_sql, args = build_eligibility_sql(policy)
    b = max(1, int(batch or 1000))

    not_exists = ""
    if dest_table_for_dedupe:
        qdest = quote_ident(dest_table_for_dedupe)
        not_exists = f"""
          AND NOT EXISTS (SELECT 1 FROM public.{qdest} d WHERE d.{pk} = s.{pk})
        """

    lim_idx = len(args) + 1
    args_with_limit = list(args) + [b]

    pick_sql = f"""
        SELECT s.{pk} AS pk
        FROM public.{qsrc} s
        WHERE {where_sql}
        {not_exists}
        ORDER BY s.{pk}
        LIMIT ${lim_idx}
    """
    rows = await PostgresDB.fetch(pick_sql, *args_with_limit)
    if not rows:
        return [], pk, qsrc
    pk_vals = [r["pk"] for r in rows]
    return pk_vals, pk, qsrc


async def archive_batch_postgres(policy: Dict[str, Any], src_physical: str, dest_table: str) -> Tuple[int, Optional[Any]]:
    """
    Insert up to sync_batch_size rows from src into dest per eligibility; skip rows already in dest.
    Returns (inserted_count, new_last_processed_value or None).
    """
    batch = max(1, int(policy.get("sync_batch_size") or 1000))
    qdest = quote_ident(dest_table)
    pk_vals, pk, qsrc = await pick_eligible_pk_batch(policy, src_physical, dest_table, batch)
    if not pk_vals:
        return 0, None

    str_vals = [str(v) for v in pk_vals]
    ins_sql = f"""
        INSERT INTO public.{qdest}
        SELECT * FROM public.{qsrc} s
        WHERE s.{pk}::text = ANY($1::text[])
    """
    await PostgresDB.execute(ins_sql, str_vals)

    mode = _enum_tail(policy.get("transfer_mode")) or "time_based"
    sync_strat = _enum_tail(policy.get("sync_strategy")) or "FULL"
    time_col = None
    if mode in ("time_based", "time_and_condition") and sync_strat == "INCREMENTAL":
        time_col = quote_ident(validate_sql_identifier(policy.get("time_column") or "idate", "time_column"))
    new_lp = None
    if time_col:
        mx = await PostgresDB.fetchrow(
            f"""
            SELECT MAX(s.{time_col}) AS m
            FROM public.{qsrc} s
            WHERE s.{pk}::text = ANY($1::text[])
            """,
            str_vals,
        )
        if mx and mx.get("m") is not None:
            new_lp = mx["m"]

    return len(pk_vals), new_lp


async def purge_batch_postgres(policy: Dict[str, Any], src_physical: str, dest_table: str, root_table: str) -> Tuple[int, int]:
    """
    Delete one batch: rows present in both flat src and archive dest and matching eligibility, then root rows.
    Returns (flat_deleted, root_deleted).
    """
    n_flat, n_root, _, _ = await purge_tier1_flat_and_root(
        policy, src_physical, dest_table, root_table, separate_children=None
    )
    return n_flat, n_root


async def flattening_separate_child_tables(root_table: str) -> List[str]:
    """target_table names for separate strategy relations under flattening root."""
    rows = await PostgresDB.fetch(
        """
        SELECT NULLIF(TRIM(target_table::text), '') AS target_table
        FROM public.flattening_relation_policy
        WHERE table_name = $1 AND strategy = 'separate'
          AND target_table IS NOT NULL
        """,
        validate_sql_identifier(root_table, "lifecycle_root"),
    )
    return [r["target_table"] for r in rows if r.get("target_table")]


async def resolve_child_fk_column_to_parent(child_table: str, parent_table: str, root_pk_column: str) -> Optional[str]:
    """
    Find the child table column that is a single-column FK to parent_table.
    Prefer the FK that references parent.root_pk_column on the parent side.
    Does not guess: returns None if no unambiguous single-column FK exists.
    """
    ch = validate_sql_identifier(child_table, "child_table")
    par = validate_sql_identifier(parent_table, "parent_table")
    pkref = (root_pk_column or "id").strip()
    if not pkref or not _SAFE_IDENT.match(pkref):
        return None

    row = await PostgresDB.fetchrow(
        """
        SELECT a.attname::text AS fk_col
        FROM pg_constraint c
        JOIN pg_class tc ON tc.oid = c.conrelid
        JOIN pg_namespace tn ON tn.oid = tc.relnamespace
        JOIN pg_class rc ON rc.oid = c.confrelid
        JOIN pg_namespace rn ON rn.oid = rc.relnamespace
        JOIN unnest(c.conkey) WITH ORDINALITY AS u(attnum, ord) ON true
        JOIN unnest(c.confkey) WITH ORDINALITY AS u2(attnum2, ord2) ON u.ord = u2.ord2
        JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = u.attnum AND NOT a.attisdropped
        JOIN pg_attribute ar ON ar.attrelid = rc.oid AND ar.attnum = u2.attnum2 AND NOT ar.attisdropped
        WHERE c.contype = 'f'
          AND cardinality(c.conkey) = 1
          AND tn.nspname = 'public' AND tc.relname = $1::name
          AND rn.nspname = 'public' AND rc.relname = $2::name
          AND ar.attname = $3::name
        ORDER BY c.oid
        LIMIT 1
        """,
        ch,
        par,
        pkref,
    )
    if row and row.get("fk_col"):
        return validate_sql_identifier(row["fk_col"], "fk_column")

    cnt = await PostgresDB.fetchval(
        """
        SELECT COUNT(DISTINCT c.oid)::int
        FROM pg_constraint c
        JOIN pg_class tc ON tc.oid = c.conrelid
        JOIN pg_namespace tn ON tn.oid = tc.relnamespace
        JOIN pg_class rc ON rc.oid = c.confrelid
        JOIN pg_namespace rn ON rn.oid = rc.relnamespace
        WHERE c.contype = 'f'
          AND cardinality(c.conkey) = 1
          AND tn.nspname = 'public' AND tc.relname = $1::name
          AND rn.nspname = 'public' AND rc.relname = $2::name
        """,
        ch,
        par,
    )
    if (cnt or 0) != 1:
        if (cnt or 0) > 1:
            logger.warning(
                "resolve_child_fk_column_to_parent: ambiguous — %s single-column FKs from public.%s to public.%s (expected FK to %s.%s)",
                cnt,
                ch,
                par,
                par,
                pkref,
            )
        return None

    row_any = await PostgresDB.fetchrow(
        """
        SELECT a.attname::text AS fk_col
        FROM pg_constraint c
        JOIN pg_class tc ON tc.oid = c.conrelid
        JOIN pg_namespace tn ON tn.oid = tc.relnamespace
        JOIN pg_class rc ON rc.oid = c.confrelid
        JOIN pg_namespace rn ON rn.oid = rc.relnamespace
        JOIN unnest(c.conkey) WITH ORDINALITY AS u(attnum, ord) ON true
        JOIN unnest(c.confkey) WITH ORDINALITY AS u2(attnum2, ord2) ON u.ord = u2.ord2
        JOIN pg_attribute a ON a.attrelid = tc.oid AND a.attnum = u.attnum AND NOT a.attisdropped
        WHERE c.contype = 'f'
          AND cardinality(c.conkey) = 1
          AND tn.nspname = 'public' AND tc.relname = $1::name
          AND rn.nspname = 'public' AND rc.relname = $2::name
        LIMIT 1
        """,
        ch,
        par,
    )
    if row_any and row_any.get("fk_col"):
        logger.warning(
            "resolve_child_fk_column_to_parent: FK column %s.%s -> %s does not reference parent column %s (using sole single-column FK)",
            ch,
            row_any["fk_col"],
            par,
            pkref,
        )
        return validate_sql_identifier(row_any["fk_col"], "fk_column")
    return None


async def purge_tier1_flat_and_root(
    policy: Dict[str, Any],
    flat_physical: str,
    archive_physical: str,
    root_table: str,
    separate_children: Optional[List[str]] = None,
) -> Tuple[int, int, int, List[Any]]:
    """
    Pick PKs in flat ∩ archive, delete from separate child tables (FK resolved via pg_catalog), then flat, then root.
    Returns (flat_deleted, root_deleted, children_deleted_rows_total, picked_pks).
    """
    pk_col = validate_sql_identifier(policy.get("pk_column") or "id", "pk_column")
    pk = quote_ident(pk_col)
    qflat = quote_ident(flat_physical)
    qarch = quote_ident(archive_physical)
    qroot = quote_ident(validate_sql_identifier(root_table, "root_table"))
    where_sql, args = build_eligibility_sql(policy)
    batch = max(1, int(policy.get("sync_batch_size") or 1000))
    lim_idx = len(args) + 1
    args_pick = list(args) + [batch]

    pick_sql = f"""
        SELECT s.{pk} AS pk
        FROM public.{qflat} s
        INNER JOIN public.{qarch} d ON d.{pk} = s.{pk}
        WHERE {where_sql}
        ORDER BY s.{pk}
        LIMIT ${lim_idx}
    """
    picked_rows = await PostgresDB.fetch(pick_sql, *args_pick)
    if not picked_rows:
        return 0, 0, 0, []

    pk_vals = [r["pk"] for r in picked_rows]
    str_vals = [str(v) for v in pk_vals]
    children = separate_children if separate_children is not None else await flattening_separate_child_tables(root_table)

    child_deleted = 0
    for child in children:
        if child == flat_physical or child == root_table:
            logger.warning("purge_tier1: skip child same as flat or root: %s", child)
            continue
        try:
            fk_col_name = await resolve_child_fk_column_to_parent(child, root_table, pk_col)
            if not fk_col_name:
                logger.warning(
                    "purge_tier1: no single-column FK from public.%s to public.%s — skip child purge",
                    child,
                    root_table,
                )
                continue
            fk_q = quote_ident(fk_col_name)
            qc = quote_ident(validate_sql_identifier(child, "child_table"))
            tag = await PostgresDB.execute(
                f"""
                DELETE FROM public.{qc} c
                WHERE c.{fk_q}::text = ANY($1::text[])
                """,
                str_vals,
            )
            if tag and str(tag).startswith("DELETE "):
                try:
                    child_deleted += int(str(tag).split()[-1])
                except (TypeError, ValueError):
                    pass
        except Exception:
            logger.exception("purge_tier1: failed deleting child table %s", child)

    flat_tag = await PostgresDB.execute(
        f"""
        DELETE FROM public.{qflat} f
        WHERE f.{pk}::text = ANY($1::text[])
        """,
        str_vals,
    )
    root_tag = await PostgresDB.execute(
        f"""
        DELETE FROM public.{qroot} r
        WHERE r.{pk}::text = ANY($1::text[])
        """,
        str_vals,
    )

    def _delete_n(tag: str) -> int:
        if not tag or not str(tag).startswith("DELETE "):
            return 0
        try:
            return int(str(tag).split()[-1])
        except (TypeError, ValueError):
            return 0

    return _delete_n(flat_tag), _delete_n(root_tag), child_deleted, pk_vals


async def delete_archived_rows_by_pk(archived_table: str, pk_column: str, pk_values: List[Any]) -> int:
    """Tier-2 purge: delete PKs from archived_* after Iceberg export ledger."""
    if not pk_values:
        return 0
    qtbl = quote_ident(validate_sql_identifier(archived_table, "archived_table"))
    pk = quote_ident(validate_sql_identifier(pk_column, "pk_column"))
    str_vals = [str(v) for v in pk_values]
    tag = await PostgresDB.execute(
        f"""
        DELETE FROM public.{qtbl} t
        WHERE t.{pk}::text = ANY($1::text[])
        """,
        str_vals,
    )
    if tag and str(tag).startswith("DELETE "):
        try:
            return int(str(tag).split()[-1])
        except (TypeError, ValueError):
            return 0
    return 0
