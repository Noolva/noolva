"""
FCM + pending-task queue for process_alarm (mobile agents).
"""
from __future__ import annotations

import json
import logging
from typing import Any, Dict, List, Optional

from classes.postgres_db import PostgresDB
from utils.fcm import is_fcm_configured, send_to_tokens

logger = logging.getLogger("noolva_api.agent_alarm_push")


async def deliver_alarm_mobile(payload: Dict[str, Any], device_id: str, alarm_id: Any) -> Dict[str, Any]:
    """
    After WebSocket push: enqueue pull-model tasks and send FCM data messages.

    - Targeted device_id: all registrations with that device_id (typically one user).
    - Broadcast (all_devices): if payload.company_id is set, registrations for that company only;
      if missing, all rows in agent_device_registrations (OK single-tenant; avoid in multi-tenant).
    """
    out: Dict[str, Any] = {
        "fcm_sent": 0,
        "fcm_failed": 0,
        "fcm_errors": [],
        "pending_enqueued": 0,
        "fcm_skipped": None,
    }
    alarm_str = str(alarm_id)
    payload_for_task = {k: v for k, v in payload.items() if k not in ("device_id", "company_id")}
    message = payload_for_task.get("title") or payload_for_task.get("message") or f"Alarm {alarm_str}"

    try:
        registrations = await _resolve_registrations(device_id, payload)
    except Exception as e:
        logger.warning("agent_alarm_push: could not load registrations: %s", e)
        out["fcm_skipped"] = "registration_query_failed"
        return out

    if not registrations:
        if str(device_id) == "all_devices":
            out["fcm_skipped"] = "no_registrations"
        else:
            out["fcm_skipped"] = "no_fcm_registration_for_device"
        return out

    pending = 0
    for row in registrations:
        try:
            await PostgresDB.execute(
                """
                INSERT INTO public.agent_pending_tasks
                (user_id, company_id, device_id, task_type, task_id, message, payload)
                VALUES ($1, $2, $3, 'alarm', $4, $5, $6::jsonb)
                """,
                row["user_id"],
                row.get("company_id"),
                row["device_id"],
                alarm_str,
                str(message)[:2000] if message is not None else None,
                json.dumps(payload_for_task, default=str),
            )
            pending += 1
        except Exception as e:
            logger.warning("agent_alarm_push: pending task insert failed: %s", e)
    out["pending_enqueued"] = pending

    if not is_fcm_configured():
        out["fcm_skipped"] = "fcm_credentials_missing"
        logger.warning(
            "agent_alarm_push: FCM not sent — no Firebase credentials file (set FIREBASE_CREDENTIALS_PATH or add file at default path). pending_enqueued=%s",
            pending,
        )
        return out

    tokens = [r["fcm_token"] for r in registrations if r.get("fcm_token")]
    if not tokens:
        logger.warning(
            "agent_alarm_push: FCM not sent — registration row(s) have empty fcm_token. pending_enqueued=%s",
            pending,
        )
        return out

    payload_json = json.dumps(payload_for_task, default=str)
    data: Dict[str, Any] = {
        "action": "sync",
        "type": "alarm",
        "alarm_id": alarm_str,
        "payload_json": payload_json,
    }
    result = await send_to_tokens(tokens, data)
    out["fcm_sent"] = result["sent"]
    out["fcm_failed"] = result["failed"]
    out["fcm_errors"] = result["errors"]
    if result["sent"]:
        logger.info(
            "agent_alarm_push: FCM sent OK — sent=%s failed=%s alarm_id=%s",
            result["sent"],
            result["failed"],
            alarm_str,
        )
    if result["failed"]:
        logger.warning(
            "agent_alarm_push: FCM send failed — sent=%s failed=%s errors=%s alarm_id=%s",
            result["sent"],
            result["failed"],
            result["errors"],
            alarm_str,
        )
    return out


async def _resolve_registrations(device_id: str, payload: Dict[str, Any]) -> List[Dict[str, Any]]:
    if str(device_id) == "all_devices":
        cid = payload.get("company_id")
        if cid is not None:
            try:
                cid_int = int(cid)
            except (TypeError, ValueError):
                cid_int = None
            if cid_int is not None:
                return await PostgresDB.fetch(
                    """
                    SELECT user_id, company_id, device_id, fcm_token
                    FROM public.agent_device_registrations
                    WHERE company_id = $1
                    """,
                    cid_int,
                )
        rows = await PostgresDB.fetch(
            """
            SELECT user_id, company_id, device_id, fcm_token
            FROM public.agent_device_registrations
            """
        )
        logger.info(
            "agent_alarm_push: broadcast without company_id — matched %d registration row(s) (pending + FCM happen next; see following log lines)",
            len(rows),
        )
        return rows

    rows = await PostgresDB.fetch(
        """
        SELECT user_id, company_id, device_id, fcm_token
        FROM public.agent_device_registrations
        WHERE device_id = $1
        """,
        str(device_id).strip(),
    )
    return rows
