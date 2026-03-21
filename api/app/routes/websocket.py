"""
WebSocket endpoint for worker and real-time connections.
Connect with auth (token in query or first message) to register as a websocket client.
Connections to /ws/{device_id} are registered in public.workers so they appear on Scheduler Workers.
Supports pushing messages (e.g. alarm) to a device via ws_connections.push_to_device.
"""
import json
import logging
from typing import Optional

from fastapi import APIRouter, Query, WebSocket, WebSocketDisconnect

from middlewares.auth import resolve_bearer_to_user
from ws_connections import register_device_connection, unregister_device_connection

router = APIRouter()
logger = logging.getLogger("noolva_api.websocket")


async def _register_worker(worker_id: str, worker_type: str = "websocket", hostname: Optional[str] = None):
    """Upsert worker into public.workers so it appears on Scheduler Workers page."""
    try:
        from classes.postgres_db import PostgresDB
        await PostgresDB.execute(
            """
            INSERT INTO public.workers (worker_id, worker_type, hostname, status, max_concurrency, last_heartbeat)
            VALUES ($1, $2, $3, 'idle', 1, now())
            ON CONFLICT (worker_id) DO UPDATE SET
                worker_type = EXCLUDED.worker_type,
                hostname = EXCLUDED.hostname,
                status = 'idle',
                last_heartbeat = now()
            """,
            worker_id,
            worker_type,
            hostname,
        )
    except Exception as e:
        logger.warning("Failed to register worker %s: %s", worker_id, e)


async def _update_worker_heartbeat(worker_id: str):
    """Update last_heartbeat for a registered worker."""
    try:
        from classes.postgres_db import PostgresDB
        await PostgresDB.execute(
            "UPDATE public.workers SET last_heartbeat = now() WHERE worker_id = $1",
            worker_id,
        )
    except Exception as e:
        logger.debug("Failed to update worker heartbeat %s: %s", worker_id, e)


async def _set_worker_offline(worker_id: str):
    """Mark worker as offline on disconnect."""
    try:
        from classes.postgres_db import PostgresDB
        await PostgresDB.execute(
            "UPDATE public.workers SET status = 'offline' WHERE worker_id = $1",
            worker_id,
        )
    except Exception as e:
        logger.debug("Failed to set worker offline %s: %s", worker_id, e)


async def _handle_websocket(
    websocket: WebSocket,
    token: Optional[str] = None,
    device_id: Optional[str] = None,
):
    """
    Shared WebSocket handler.
    Auth (same as HTTP API):
    - Query: ?token=... or ?access_token=... (JWT session or PAT nvpat_...)
    - Header: Authorization: Bearer ...
    - Or after accept, first text frame: {"type":"auth","token":"..."}

    If device_id is set (e.g. /ws/device123), the client is registered in public.workers and shown on Scheduler Workers.
    Server sends: {"type":"connected"} then keeps connection open. Send {"type":"ping"} for {"type":"pong"}.
    """
    q = websocket.query_params
    qp_token = (token or q.get("token") or q.get("access_token") or "").strip() or None
    auth_header: Optional[str] = None
    if qp_token:
        auth_header = f"Bearer {qp_token}"
    else:
        h = websocket.headers.get("authorization") or websocket.headers.get("Authorization")
        if h and not str(h).strip().lower().startswith("Bearer "):
            auth_header = f"Bearer {str(h).strip()}"
        else:
            auth_header = h

    user = await resolve_bearer_to_user(auth_header) if auth_header else None

    if auth_header and not user:
        try:
            await websocket.close(code=1008)
        except Exception:
            pass
        return

    if user:
        await websocket.accept()
    else:
        await websocket.accept()
        try:
            first = await websocket.receive_text()
            data = json.loads(first) if first else {}
            if data.get("type") == "auth" and data.get("token"):
                user = await resolve_bearer_to_user(f"Bearer {data['token']}")
        except (json.JSONDecodeError, WebSocketDisconnect):
            pass
        if not user:
            try:
                await websocket.close(code=4001)
            except Exception:
                pass
            return

    # Register this connection as a worker so it appears on Scheduler Workers page
    if device_id:
        await _register_worker(device_id, worker_type="websocket", hostname=None)
        register_device_connection(device_id, websocket)

    try:
        await websocket.send_json({"type": "connected", "message": "WebSocket connected"})
    except Exception:
        await websocket.close()
        if device_id:
            await _set_worker_offline(device_id)
        return

    try:
        while True:
            try:
                text = await websocket.receive_text()
                data = json.loads(text) if text else {}
                if data.get("type") == "ping":
                    if device_id:
                        await _update_worker_heartbeat(device_id)
                    await websocket.send_json({"type": "pong"})
                # Future: handle job result, etc.
            except WebSocketDisconnect:
                break
            except json.JSONDecodeError:
                await websocket.send_json({"type": "error", "message": "Invalid JSON"})
            except Exception as e:
                logger.exception("WebSocket error: %s", e)
                break
    finally:
        if device_id:
            unregister_device_connection(device_id)
            await _set_worker_offline(device_id)
    logger.info("WebSocket closed")


@router.websocket("/ws")
async def websocket_endpoint(
    websocket: WebSocket,
    token: Optional[str] = Query(None, description="Bearer token (PAT or JWT) for auth"),
):
    """WebSocket at /ws."""
    await _handle_websocket(websocket, token=token)


@router.websocket("/ws/{device_id}")
async def websocket_endpoint_with_device(
    websocket: WebSocket,
    device_id: str,
    token: Optional[str] = Query(None, description="Bearer token (PAT or JWT) for auth"),
):
    """WebSocket at /ws/{device_id} (e.g. /ws/device123). Registers as a worker so it appears on Scheduler Workers."""
    await _handle_websocket(websocket, token=token, device_id=device_id)
