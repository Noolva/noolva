"""
Refresh one flattening_table_policy row.

Implements checkpoint/signature logic using:
- last_refreshed: last successful run time
- last_processed_value (TIMESTAMPTZ): checkpoint / signature timestamp

Rules (as discussed):
- destination=s3: compute signature_ts from policy.last_updated + source MAX(change_col).
  Only write to S3 when signature differs; after write set last_processed_value=signature_ts.
  If user modifies policy/config, policy.last_updated changes and forces next S3 write.
  Relation policy create/update/delete bumps parental flattening_table_policy.last_updated so S3
  re-exports pick up new flattening_relation_policy without a hot-table change.
  Job payload {"force": true} skips the signature check and always re-uploads (e.g. after manual
  S3 deletion or to re-emit JSON shape). Clearing last_processed_value on the policy also works.
  S3 export uses the same SELECT shape as postgres materialization (m2o denormalize + o2m json).
- destination=postgres: FULL uses policy.last_updated as signature checkpoint;
  INCREMENTAL uses MAX(change_col) of newly changed rows as checkpoint (engine TBD).
"""

import json
import logging
import re
from datetime import datetime, timezone
from io import BytesIO
from typing import Any, Dict, List, Optional, Tuple

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.refresh_flattening_table")

_SAFE_IDENTIFIER_RE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


def _is_safe_identifier(value: str) -> bool:
    return bool(_SAFE_IDENTIFIER_RE.fullmatch(value or ""))


def _to_utc_dt(v: Any) -> Optional[datetime]:
    if v is None:
        return None
    if isinstance(v, datetime):
        return v.astimezone(timezone.utc) if v.tzinfo else v.replace(tzinfo=timezone.utc)
    return None


async def _get_best_change_column(table_name: str) -> Optional[str]:
    """
    Pick best available "last change" timestamp column.
    """
    from classes.postgres_db import PostgresDB

    candidates = ["last_updated", "updated_at", "modified_at", "updated_on", "idate"]
    row = await PostgresDB.fetchrow(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name = $1
          AND column_name = ANY($2::text[])
        ORDER BY CASE column_name
          WHEN 'last_updated' THEN 1
          WHEN 'updated_at' THEN 2
          WHEN 'modified_at' THEN 3
          WHEN 'updated_on' THEN 4
          WHEN 'idate' THEN 5
          ELSE 99
        END
        LIMIT 1
        """,
        table_name,
        candidates,
    )
    return row["column_name"] if row else None


async def _get_primary_key_column(table_name: str) -> str:
    from classes.postgres_db import PostgresDB

    row = await PostgresDB.fetchrow(
        """
        SELECT kcu.column_name
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        WHERE tc.table_schema = 'public'
          AND tc.table_name = $1
          AND tc.constraint_type = 'PRIMARY KEY'
        ORDER BY kcu.ordinal_position
        LIMIT 1
        """,
        table_name,
    )
    return (row["column_name"] if row and row.get("column_name") else "id")


async def _get_table_columns(table_name: str) -> list[str]:
    from classes.postgres_db import PostgresDB

    rows = await PostgresDB.fetch(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1
        ORDER BY ordinal_position
        """,
        table_name,
    )
    return [r["column_name"] for r in (rows or []) if r.get("column_name")]


def _aliasize(value: str) -> str:
    # Make a safe identifier-ish alias from arbitrary relation keys.
    v = re.sub(r"[^A-Za-z0-9_]+", "_", value or "").strip("_")
    if not v:
        v = "rel"
    if not re.match(r"^[A-Za-z_]", v):
        v = f"r_{v}"
    return v


async def _resolve_fk_target(source_table: str, fk_column: str) -> tuple[Optional[str], Optional[str]]:
    """
    Resolve FK (source_table.fk_column) -> (ref_table, ref_column) using information_schema.
    """
    from classes.postgres_db import PostgresDB

    row = await PostgresDB.fetchrow(
        """
        SELECT
          ccu.table_name AS ref_table,
          ccu.column_name AS ref_column
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
          ON tc.constraint_name = kcu.constraint_name
         AND tc.table_schema = kcu.table_schema
        JOIN information_schema.constraint_column_usage ccu
          ON ccu.constraint_name = tc.constraint_name
         AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public'
          AND tc.table_name = $1
          AND kcu.column_name = $2
        LIMIT 1
        """,
        source_table,
        fk_column,
    )
    if not row:
        return None, None
    return row.get("ref_table"), row.get("ref_column")


