"""
Sync one data_lifecycle_policy row:
- postgres_archive: copy eligible rows from flat/source -> archived_* (ensure table, ledger, timestamps).
- iceberg: export eligible archived_* rows to Parquet (+ optional PyIceberg append), ledger with pk_values.
- s3: not implemented in 1.0.6 engine (timestamp + warning only).
Archiving never deletes hot rows; deletion is purge_lifecycle_after_archive (verified against archive).
"""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.sync_lifecycle_table")


async def sync_lifecycle_table(payload: Dict[str, Any]) -> Dict[str, Any]:
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")
    from classes.postgres_db import PostgresDB
    from utils.data_lifecycle_ledger import insert_batch_ledger
    from utils.data_lifecycle_sync import (
        archive_batch_postgres,
        ensure_archive_table_like_source,
        lifecycle_destination_table,
        resolve_archive_physical_table,
        _enum_tail,
    )

    row = await PostgresDB.fetchrow(
        """
        SELECT id, policy_label, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition,
               destination_type::text AS destination_type, destination_table, is_public_on_s3,
               movement_type::text AS movement_type, sync_strategy::text AS sync_strategy,
               sync_batch_size, sync_interval_minutes, last_processed_value,
               archive_source_table, lifecycle_root_table, incremental_lookback_minutes
        FROM public.data_lifecycle_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"data_lifecycle_policy not found: {policy_id}")

    policy: Dict[str, Any] = dict(row)
    dest = _enum_tail(row.get("destination_type"))
    requested_src = (row.get("table_name") or "").strip()
    src_physical = await resolve_archive_physical_table(requested_src, row.get("archive_source_table"))

    logger.info(
        "sync_lifecycle_table: policy %s src=%s dest=%s movement=%s",
        policy_id,
        src_physical,
        dest,
        row.get("movement_type"),
    )

    if dest == "postgres_archive":
        dest_table = (row.get("destination_table") or "").strip() or lifecycle_destination_table(src_physical)
        await ensure_archive_table_like_source(dest_table, src_physical)

        # Catch-up: process up to MAX_BATCHES_PER_RUN batches per job run so a large
        # backlog drains quickly; each batch is bounded by sync_batch_size.
        batch_limit = max(1, int(policy.get("sync_batch_size") or 1000))
        max_batches_per_run = 10
        total = 0
        runs = 0
        last_lp = policy.get("last_processed_value")
        for _ in range(max_batches_per_run):
            policy["last_processed_value"] = last_lp
            inserted, new_lp = await archive_batch_postgres(policy, src_physical, dest_table)
            runs += 1
            total += inserted
            if new_lp is not None:
                last_lp = new_lp
            if inserted < batch_limit:
                break

        await insert_batch_ledger(
            int(policy_id),
            "archive",
            src_physical,
            dest,
            dest_table,
            total,
            status="completed",
            extra={
                "movement_type": _enum_tail(row.get("movement_type")),
                "transfer_mode": _enum_tail(row.get("transfer_mode")),
                "sync_strategy": _enum_tail(row.get("sync_strategy")),
                "batches_this_run": runs,
                "batch_size": batch_limit,
                "incremental_lookback_minutes": policy.get("incremental_lookback_minutes"),
            },
        )
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_synced_at = now(),
                last_processed_value = COALESCE($2, last_processed_value),
                last_archive_completed_at = CASE WHEN $3 > 0 THEN now() ELSE last_archive_completed_at END,
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
            last_lp,
            int(total),
        )
        logger.info(
            "sync_lifecycle_table: policy %s archived %s rows in %s batch(es) %s -> %s",
            policy_id,
            total,
            runs,
            src_physical,
            dest_table,
        )
        return {
            "ok": True,
            "policy_id": int(policy_id),
            "table_name": requested_src,
            "source_table": src_physical,
            "destination_table": dest_table,
            "rows_archived": total,
            "batches_this_run": runs,
            "engine": "postgres_archive_v1",
        }

    if dest == "iceberg":
        from utils.data_lifecycle_iceberg import export_archived_batch_to_parquet

        dest_table = (row.get("destination_table") or "").strip() or f"lifecycle.{src_physical}"
        try:
            count, new_lp, pk_vals, file_path = await export_archived_batch_to_parquet(
                policy, src_physical, dest_table, int(policy_id)
            )
        except RuntimeError as e:
            logger.error("sync_lifecycle_table: iceberg export failed policy=%s: %s", policy_id, e)
            return {"ok": False, "policy_id": int(policy_id), "error": str(e)}
        await insert_batch_ledger(
            int(policy_id),
            "iceberg_export",
            src_physical,
            dest,
            dest_table,
            count,
            status="completed",
            last_processed_snapshot=new_lp,
            extra={"pk_values": [str(v) for v in pk_vals], "file_path": file_path},
        )
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_synced_at = now(),
                last_processed_value = COALESCE($2, last_processed_value),
                last_archive_completed_at = CASE WHEN $3 > 0 THEN now() ELSE last_archive_completed_at END,
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
            new_lp,
            int(count),
        )
        logger.info("sync_lifecycle_table: policy %s exported %s rows to parquet %s", policy_id, count, file_path)
        return {
            "ok": True,
            "policy_id": int(policy_id),
            "table_name": requested_src,
            "source_table": src_physical,
            "rows_exported": count,
            "file_path": file_path,
            "engine": "iceberg_parquet_v1",
        }

    if dest == "s3":
        logger.warning(
            "sync_lifecycle_table: s3 destination not implemented in 1.0.6 engine — stamping last_synced_at only (policy %s)",
            policy_id,
        )
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_synced_at = now(), last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
        )
        return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "s3_not_implemented_in_1_0_6"}

    logger.warning("sync_lifecycle_table: unknown destination_type %r for policy %s", dest, policy_id)
    return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": f"unknown_destination_{dest}"}


register_handler("sync_lifecycle_table", sync_lifecycle_table)
