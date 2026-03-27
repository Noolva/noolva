"""
Mobile agent: FCM registration and pending-task pull (Bearer JWT or PAT).
"""
import json
import logging
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, Body, Depends, Header, HTTPException
from pydantic import BaseModel, Field

from classes.postgres_db import PostgresDB
from middlewares.auth import resolve_bearer_to_user

router = APIRouter()
logger = logging.getLogger("noolva_api.mobile_agent")


async def _require_user_dep(authorization: Optional[str] = Header(None)) -> Dict[str, Any]:
    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required (Bearer JWT or PAT)")
    return user


class RegisterDeviceBody(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=512)
    fcm_token: str = Field(..., min_length=1)


class UnregisterDeviceBody(BaseModel):
    device_id: str = Field(..., min_length=1, max_length=512)


@router.post("/register-device")
async def register_device(
    body: RegisterDeviceBody,
    user: Dict[str, Any] = Depends(_require_user_dep),
):
    """Upsert FCM token for this user + device_id (same id as WebSocket path). Replaces previous token."""
    uid = user["user_id"]
    cid = user.get("company_id")
    if isinstance(cid, str) and cid.isdigit():
        cid = int(cid)
    elif cid is not None and not isinstance(cid, int):
        try:
            cid = int(cid)
        except (TypeError, ValueError):
            cid = None

    await PostgresDB.execute(
        """
        INSERT INTO public.agent_device_registrations
        (user_id, company_id, device_id, fcm_token, updated_at)
        VALUES ($1, $2, $3, $4, CURRENT_TIMESTAMP)
        ON CONFLICT (user_id, device_id) DO UPDATE SET
            fcm_token = EXCLUDED.fcm_token,
            company_id = EXCLUDED.company_id,
            updated_at = CURRENT_TIMESTAMP
        """,
        uid,
        cid,
        body.device_id.strip(),
        body.fcm_token.strip(),
    )
    return {"success": True, "device_id": body.device_id.strip()}


@router.delete("/register-device")
async def unregister_device(
    body: UnregisterDeviceBody = Body(...),
    user: Dict[str, Any] = Depends(_require_user_dep),
):
    """Remove FCM registration for this device (call on logout if desired)."""
    uid = user["user_id"]
    await PostgresDB.execute(
        """
        DELETE FROM public.agent_device_registrations
        WHERE user_id = $1 AND device_id = $2
        """,
        uid,
        body.device_id.strip(),
    )
    return {"success": True, "device_id": body.device_id.strip()}


@router.get("/pending-tasks/{device_id}")
async def get_pending_tasks(
    device_id: str,
    user: Dict[str, Any] = Depends(_require_user_dep),
):
    """
    Atomically fetch and remove pending tasks for this user + device (pull after FCM sync).
    """
    uid = user["user_id"]
    dev = device_id.strip()
    if not dev:
        raise HTTPException(status_code=400, detail="device_id required")

    own = await PostgresDB.fetchrow(
        """
        SELECT 1 FROM public.agent_device_registrations
        WHERE user_id = $1 AND device_id = $2
        LIMIT 1
        """,
        uid,
        dev,
    )
    if not own:
        raise HTTPException(status_code=403, detail="Device not registered for this user")

    rows = await PostgresDB.fetch(
        """
        WITH t AS (
            SELECT pending_task_id
            FROM public.agent_pending_tasks
            WHERE user_id = $1 AND device_id = $2
            ORDER BY created_at ASC
            LIMIT 200
        )
        DELETE FROM public.agent_pending_tasks p
        USING t
        WHERE p.pending_task_id = t.pending_task_id
        RETURNING p.task_type, p.task_id, p.message, p.payload
        """,
        uid,
        dev,
    )

    out: List[Dict[str, Any]] = []
    for r in rows:
        tid = r.get("task_id") or ""
        msg = r.get("message") or ""
        item: Dict[str, Any] = {
            "type": r.get("task_type") or "alarm",
            "task_id": tid,
            "id": tid,
            "message": msg,
            "text": msg,
        }
        pl = r.get("payload")
        if isinstance(pl, str):
            try:
                pl = json.loads(pl)
            except Exception:
                pl = {}
        elif pl is not None and not isinstance(pl, dict):
            pl = {}
        if pl:
            item["payload"] = pl
        out.append(item)

    return out