def _first_value(row: Any) -> Any:
    """
    Given a PostgresDB.fetchrow result, return the first column value.
    """
    if not row:
        return None
    if isinstance(row, dict):
        for k in row.keys():
            return row.get(k)
        return None
    try:
        return row[0]
    except Exception:
        return None


def _normalize_for_json_file(value: Any) -> Any:
    """
    Ensure value is a JSON-serializable structure for S3 flatten exports.

    asyncpg (and some json_agg paths) may return JSON already as a Python ``str``.
    json.dumps on that produces a double-encoded file (body starts with ``"[``),
    which breaks clients that expect a top-level array/object after ``response.json()``.
    """
    if value is None:
        return []
    if isinstance(value, (bytes, bytearray)):
        value = value.decode("utf-8")
    if isinstance(value, str):
        stripped = (value or "").strip()
        if not stripped:
            return []
        if stripped[0] in "[{" or (stripped[0] == '"' and len(stripped) > 1 and stripped[1] in "[{"):
            try:
                return json.loads(value)
            except json.JSONDecodeError:
                pass
        return value
    return value


async def _build_flatten_materialize_fragments(table_name: str) -> Tuple[
    str,
    List[str],
    List[str],
    List[str],
    List[str],
    List[str],
]:
    """
    Shared SQL fragments for flattening: same row shape as postgres INSERT into flat_*.
    Returns (pk_col, source_cols, joins, select_exprs, insert_cols, update_sets).
    """
    from classes.postgres_db import PostgresDB

    pk_col = await _get_primary_key_column(table_name)
    if not _is_safe_identifier(pk_col):
        raise ValueError(f"Unsafe pk column: {pk_col!r}")

    source_cols = await _get_table_columns(table_name)
    if pk_col not in source_cols:
        raise ValueError(f"Primary key column {pk_col!r} not found on source table {table_name!r}")

    rel_rows = await PostgresDB.fetch(
        """
        SELECT relation_name, relation_type, strategy, include_fields, target_table
        FROM public.flattening_relation_policy
        WHERE table_name = $1
        ORDER BY id
        """,
        table_name,
    )

    joins: list[str] = []
    select_exprs: list[str] = [f's."{c}"' for c in source_cols]
    insert_cols: list[str] = [f'"{c}"' for c in source_cols]
    update_sets: list[str] = [f'"{c}" = EXCLUDED."{c}"' for c in source_cols if c != pk_col]

    for rr in rel_rows or []:
        rel_name = (rr.get("relation_name") or "").strip()
        rtype = (rr.get("relation_type") or "").strip().lower()
        strategy = (rr.get("strategy") or "").strip().lower()
        include_fields = rr.get("include_fields") or []
        if isinstance(include_fields, str):
            include_fields = [x.strip() for x in include_fields.split(",") if x.strip()]
        if not isinstance(include_fields, list):
            include_fields = []

        if rtype == "m2o" and strategy == "denormalize":
            fk_col = rel_name
            if not _is_safe_identifier(fk_col) or fk_col not in source_cols:
                continue
            ref_table, ref_col = await _resolve_fk_target(table_name, fk_col)
            if not ref_table or not ref_col or not _is_safe_identifier(ref_table) or not _is_safe_identifier(ref_col):
                continue
            ref_cols = await _get_table_columns(ref_table)
            alias = _aliasize(f"{fk_col}_ref")
            joins.append(f'LEFT JOIN public."{ref_table}" {alias} ON {alias}."{ref_col}" = s."{fk_col}"')
            for f in include_fields:
                if not _is_safe_identifier(f) or f not in ref_cols:
                    continue
                out_col = _aliasize(f"{fk_col}__{f}")
                insert_cols.append(f'"{out_col}"')
                select_exprs.append(f'{alias}."{f}"::text AS "{out_col}"')
                update_sets.append(f'"{out_col}" = EXCLUDED."{out_col}"')

        if rtype == "o2m" and strategy in ("json", "separate"):
            if "." not in rel_name:
                continue
            child_table, child_fk = rel_name.split(".", 1)
            child_table = child_table.strip()
            child_fk = child_fk.strip()
            if not _is_safe_identifier(child_table) or not _is_safe_identifier(child_fk):
                continue
            out_col = _aliasize(f"{child_table}_items")
            insert_cols.append(f'"{out_col}"')
            select_exprs.append(
                f'(SELECT COALESCE(json_agg(c), \'[]\'::json) FROM public."{child_table}" c WHERE c."{child_fk}" = s."{pk_col}")::jsonb AS "{out_col}"'
            )
            update_sets.append(f'"{out_col}" = EXCLUDED."{out_col}"')

    return pk_col, source_cols, joins, select_exprs, insert_cols, update_sets


