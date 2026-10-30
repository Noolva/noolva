"""
Refresh one flattening_table_policy row (postgres destination):
materialize the flat target table = source columns + m2o denormalized fields + o2m JSON children.
"""
import logging
from typing import Any, Dict, List, Tuple

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.refresh_flattening_table")


async def _load_relation_specs(source_table: str) -> Tuple[List[Dict[str, Any]], List[Dict[str, Any]]]:
    """Return (denormalize specs, o2m json specs) for a flattening source table."""
    from classes.postgres_db import PostgresDB
    from utils.flattening_materializer import (
        aliasize,
        get_primary_key_column,
        get_table_columns,
        is_safe_identifier,
        resolve_relation_target,
    )

    rows = await PostgresDB.fetch(
        """
        SELECT relation_name, relation_type, strategy, include_fields, target_table
        FROM public.flattening_relation_policy
        WHERE table_name = $1
        ORDER BY id
        """,
        source_table,
    )
    denorm: List[Dict[str, Any]] = []
    json_specs: List[Dict[str, Any]] = []
    for rr in rows or []:
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
            if not is_safe_identifier(fk_col):
                logger.warning("refresh_flattening_table: unsafe m2o relation %r — skipped", rel_name)
                continue
            ref_table, ref_col = await resolve_relation_target(source_table, fk_col)
            if not ref_table or not is_safe_identifier(ref_table):
                logger.warning(
                    "refresh_flattening_table: cannot resolve m2o target for %s.%s — skipped",
                    source_table,
                    fk_col,
                )
                continue
            ref_col = (ref_col or "").strip()
            if not ref_col or not is_safe_identifier(ref_col):
                pk_ref = await get_primary_key_column(ref_table)
                ref_col = pk_ref
            ref_cols = await get_table_columns(ref_table)
            fields: List[Tuple[str, str]] = []
            for f in include_fields:
                if not is_safe_identifier(f) or f not in ref_cols:
                    continue
                fields.append((f, aliasize(f"{fk_col}__{f}")))
            if not fields:
                continue
            denorm.append(
                {
                    "fk_col": fk_col,
                    "ref_table": ref_table,
                    "ref_col": ref_col,
                    "fields": fields,
                }
            )

        if rtype == "o2m" and strategy == "json":
            if "." not in rel_name:
                logger.warning("refresh_flattening_table: o2m json relation must be child.fk — %r skipped", rel_name)
                continue
            child_table, child_fk = rel_name.split(".", 1)
            child_table = child_table.strip()
            child_fk = child_fk.strip()
            if not is_safe_identifier(child_table) or not is_safe_identifier(child_fk):
                logger.warning("refresh_flattening_table: unsafe o2m relation %r — skipped", rel_name)
                continue
            child_cols = await get_table_columns(child_table)
            if child_fk not in child_cols:
                logger.warning(
                    "refresh_flattening_table: o2m child %s has no column %s — skipped",
                    child_table,
                    child_fk,
                )
                continue
            child_pk = await get_primary_key_column(child_table)
            json_specs.append(
                {
                    "child_table": child_table,
                    "child_fk": child_fk,
                    "child_pk": child_pk,
                    "has_idate": "idate" in child_cols,
                    "out_col": aliasize(f"{child_table}_items"),
                }
            )
    return denorm, json_specs


def _json_select_expr(spec: Dict[str, Any], pk: str) -> str:
    child = spec["child_table"]
    fk = spec["child_fk"]
    cpk = spec["child_pk"]
    if spec.get("has_idate"):
        order = f'c."idate" ASC NULLS FIRST, c."{cpk}" ASC'
    else:
        order = f'c."{cpk}" ASC'
    return (
        f'(SELECT COALESCE(jsonb_agg(to_jsonb(c) ORDER BY {order}), \'[]\'::jsonb) '
        f'FROM public."{child}" c WHERE c."{fk}"::text = s."{pk}"::text) AS "{spec["out_col"]}"'
    )


