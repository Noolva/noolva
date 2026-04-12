"""
Sync one data_lifecycle_policy row. Phase 1: update last_synced_at; S3/archive/iceberg movement TBD.
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

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, destination_type::text AS destination_type,
               movement_type::text AS movement_type, sync_strategy::text AS sync_strategy
        FROM public.data_lifecycle_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"data_lifecycle_policy not found: {policy_id}")
    dest = row["destination_type"]
    logger.info(
        "sync_lifecycle_table: policy %s table=%s dest=%s movement=%s (minimal implementation)",
        policy_id,
        row["table_name"],
        dest,
        row["movement_type"],
    )
    if dest == "iceberg":
        logger.warning("sync_lifecycle_table: iceberg not implemented for policy %s", policy_id)
    await PostgresDB.execute(
        """
        UPDATE public.data_lifecycle_policy
        SET last_synced_at = now(), last_updated = now()
        WHERE id = $1
        """,
        int(policy_id),
    )
    return {
        "ok": True,
        "policy_id": int(policy_id),
        "table_name": row["table_name"],
        "destination_type": dest,
        "engine": "stub",
    }


register_handler("sync_lifecycle_table", sync_lifecycle_table)
