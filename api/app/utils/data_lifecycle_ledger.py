"""
Insert / query data_lifecycle_batch_ledger rows.
"""
from __future__ import annotations

from typing import Any, Dict, List, Optional

from classes.postgres_db import PostgresDB


async def insert_batch_ledger(
    policy_id: int,
    operation: str,
    source_table: str,
    destination_type: str,
    destination_detail: Optional[str],
    rows_affected: int,
    status: str = "completed",
    error_message: Optional[str] = None,
    last_processed_snapshot: Any = None,
    extra: Optional[Dict[str, Any]] = None,
) -> int:
    ex = extra if extra is not None else {}
    row = await PostgresDB.fetchrow(
        """
        INSERT INTO public.data_lifecycle_batch_ledger (
            policy_id, operation, source_table, destination_type,
            destination_detail, rows_affected, status, error_message,
            completed_at, last_processed_snapshot, extra
        ) VALUES (
            $1, $2, $3, $4, $5, $6, $7, $8,
            CURRENT_TIMESTAMP,
            $9, COALESCE($10::jsonb, '{}'::jsonb)
        )
        RETURNING id
        """,
        int(policy_id),
        operation,
        source_table,
        destination_type,
        destination_detail,
        int(rows_affected or 0),
        status,
        error_message,
        last_processed_snapshot,
        ex,
    )
    return int(row["id"]) if row else 0


async def mark_ledger_purged(ledger_id: int) -> None:
    await PostgresDB.execute(
        """
        UPDATE public.data_lifecycle_batch_ledger
        SET purged_at = CURRENT_TIMESTAMP
        WHERE id = $1
        """,
        int(ledger_id),
    )


async def fetch_pending_iceberg_purge_row(policy_id: int) -> Optional[Dict[str, Any]]:
    return await PostgresDB.fetchrow(
        """
        SELECT id, extra, source_table
        FROM public.data_lifecycle_batch_ledger
        WHERE policy_id = $1
          AND operation = 'iceberg_export'
          AND status = 'completed'
          AND purged_at IS NULL
        ORDER BY id ASC
        LIMIT 1
        """,
        int(policy_id),
    )


async def count_batch_ledger_rows(policy_id: Optional[int]) -> int:
    if policy_id is not None:
        row = await PostgresDB.fetchrow(
            """
            SELECT COUNT(*)::int AS c
            FROM public.data_lifecycle_batch_ledger
            WHERE policy_id = $1
            """,
            int(policy_id),
        )
    else:
        row = await PostgresDB.fetchrow(
            "SELECT COUNT(*)::int AS c FROM public.data_lifecycle_batch_ledger",
        )
    return int(row["c"] or 0) if row else 0


async def list_batch_ledger_rows(
    policy_id: Optional[int],
    limit: int = 100,
    offset: int = 0,
) -> List[Dict[str, Any]]:
    lim = max(1, min(int(limit or 100), 500))
    off = max(0, int(offset or 0))
    if policy_id is not None:
        return await PostgresDB.fetch(
            """
            SELECT id, policy_id, operation, source_table, destination_type,
                   destination_detail, rows_affected, status, error_message,
                   started_at, completed_at, last_processed_snapshot, purged_at, extra
            FROM public.data_lifecycle_batch_ledger
            WHERE policy_id = $1
            ORDER BY started_at DESC, id DESC
            LIMIT $2 OFFSET $3
            """,
            int(policy_id),
            lim,
            off,
        )
    return await PostgresDB.fetch(
        """
        SELECT id, policy_id, operation, source_table, destination_type,
               destination_detail, rows_affected, status, error_message,
               started_at, completed_at, last_processed_snapshot, purged_at, extra
        FROM public.data_lifecycle_batch_ledger
        ORDER BY started_at DESC, id DESC
        LIMIT $1 OFFSET $2
        """,
        lim,
        off,
    )
