"""
Purge after archive/export:
- postgres_archive + lifecycle_root: delete flattening separate children, flat, root (PKs in flat ∩ archive).
- iceberg: delete PKs from archived_* for completed iceberg_export ledger rows not yet purged.
"""
import json
import logging
from typing import Any, Dict

from classes.postgres_db import PostgresDB
from utils.data_lifecycle_ledger import fetch_pending_iceberg_purge_row, insert_batch_ledger, mark_ledger_purged
from utils.data_lifecycle_sync import (
    delete_archived_rows_by_pk,
    lifecycle_destination_table,
    purge_tier1_flat_and_root,
    table_exists,
)
from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.purge_lifecycle_after_archive")


async def purge_lifecycle_after_archive(payload: Dict[str, Any]) -> Dict[str, Any]:
    policy_id = payload.get("policy_id")
    if policy_id is None:
        raise ValueError("payload.policy_id is required")

    row = await PostgresDB.fetchrow(
        """
        SELECT id, table_name, pk_column, transfer_mode::text AS transfer_mode,
               time_column, filter_condition,
               destination_type::text AS destination_type,
               sync_strategy::text AS sync_strategy,
               sync_batch_size, destination_table, is_public_on_s3,
               purge_enabled, purge_after_interval_minutes,
               last_archive_completed_at, lifecycle_root_table
        FROM public.data_lifecycle_policy
        WHERE id = $1
        """,
        int(policy_id),
    )
    if not row:
        raise ValueError(f"data_lifecycle_policy not found: {policy_id}")

    policy = dict(row)
    dest = row["destination_type"].rsplit(".", 1)[-1]

    if not policy.get("purge_enabled"):
        return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "purge_disabled"}

    if not policy.get("last_archive_completed_at"):
        return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "no_archive_yet"}

    delay = policy.get("purge_after_interval_minutes")
    if delay is not None and int(delay) > 0:
        ok = await PostgresDB.fetchrow(
            """
            SELECT (last_archive_completed_at + ($2 || ' minutes')::interval <= now()) AS due
            FROM public.data_lifecycle_policy
            WHERE id = $1
            """,
            int(policy_id),
            str(int(delay)),
        )
        if not ok or not ok.get("due"):
            return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "purge_after_delay"}

    if dest == "postgres_archive":
        root = policy.get("lifecycle_root_table")
        if not root:
            return {
                "ok": True,
                "policy_id": int(policy_id),
                "skipped": True,
                "reason": "no_lifecycle_root_for_tier1_purge",
            }
        flat = (policy["table_name"] or "").strip()
        archived_table = (policy.get("destination_table") or "").strip() or lifecycle_destination_table(flat)
        if not await table_exists("public", flat) or not await table_exists("public", archived_table):
            logger.warning(
                "purge_lifecycle_after_archive: missing table flat=%s arch=%s policy=%s",
                flat,
                archived_table,
                policy_id,
            )
            return {"ok": False, "policy_id": int(policy_id), "error": "missing_source_or_archive_table"}

        n_flat, n_root, n_child, pks = await purge_tier1_flat_and_root(policy, flat, archived_table, root, None)
        logger.info(
            "purge_tier1 policy=%s flat=%s root=%s children_rows=%s flat_del=%s root_del=%s",
            policy_id,
            flat,
            root,
            n_child,
            n_flat,
            n_root,
        )
        await insert_batch_ledger(
            int(policy_id),
            "purge_hot",
            flat,
            dest,
            archived_table,
            n_flat + n_root,
            status="completed",
            extra={
                "flat_deleted": n_flat,
                "root_deleted": n_root,
                "child_deleted_est": n_child,
                "picked_count": len(pks),
            },
        )
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_purge_completed_at = now(), last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
        )
        return {
            "ok": True,
            "policy_id": int(policy_id),
            "flat_deleted": n_flat,
            "root_deleted": n_root,
            "children_deleted_est": n_child,
        }

    if dest == "iceberg":
        pend = await fetch_pending_iceberg_purge_row(int(policy_id))
        if not pend:
            return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "no_pending_ledger_export"}
        extra = pend.get("extra")
        if isinstance(extra, str):
            try:
                extra = json.loads(extra)
            except json.JSONDecodeError:
                extra = {}
        if not isinstance(extra, dict):
            extra = {}
        pks_raw = extra.get("pk_values") or []
        archived_src = (policy["table_name"] or "").strip() or (pend.get("source_table") or "")
        if not pks_raw or not archived_src:
            mark_ledger_purged(int(pend["id"]))
            return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "ledger_empty_pks"}
        # Normalize pk to native types where int
        pks: list = []
        for p in pks_raw:
            try:
                pks.append(int(str(p)))
            except ValueError:
                pks.append(str(p))
        n = await delete_archived_rows_by_pk(archived_src, policy.get("pk_column") or "id", pks)
        mark_ledger_purged(int(pend["id"]))
        await insert_batch_ledger(
            int(policy_id),
            "purge_archived",
            archived_src,
            dest,
            policy.get("destination_table"),
            n,
            status="completed",
            extra={"ledger_id": int(pend["id"]), "deleted": n},
        )
        await PostgresDB.execute(
            """
            UPDATE public.data_lifecycle_policy
            SET last_purge_completed_at = now(), last_updated = now()
            WHERE id = $1
            """,
            int(policy_id),
        )
        return {"ok": True, "policy_id": int(policy_id), "archived_deleted": n, "ledger_id": int(pend["id"])}

    logger.info("purge_lifecycle_after_archive: skip dest=%s policy=%s", dest, policy_id)
    return {"ok": True, "policy_id": int(policy_id), "skipped": True, "reason": "destination_not_purged_here"}
