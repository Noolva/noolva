"""Push notification handler (stub)."""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers")


async def notification_push(payload: Dict[str, Any]) -> Dict[str, Any]:
    user_id = payload.get("user_id")
    message = payload.get("message", "")
    logger.info("notification_push: user_id=%s message=%s", user_id, message[:50] if message else "")
    return {"ok": True, "message": "Push queued (stub)"}


register_handler("notification_push", notification_push)
