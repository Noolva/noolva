"""
Archive / export for data_lifecycle_policy.
- postgres_archive / s3: read from physical source table (flat); archive to archived_<source>.
- iceberg: read from archived_* physical table; write Parquet (optional PyIceberg append).

Never deletes hot/archived rows here — use purge_lifecycle_after_archive.
"""
import logging
from typing import Any, Dict

from classes.postgres_db import PostgresDB
from utils.data_lifecycle_iceberg import export_archived_batch_to_parquet
from utils.data_lifecycle_ledger import insert_batch_ledger
from utils.data_lifecycle_sync import (
    archive_batch_postgres,
    ensure_archive_table_like_source,
    lifecycle_destination_table,
    table_exists,
)
from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.sync_lifecycle_table")


async def sync_lifecycle_table(payload: Dict[str, Any]) -> Dict[str, Any]:
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition,
               destination_type::text AS destination_type,
               movement_type::text AS movement_type, sync_strategy::text AS sync_strategy,
               sync_batch_size, destination_table, is_public_on_s3,
               last_processed_value, lifecycle_root_table
        FROM public.data_lifecycle_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"data_lifecycle_policy not found: {policy_id}")

    policy = dict(row)
    dest = row["destination_type"].rsplit(".", 1)[-1]
    src_physical = (policy["table_name"] or "").strip()
    archived_table = (policy.get("destination_table") or "").strip()
    inserted = 0
    new_lp = None
    parquet_path = ""
    pk_exported: list = []

    try:
        if dest == "postgres_archive":
            if not archived_table:
                archived_table = lifecycle_destination_table(src_physical)
            if not await table_exists("public", src_physical):
                raise ValueError(f"Source table does not exist: public.{src_physical}")
            await ensure_archive_table_like_source(archived_table, src_physical)
            inserted, new_lp = await archive_batch_postgres(policy, src_physical, archived_table)
            if inserted > 0:
                await insert_batch_ledger(
                    int(policy_id),
                    "archive_postgres",
                    src_physical,
                    dest,
                    archived_table,
                    inserted,
                    status="completed",
                    last_processed_snapshot=new_lp,
                    extra={"pk_batch_count": inserted},
                )
            logger.info(
                "sync_lifecycle_table: archived %s rows policy=%s src=%s dest=%s",
                inserted,
                policy_id,
                src_physical,
                archived_table,
            )
        elif dest == "s3":
            logger.info(
                "sync_lifecycle_table: S3 row export not implemented policy=%s src=%s",
                policy_id,
                src_physical,
            )
            await insert_batch_ledger(
                int(policy_id),
                "archive_postgres",
                src_physical,
                dest,
                archived_table or "",
                0,
                status="completed",
                extra={"note": "s3_stub"},
            )
        elif dest == "iceberg":
            iceberg_ident = archived_table
            if not iceberg_ident:
                raise ValueError("destination_table (Iceberg logical id) is missing on policy")
            if not await table_exists("public", src_physical):
                raise ValueError(f"Iceberg source archived table missing: public.{src_physical}")
            inserted, new_lp, pk_exported, parquet_path = await export_archived_batch_to_parquet(
                policy, src_physical, iceberg_ident, int(policy_id)
            )
            if inserted > 0:
                await insert_batch_ledger(
                    int(policy_id),
                    "iceberg_export",
                    src_physical,
                    dest,
                    iceberg_ident,
                    inserted,
                    status="completed",
                    last_processed_snapshot=new_lp,
                    extra={
                        "parquet_path": parquet_path,
                        "pk_values": [str(x) for x in pk_exported],
                    },
                )
            logger.info(
                "sync_lifecycle_table: iceberg parquet policy=%s rows=%s path=%s",
                policy_id,
                inserted,
                parquet_path,
            )
        else:
            logger.warning("sync_lifecycle_table: unknown destination_type %s", dest)
    except Exception as e:
        logger.exception("sync_lifecycle_table failed policy=%s", policy_id)
        op = "iceberg_export" if dest == "iceberg" else "archive_postgres"
        await insert_batch_ledger(
            int(policy_id),
            op,
            src_physical,
            dest,
            archived_table or "",
            0,
            status="failed",
            error_message=str(e)[:4000],
        )
        raise

    upd_lp = policy.get("last_processed_value")
    if new_lp is not None:
        upd_lp = new_lp

    if inserted > 0:
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_synced_at = now(),
                last_archive_completed_at = now(),
                last_processed_value = $2,
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
            upd_lp,
        )
    else:
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_synced_at = now(),
                last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
        )

    return {
        "ok": True,
        "policy_id": int(policy_id),
        "table_name": src_physical,
        "destination_table": archived_table,
        "destination_type": dest,
        "rows_affected": inserted,
        "parquet_path": parquet_path or None,
    }


register_handler("sync_lifecycle_table", sync_lifecycle_table)
