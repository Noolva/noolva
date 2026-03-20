"""Generate report handler (stub)."""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers")


async def generate_report(payload: Dict[str, Any]) -> Dict[str, Any]:
    logger.info("generate_report: payload=%s", list(payload.keys()))
    return {"ok": True, "report_id": "stub-report"}


register_handler("generate_report", generate_report)
