"""
Refresh one flattening_table_policy row. Phase 1: touch last_refreshed; real flattening TBD.
"""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.refresh_flattening_table")


async def refresh_flattening_table(payload: Dict[str, Any]) -> Dict[str, Any]:
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")
    from classes.postgres_db import PostgresDB

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, refresh_strategy, is_snapshot
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
    strat = row["refresh_strategy"]
    logger.info(
        "refresh_flattening_table: policy %s table=%s strategy=%s (engine not implemented)",
        policy_id,
        row["table_name"],
        strat,
    )
    await PostgresDB.execute(
        """
        UPDATE public.flattening_table_policy
        SET last_refreshed = now(), last_updated = now()
        WHERE id = $1
        """,
        int(policy_id),
    )
    return {
        "ok": True,
        "policy_id": int(policy_id),
        "table_name": row["table_name"],
        "refresh_strategy": strat,
        "engine": "stub",
    }


register_handler("refresh_flattening_table", refresh_flattening_table)
