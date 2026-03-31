"""
Hard-delete rows past soft-delete retention (deleted_at).
"""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.purge_soft_deleted")


def _is_safe_identifier(name: str) -> bool:
    import re

    return bool(name and re.match(r"^[A-Za-z_][A-Za-z0-9_]*$", name))


async def purge_soft_deleted(payload: Dict[str, Any]) -> Dict[str, Any]:
    table_name = (payload.get("table_name") or "").strip()
    if not table_name or not _is_safe_identifier(table_name):
        raise ValueError("payload.table_name must be a safe SQL identifier")
    try:
        retention_days = int(payload.get("retention_days") or 30)
    except (TypeError, ValueError):
        retention_days = 30
    if retention_days < 1:
        retention_days = 1

    from classes.postgres_db import PostgresDB

    row = await PostgresDB.fetchrow(
        """
        SELECT column_name
        FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = $1 AND column_name = 'deleted_at'
        """,
        table_name,
    )
    if not row:
        logger.info("purge_soft_deleted: table %s has no deleted_at column, skipping", table_name)
        return {"ok": True, "skipped": True, "reason": "no_deleted_at_column", "table_name": table_name}

    # Identifier validated; safe to quote
    sql = f"""
        DELETE FROM public.\"{table_name}\"
        WHERE deleted_at IS NOT NULL
          AND deleted_at < now() - ($1::int * interval '1 day')
    """
    result = await PostgresDB.execute(sql, retention_days)
    # asyncpg execute may return status string
    logger.info("purge_soft_deleted: table=%s retention_days=%s status=%s", table_name, retention_days, result)
    return {"ok": True, "table_name": table_name, "retention_days": retention_days, "status": str(result)}


register_handler("purge_soft_deleted", purge_soft_deleted)