async def refresh_flattening_table(payload: Dict[str, Any]) -> Dict[str, Any]:
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")
    from classes.postgres_db import PostgresDB
    from utils.flattening_materializer import (
        ensure_flattened_table_and_model,
        get_primary_key_column,
        get_table_columns,
        is_safe_identifier,
    )
    from utils.flattening_policy import ensure_flattening_read_endpoints

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, target_table_name, refresh_strategy, batch_size,
               last_processed_value, destination, is_snapshot
        FROM public.flattening_table_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"flattening_table_policy not found: {policy_id}")
    if row["is_snapshot"]:
        logger.info("refresh_flattening_table: policy %s is snapshot, skipping refresh", policy_id)
        return {"ok": True, "skipped": True, "reason": "snapshot"}

    dest = (row.get("destination") or "postgres").strip().lower()
    if dest != "postgres":
        logger.info(
            "refresh_flattening_table: policy %s destination=%s — engine runs for postgres only, skipping",
            policy_id,
            dest,
        )
        return {"ok": True, "skipped": True, "reason": f"destination_{dest}_not_in_engine"}

    source = (row["table_name"] or "").strip()
    target = (row.get("target_table_name") or "").strip() or f"flat_{source}"
    if not is_safe_identifier(source) or not is_safe_identifier(target):
        raise ValueError(f"Unsafe table names: source={source!r} target={target!r}")

    strat = (row.get("refresh_strategy") or "FULL").strip().upper()
    batch_size = max(1, int(row.get("batch_size") or 1000))

    if not await get_table_columns(source):
        raise ValueError(f"Source table not found or empty: public.{source}")

    ensure_info = await ensure_flattened_table_and_model(
        policy_id=int(policy_id),
        source_table=source,
        target_table=target,
        created_by=None,
    )
    read_paths = await ensure_flattening_read_endpoints(int(policy_id), target, None)

    denorm, json_specs = await _load_relation_specs(source)

    pk = await get_primary_key_column(source)
    if not is_safe_identifier(pk):
        raise ValueError(f"Unsafe pk column on {source}: {pk!r}")
    src_cols = [c for c in await get_table_columns(source) if is_safe_identifier(c)]
    flat_cols = set(await get_table_columns(target))

    join_clauses: List[str] = []
    select_parts: List[str] = [f's."{c}"' for c in src_cols if c in flat_cols]
    insert_cols: List[str] = [c for c in src_cols if c in flat_cols]

    for i, d in enumerate(denorm, start=1):
        alias = f"t{i}"
        # ::text join tolerates varchar<->int logical FKs (e.g. my_tasks.priority -> task_priorities.priority_id)
        join_clauses.append(
            f'LEFT JOIN public."{d["ref_table"]}" {alias} '
            f'ON s."{d["fk_col"]}"::text = {alias}."{d["ref_col"]}"::text'
        )
        for field, out_col in d["fields"]:
            if out_col not in flat_cols:
                continue
            select_parts.append(f'{alias}."{field}"')
            insert_cols.append(out_col)

    for js in json_specs:
        if js["out_col"] not in flat_cols:
            continue
        select_parts.append(_json_select_expr(js, pk))
        insert_cols.append(js["out_col"])

    if not insert_cols:
        raise ValueError(f"No materializable columns for {source} -> {target}")

    incremental = strat == "INCREMENTAL" and "last_updated" in src_cols
    lp = row.get("last_processed_value")
    where = ""
    where_args: List[Any] = []
    if incremental and lp is not None:
        where = 'WHERE s."last_updated" > $1'
        where_args = [lp]

    pk_rows = await PostgresDB.fetch(
        f'SELECT s."{pk}" AS pk FROM public."{source}" s {where} ORDER BY s."{pk}"',
        *where_args,
    )
    pk_vals = [r["pk"] for r in (pk_rows or [])]

    insert_sql = (
        f'INSERT INTO public."{target}" ({", ".join(chr(34) + c + chr(34) for c in insert_cols)}) '
        f'SELECT {", ".join(select_parts)} '
        f'FROM public."{source}" s {" ".join(join_clauses)} '
        f'WHERE s."{pk}"::text = ANY($1::text[])'
    )
    delete_sql = f'DELETE FROM public."{target}" WHERE "{pk}"::text = ANY($1::text[])'

    upserted = 0
    batches = 0
    for start in range(0, len(pk_vals), batch_size):
        chunk = [str(v) for v in pk_vals[start : start + batch_size]]
        if not chunk:
            continue
        await PostgresDB.execute(delete_sql, chunk)
        tag = await PostgresDB.execute(insert_sql, chunk)
        batches += 1
        if tag and str(tag).startswith("INSERT "):
            try:
                upserted += int(str(tag).split()[-1])
            except (TypeError, ValueError):
                pass

    stale_deleted = 0
    if strat == "FULL":
        stale_tag = await PostgresDB.execute(
            f"""
            DELETE FROM public."{target}" f
            WHERE NOT EXISTS (
              SELECT 1 FROM public."{source}" s WHERE s."{pk}" = f."{pk}"
            )
            """
        )
        if stale_tag and str(stale_tag).startswith("DELETE "):
            try:
                stale_deleted = int(str(stale_tag).split()[-1])
            except (TypeError, ValueError):
                pass

    new_lp = None
    if incremental and pk_vals:
        mx = await PostgresDB.fetch(
            f'SELECT MAX(s."last_updated") AS m FROM public."{source}" s {where}',
            *where_args,
        )
        if mx and mx[0].get("m") is not None:
            new_lp = mx[0]["m"]

    await PostgresDB.execute(
        """
        UPDATE public.flattening_table_policy
        SET last_refreshed = now(),
            last_processed_value = COALESCE($2, last_processed_value),
            last_updated = now()
        WHERE id = $1
        """,
        int(policy_id),
        new_lp,
    )

    logger.info(
        "refresh_flattening_table: policy=%s %s -> %s strategy=%s upserted=%s stale_deleted=%s batches=%s",
        policy_id,
        source,
        target,
        strat,
        upserted,
        stale_deleted,
        batches,
    )
    return {
        "ok": True,
        "policy_id": int(policy_id),
        "table_name": source,
        "target_table": target,
        "refresh_strategy": strat,
        "engine": "postgres_v1",
        "rows_upserted": upserted,
        "stale_deleted": stale_deleted,
        "batches": batches,
        "denorm_relations": len(denorm),
        "json_relations": len(json_specs),
        "model_id": ensure_info.get("model_id"),
        "read_endpoints": read_paths,
    }


register_handler("refresh_flattening_table", refresh_flattening_table)
