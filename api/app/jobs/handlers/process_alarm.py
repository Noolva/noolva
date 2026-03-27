"""
Process one alarm: optionally update alarm state and push the alarm to the device over WebSocket.

Payload:
- alarm_id: id of the alarm record (required)
- device_id: optional; if present and the device is connected via WebSocket, push alarm to it
- Optional: other fields for updating the alarm (e.g. status) via auto_crud in future
"""
import logging
from typing import Any, Dict

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.process_alarm")


async def process_alarm(payload: Dict[str, Any]) -> Dict[str, Any]:
    alarm_id = payload.get("alarm_id")
    if not alarm_id:
        raise ValueError("payload.alarm_id is required")
    device_id = payload.get("device_id")
    if device_id is None or (isinstance(device_id, str) and not device_id.strip()):
        device_id = "all_devices"
    pushed = False
    pushed_count = 0
    if device_id:
        try:
            from ws_connections import push_to_device, push_to_all_devices
            msg = {
                "type": "alarm",
                "alarm_id": alarm_id,
                "payload": {k: v for k, v in payload.items() if k not in ("device_id",)}
            }
            if str(device_id) == "all_devices":
                pushed_count = await push_to_all_devices(msg)
                pushed = pushed_count > 0
            else:
                pushed = await push_to_device(str(device_id), msg)
                pushed_count = 1 if pushed else 0
        except Exception as e:
            logger.warning("process_alarm: push failed for device_id=%s: %s", device_id, e)

    mobile_result: Dict[str, Any] = {}
    try:
        from utils.agent_alarm_push import deliver_alarm_mobile

        mobile_result = await deliver_alarm_mobile(payload, str(device_id), alarm_id)
    except Exception as e:
        logger.warning("process_alarm: mobile FCM/pending queue failed: %s", e)
        mobile_result = {"fcm_skipped": "exception", "fcm_error": str(e)}

    # Future: update alarm status in DB (e.g. mark as notified) via auto_crud or direct update
    return {
        "ok": True,
        "alarm_id": alarm_id,
        "pushed_to_device": pushed,
        "pushed_count": pushed_count,
        "device_id": device_id,
        **mobile_result,
    }


register_handler("process_alarm", process_alarm)