async def refresh_flattening_table(payload: Dict[str, Any]) -> Dict[str, Any]:
    # Worker payload may arrive as JSON string depending on job template wiring.
    if isinstance(payload, str):
        try:
            payload = json.loads(payload)
        except Exception as e:
            raise ValueError("refresh_flattening_table payload must be JSON object (dict)") from e
    if not isinstance(payload, dict):
        raise ValueError("refresh_flattening_table payload must be an object (dict)")
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")
    from classes.postgres_db import PostgresDB

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, destination, is_public_on_s3,
               target_table_name, is_db_table,
               refresh_strategy, refresh_interval_minutes, batch_size,
               last_refreshed, last_processed_value, is_snapshot, is_active,
               created_at, last_updated
        FROM public.flattening_table_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"flattening_table_policy not found: {policy_id}")
    if row.get("is_snapshot") is True:
        # Snapshot is deprecated; treat as active by flipping it off.
        await PostgresDB.execute(
            "UPDATE public.flattening_table_policy SET is_snapshot = false, last_updated = now() WHERE id = $1",
            int(policy_id),
        )
        row = {**dict(row), "is_snapshot": False}
    if row.get("is_active") is False:
        logger.info("refresh_flattening_table: policy %s is inactive, skipping refresh", policy_id)
        return {"ok": True, "skipped": True, "reason": "inactive"}

    table_name = (row.get("table_name") or "").strip()
    if not _is_safe_identifier(table_name):
        raise ValueError(f"Unsafe table_name: {table_name!r}")

    dest = (row.get("destination") or "postgres").strip().lower()
    strat = row["refresh_strategy"]

    # ---------------- destination: S3 ----------------
    if dest == "s3":
        if row.get("is_public_on_s3") is None:
            raise ValueError("is_public_on_s3 is required when destination is s3")

        policy_last_updated = _to_utc_dt(row.get("last_updated"))
        last_processed = _to_utc_dt(row.get("last_processed_value"))
        change_col = await _get_best_change_column(table_name)

        source_max_ts = None
        if change_col:
            source_max_row = await PostgresDB.fetchrow(
                f'SELECT MAX("{change_col}") AS v FROM public."{table_name}"'
            )
            source_max_ts = _first_value(source_max_row)
            source_max_ts = _to_utc_dt(source_max_ts)

        signature_candidates = [dt for dt in (policy_last_updated, source_max_ts) if dt is not None]
        signature_ts = max(signature_candidates) if signature_candidates else None

        force = bool(payload.get("force"))
        if (
            not force
            and signature_ts is not None
            and last_processed is not None
            and last_processed >= signature_ts
        ):
            logger.info(
                "refresh_flattening_table: policy %s table=%s dest=s3 signature unchanged, skipping",
                policy_id,
                table_name,
            )
            return {
                "ok": True,
                "skipped": True,
                "reason": "signature_unchanged",
                "policy_id": int(policy_id),
                "table_name": table_name,
                "destination": "s3",
                "signature_ts": signature_ts.isoformat(),
            }

        # Export full table (expected small for S3 use-cases); same row shape as postgres flat materialization.
        logger.info(
            "refresh_flattening_table: policy %s table=%s dest=s3 exporting (strategy=%s change_col=%s force=%s)",
            policy_id,
            table_name,
            strat,
            change_col,
            force,
        )
        _pk_col, _src_cols, joins, select_exprs, _ic, _us = await _build_flatten_materialize_fragments(table_name)
        export_sql = f"""
        SELECT COALESCE(json_agg(r), '[]'::json) AS v
        FROM (
            SELECT {", ".join(select_exprs)}
            FROM public."{table_name}" s
            {" ".join(joins)}
        ) r
        """
        data_row = await PostgresDB.fetchrow(export_sql)
        data_json = _normalize_for_json_file(_first_value(data_row))
        json_bytes = (json.dumps(data_json, default=str) + "\n").encode("utf-8")

        # Upload to default S3 integration
        from routes.upload import _get_default_s3_service

        s3 = await _get_default_s3_service(None)
        is_public = bool(row.get("is_public_on_s3"))
        vis_prefix = "public" if is_public else "private"
        # Folder is hardcoded as 'flattened'
        s3_key = f"{vis_prefix}/flattened/{table_name}.json"
        meta = {
            "policy_id": str(int(policy_id)),
            "table_name": table_name,
            "destination": "s3",
            "refresh_strategy": str(strat or ""),
            "signature_ts": signature_ts.isoformat() if signature_ts else "",
        }
        res = s3.upload_fileobj(
            BytesIO(json_bytes),
            s3_key=s3_key,
            is_public=is_public,
            content_type="application/json",
            metadata=meta,
        )
        if not res.get("success"):
            raise ValueError(f"S3 upload failed: {res.get('message') or res}")

        await PostgresDB.execute(
            """
            UPDATE public.flattening_table_policy
            SET last_refreshed = now(),
                last_processed_value = $2,
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
            signature_ts or datetime.now(timezone.utc),
        )
        return {
            "ok": True,
            "policy_id": int(policy_id),
            "table_name": table_name,
            "destination": "s3",
            "refresh_strategy": strat,
            "s3_key": res.get("s3_key"),
            "public_url": res.get("public_url"),
            "signature_ts": signature_ts.isoformat() if signature_ts else None,
            "engine": "checkpoint+s3_export_relations",
            "forced": force,
        }

    # ---------------- destination: Iceberg (planned) ----------------
    if dest == "iceberg":
        logger.warning("refresh_flattening_table: iceberg not implemented for policy %s", policy_id)
        return {"ok": True, "skipped": True, "reason": "iceberg_not_implemented", "policy_id": int(policy_id)}

    # ---------------- destination: Postgres ----------------
    target_table = (row.get("target_table_name") or f"flat_{table_name}").strip()
    if not _is_safe_identifier(target_table):
        raise ValueError(f"Unsafe target_table_name: {target_table!r}")

    pk_col, _source_cols, joins, select_exprs, insert_cols, update_sets = await _build_flatten_materialize_fragments(
        table_name
    )

    # Build and run FULL / INCREMENTAL materialization
    change_col = await _get_best_change_column(table_name)
    if change_col and not _is_safe_identifier(change_col):
        change_col = None

    batch_size = row.get("batch_size")
    try:
        batch_size_int = int(batch_size) if batch_size is not None else None
    except Exception:
        batch_size_int = None

    if strat == "INCREMENTAL" and change_col:
        last_processed = _to_utc_dt(row.get("last_processed_value"))
        limit_sql = f"LIMIT {batch_size_int}" if batch_size_int and batch_size_int > 0 else ""
        changed_rows = await PostgresDB.fetch(
            f"""
            SELECT s."{pk_col}" AS pk, s."{change_col}" AS ck
            FROM public."{table_name}" s
            WHERE ($1::timestamptz IS NULL OR s."{change_col}" > $1::timestamptz)
            ORDER BY s."{change_col}" ASC
            {limit_sql}
            """,
            last_processed,
        )
        pks = [r["pk"] for r in (changed_rows or []) if r.get("pk") is not None]
        new_ck = None
        if changed_rows:
            new_ck = max([r.get("ck") for r in changed_rows if r.get("ck") is not None], default=None)
        if not pks:
            # If the flat table is empty but incremental found no changed rows, do a safety FULL rebuild.
            # This covers first-run or checkpoint drift scenarios.
            cnt_row = await PostgresDB.fetchrow(f'SELECT COUNT(*) AS c FROM public."{target_table}"')
            flat_count = int((cnt_row or {}).get("c") or 0)
            if flat_count == 0:
                await PostgresDB.execute(f'TRUNCATE TABLE public."{target_table}"')
                full_sql = f"""
                INSERT INTO public."{target_table}" ({", ".join(insert_cols)})
                SELECT {", ".join(select_exprs)}
                FROM public."{table_name}" s
                {" ".join(joins)}
                """
                await PostgresDB.execute(full_sql)
                await PostgresDB.execute(
                    """
                    UPDATE public.flattening_table_policy
                    SET last_refreshed = now(),
                        last_processed_value = now(),
                        last_updated = now()
                    WHERE id = $1
                    """,
                    int(policy_id),
                )
                return {
                    "ok": True,
                    "policy_id": int(policy_id),
                    "table_name": table_name,
                    "destination": "postgres",
                    "refresh_strategy": strat,
                    "target_table": target_table,
                    "updated_rows": 0,
                    "engine": "postgres_full_rebuild_fallback",
                }

            await PostgresDB.execute(
                "UPDATE public.flattening_table_policy SET last_refreshed = now(), last_updated = now() WHERE id = $1",
                int(policy_id),
            )
            return {
                "ok": True,
                "policy_id": int(policy_id),
                "table_name": table_name,
                "destination": "postgres",
                "refresh_strategy": strat,
                "target_table": target_table,
                "updated_rows": 0,
                "engine": "postgres_incremental_upsert",
            }

        sql = f"""
        INSERT INTO public."{target_table}" ({", ".join(insert_cols)})
        SELECT {", ".join(select_exprs)}
        FROM public."{table_name}" s
        {" ".join(joins)}
        WHERE s."{pk_col}" = ANY($1)
        ON CONFLICT ("{pk_col}") DO UPDATE SET
          {", ".join(update_sets)}
        """
        await PostgresDB.execute(sql, pks)

        await PostgresDB.execute(
            """
            UPDATE public.flattening_table_policy
            SET last_refreshed = now(),
                last_processed_value = COALESCE($2, last_processed_value),
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
            _to_utc_dt(new_ck),
        )
        return {
            "ok": True,
            "policy_id": int(policy_id),
            "table_name": table_name,
            "destination": "postgres",
            "refresh_strategy": strat,
            "target_table": target_table,
            "updated_rows": len(pks),
            "checkpoint_column": change_col,
            "new_checkpoint": (_to_utc_dt(new_ck).isoformat() if _to_utc_dt(new_ck) else None),
            "engine": "postgres_incremental_upsert",
        }

    # FULL refresh: rebuild target from scratch
    await PostgresDB.execute(f'TRUNCATE TABLE public."{target_table}"')
    full_sql = f"""
    INSERT INTO public."{target_table}" ({", ".join(insert_cols)})
    SELECT {", ".join(select_exprs)}
    FROM public."{table_name}" s
    {" ".join(joins)}
    """
    await PostgresDB.execute(full_sql)
    await PostgresDB.execute(
        """
        UPDATE public.flattening_table_policy
        SET last_refreshed = now(),
            last_processed_value = now(),
            last_updated = now()
        WHERE id = $1
        """,
        int(policy_id),
    )
    return {
        "ok": True,
        "policy_id": int(policy_id),
        "table_name": table_name,
        "destination": "postgres",
        "refresh_strategy": strat,
        "target_table": target_table,
        "engine": "postgres_full_rebuild",
    }


register_handler("refresh_flattening_table", refresh_flattening_table)
