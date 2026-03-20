"""
WebSocket connection registry by device_id. Used by the WebSocket route to register
connections and by job handlers (e.g. process_alarm) to push messages to a device.
"""
import asyncio
import logging
from typing import Any, Dict

logger = logging.getLogger("noolva_api.ws_connections")

# device_id -> WebSocket (single connection per device; last wins)
_connections: Dict[str, Any] = {}
_connections_lock = asyncio.Lock()


def register_device_connection(device_id: str, websocket: Any) -> None:
    """Register a WebSocket for device_id (called when connection opens)."""
    _connections[device_id] = websocket


def unregister_device_connection(device_id: str) -> None:
    """Remove device_id from registry (called on disconnect)."""
    _connections.pop(device_id, None)


async def push_to_device(device_id: str, message: Dict[str, Any]) -> bool:
    """
    Send a JSON message to the WebSocket connection for the given device_id.
    Used by process_alarm to deliver alarms to connected devices.
    Returns True if sent, False if no connection for device_id.
    """
    async with _connections_lock:
        ws = _connections.get(device_id)
    if not ws:
        logger.debug("push_to_device: no connection for device_id=%s", device_id)
        return False
    try:
        await ws.send_json(message)
        return True
    except Exception as e:
        logger.warning("push_to_device failed for device_id=%s: %s", device_id, e)
        unregister_device_connection(device_id)
        return False


async def push_to_all_devices(message: Dict[str, Any]) -> int:
    """
    Send a JSON message to all registered WebSocket connections.
    Used by process_alarm when device_id is "all_devices".
    Returns the number of devices the message was sent to.
    """
    async with _connections_lock:
        device_ids = list(_connections.keys())
    sent = 0
    for did in device_ids:
        if await push_to_device(did, message):
            sent += 1
    return sent
