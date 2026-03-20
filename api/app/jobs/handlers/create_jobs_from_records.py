"""
Create one job per record from a list. Used by workflows (e.g. process_pending_alarms).

Payload:
- records: list of dicts (e.g. from previous step $alarm_list.body.records)
- job_template_name: str (template name to create jobs for)
- payload_mapping: dict, key = job payload key, value = expression "$record.<field>" (e.g. "$record.alarm_id")
"""
import json
import logging
import uuid
from typing import Any, Dict, List

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.create_jobs_from_records")


def _resolve_record_expr(expr: str, record: Dict[str, Any]) -> Any:
    """Resolve $record.field or $record.field.nested from record."""
    if not isinstance(expr, str) or not expr.strip().startswith("$record."):
        return expr
    path = expr.strip()[8:]  # after "$record."
    if not path:
        return record
    parts = path.split(".")
    obj = record
    for p in parts:
        obj = obj.get(p) if isinstance(obj, dict) else getattr(obj, p, None)
    return obj


async def create_jobs_from_records(payload: Dict[str, Any]) -> Dict[str, Any]:
    records = payload.get("records")
    if not isinstance(records, list):
        if records is not None:
            logger.warning("create_jobs_from_records: payload.records is not a list (got %s), using empty list", type(records).__name__)
        records = []
    logger.info("create_jobs_from_records: received %d records, payload keys: %s", len(records), list(payload.keys()))
    job_template_name = payload.get("job_template_name")
    if not job_template_name:
        raise ValueError("payload.job_template_name is required")
    payload_mapping = payload.get("payload_mapping") or {}
    if not isinstance(payload_mapping, dict):
        payload_mapping = {}

    from classes.postgres_db import PostgresDB
    from jobs.queue_manager import get_queue_manager

    row = await PostgresDB.fetchrow(
        "SELECT id FROM public.job_templates WHERE name = $1 AND COALESCE(is_active, true) = true",
        job_template_name,
    )
    if not row:
        raise ValueError(f"Job template not found: {job_template_name}")
    template_id = row["id"]
    job_ids = []
    qm = get_queue_manager()
    for rec in records:
        if not isinstance(rec, dict):
            continue
        job_payload = {}
        for key, expr in payload_mapping.items():
            val = _resolve_record_expr(expr, rec) if isinstance(expr, str) else expr
            # Default device_id to "all_devices" when alarm_target is null
            if key == "device_id" and (val is None or (isinstance(val, str) and not val.strip())):
                val = "all_devices"
            job_payload[key] = val
        # Skip records where all mapped values are None (invalid/incomplete)
        if all(v is None for v in job_payload.values()):
            continue
        job_id = uuid.uuid4()
        payload_json = json.dumps(job_payload, default=str)
        await PostgresDB.execute(
            """
            INSERT INTO public.jobs (id, template_id, payload, schedule_time, status)
            VALUES ($1, $2, $3::jsonb, NULL, 'queued')
            """,
            job_id,
            template_id,
            payload_json,
        )
        job_ids.append(str(job_id))
        job_row = {
            "id": str(job_id),
            "template_id": str(template_id),
            "payload": job_payload,
            "schedule_time": None,
            "status": "queued",
        }
        await qm.ready_put(job_row, priority=0)
    logger.info("create_jobs_from_records: created %d jobs for template %s", len(job_ids), job_template_name)
    return {"created": len(job_ids), "job_ids": job_ids}


register_handler("create_jobs_from_records", create_jobs_from_records)
