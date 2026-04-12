"""
Allowed lifecycle policy sources: flattening flat targets, or archived_* physical tables.
"""
from __future__ import annotations

import re
from typing import Any, Dict, List, Optional, Set, Tuple

from classes.postgres_db import PostgresDB

from utils.data_lifecycle_sync import lifecycle_destination_table, validate_sql_identifier

_SAFE = re.compile(r"^[A-Za-z_][A-Za-z0-9_]*$")


async def list_archived_physical_tables() -> List[str]:
    rows = await PostgresDB.fetch(
        """
        SELECT table_name::text AS table_name
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name ~ '^archived_'
        ORDER BY table_name
        """
    )
    return [r["table_name"] for r in rows if r.get("table_name")]


async def list_flattening_flat_targets() -> List[Dict[str, Any]]:
    """Active flattening policies with non-empty target_table_name."""
    return await PostgresDB.fetch(
        """
        SELECT table_name::text AS root_table,
               NULLIF(TRIM(target_table_name::text), '') AS flat_table
        FROM public.flattening_table_policy
        WHERE COALESCE(is_active, TRUE)
          AND NULLIF(TRIM(target_table_name::text), '') IS NOT NULL
        ORDER BY table_name
        """
    )


async def resolve_lifecycle_root_for_source(physical_table: str) -> Optional[str]:
    """Hot root table if physical_table is a flat target; None if archived tier."""
    p = (physical_table or "").strip()
    if not p or p.startswith("archived_"):
        return None
    row = await PostgresDB.fetchrow(
        """
        SELECT table_name::text AS root_table
        FROM public.flattening_table_policy
        WHERE TRIM(target_table_name::text) = $1 AND COALESCE(is_active, TRUE)
        LIMIT 1
        """,
        p,
    )
    return (row["root_table"] if row else None) or None


async def is_allowed_lifecycle_source(physical_table: str, destination_type: str) -> Tuple[bool, str]:
    """destination_type: postgres_archive | s3 | iceberg"""
    p = (physical_table or "").strip()
    if not p or not _SAFE.match(p):
        return False, "Invalid table name"
    dest = (destination_type or "").rsplit(".", 1)[-1]
    if dest in ("postgres_archive", "s3"):
        row = await PostgresDB.fetchrow(
            """
            SELECT 1
            FROM public.flattening_table_policy
            WHERE TRIM(target_table_name::text) = $1 AND COALESCE(is_active, TRUE)
            LIMIT 1
            """,
            p,
        )
        if not row:
            return False, "Source must be an active flattening policy target_table_name (flat table)."
        return True, ""
    if dest == "iceberg":
        if not p.startswith("archived_"):
            return False, "Iceberg tier source must be a physical archived_* Postgres table."
        exists = await PostgresDB.fetchrow(
            """
            SELECT 1 FROM information_schema.tables
            WHERE table_schema = 'public' AND table_name = $1
            """,
            p,
        )
        if not exists:
            return False, f"Table not found in public schema: {p}"
        return True, ""
    return False, "Unknown destination_type"


def default_iceberg_table_identifier(archived_physical: str) -> str:
    """Logical Iceberg identifier (namespace.table) — file layout uses sanitized name."""
    a = validate_sql_identifier((archived_physical or "").strip(), "table_name")
    safe = re.sub(r"[^a-zA-Z0-9_]", "_", a).lower().strip("_")
    return f"lifecycle.{safe}"


def compute_policy_destination_table(table_name: str, destination_type: str, iceberg_override: Optional[str]) -> str:
    """Canonical destination_table string stored on policy."""
    tn = (table_name or "").strip()
    dest = (destination_type or "").rsplit(".", 1)[-1]
    if dest in ("postgres_archive", "s3"):
        return lifecycle_destination_table(tn)
    if dest == "iceberg":
        o = (iceberg_override or "").strip()
        if o:
            return o
        return default_iceberg_table_identifier(tn)
    return ""
