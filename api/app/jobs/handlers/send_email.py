"""Send email handler (stub; integrate with CommsService/SES later)."""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers")


async def send_email(payload: Dict[str, Any]) -> Dict[str, Any]:
    to_ = payload.get("to", "")
    subject = payload.get("subject", "")
    body = payload.get("body", "")
    logger.info("send_email: to=%s subject=%s", to_, subject[:50] if subject else "")
    # TODO: wire to CommsService / AWS SES
    return {"ok": True, "message": "Email queued (stub)"}


register_handler("send_email", send_email)
