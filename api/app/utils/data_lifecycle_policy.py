"""
Validation helpers for data_lifecycle_policy.
"""
from __future__ import annotations

from typing import Any, Dict


def validate_lifecycle_row(row: Dict[str, Any], partial: bool = False) -> None:
    dest = row.get("destination_type")
    if not partial and not dest:
        raise ValueError("destination_type is required")
    mode = row.get("transfer_mode") or "time_based"
    if mode in ("time_based", "time_and_condition") and not partial:
        if not (row.get("time_column") or "").strip():
            raise ValueError("time_column is required for time_based / time_and_condition")
    if mode in ("condition_based", "time_and_condition") and not partial:
        if not (row.get("filter_condition") or "").strip():
            raise ValueError("filter_condition is required for condition_based / time_and_condition")
    if dest == "postgres_archive" and not partial:
        if not (row.get("destination_table") or "").strip():
            raise ValueError("destination_table is required for postgres_archive")
    if str(dest).rsplit(".", 1)[-1] == "iceberg" and not partial:
        if not (row.get("destination_table") or "").strip():
            raise ValueError("destination_table is required for iceberg (logical table id, e.g. lifecycle.archived_x)")
    if dest == "s3" and row.get("is_public_on_s3") is None and not partial:
        raise ValueError("is_public_on_s3 is required for s3 destination (true=public prefix, false=private)")
    pad = row.get("purge_after_interval_minutes")
    if pad is not None and not partial:
        try:
            if int(pad) < 0:
                raise ValueError()
        except (TypeError, ValueError):
            raise ValueError("purge_after_interval_minutes must be a non-negative integer or null") from None


def sql_due_lifecycle_policies() -> str:
    return """
SELECT id, table_name, pk_column, destination_type::text AS destination_type,
       movement_type::text AS movement_type, sync_strategy::text AS sync_strategy,
       sync_batch_size, time_column, filter_condition, destination_table, is_public_on_s3,
       archive_source_table, purge_enabled, purge_after_interval_minutes,
       last_archive_completed_at, last_purge_completed_at
FROM public.data_lifecycle_policy
WHERE COALESCE(is_active, true) = true
  AND sync_interval_minutes IS NOT NULL
  AND (
    last_synced_at IS NULL
    OR last_synced_at + (sync_interval_minutes || ' minutes')::interval <= now()
)
"""


def sql_due_lifecycle_purge_policies() -> str:
    return """
SELECT id, table_name, pk_column, destination_type::text AS destination_type,
       sync_strategy::text AS sync_strategy, sync_batch_size, time_column, filter_condition,
       destination_table, archive_source_table, purge_after_interval_minutes,
       last_archive_completed_at, last_purge_completed_at, lifecycle_root_table
FROM public.data_lifecycle_policy
WHERE COALESCE(is_active, true) = true
  AND purge_enabled = true
  AND sync_interval_minutes IS NOT NULL
  AND last_archive_completed_at IS NOT NULL
  AND (
    COALESCE(purge_after_interval_minutes, 0) = 0
    OR last_archive_completed_at + (purge_after_interval_minutes || ' minutes')::interval <= now()
  )
  AND (
    last_purge_completed_at IS NULL
    OR last_purge_completed_at + (sync_interval_minutes || ' minutes')::interval <= now()
  )
  AND (
    (
      destination_type = 'postgres_archive'::public.destination_type_enum
      AND lifecycle_root_table IS NOT NULL
    )
    OR (
      destination_type = 'iceberg'::public.destination_type_enum
      AND EXISTS (
        SELECT 1 FROM public.data_lifecycle_batch_ledger bl
        WHERE bl.policy_id = public.data_lifecycle_policy.id
          AND bl.operation = 'iceberg_export'
          AND bl.status = 'completed'
          AND bl.purged_at IS NULL
      )
    )
  )
"""
