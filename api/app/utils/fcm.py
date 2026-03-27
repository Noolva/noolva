"""
Firebase Cloud Messaging (FCM) — data messages for mobile agents (wake + sync).
Requires firebase-admin and FIREBASE_CREDENTIALS_PATH pointing to a service account JSON.
"""
from __future__ import annotations

import asyncio
import json
import logging
import os
from typing import Any, Dict, List, Optional, Tuple

logger = logging.getLogger("noolva_api.fcm")

_app = None


def _default_credentials_path() -> str:
    base = os.path.dirname(os.path.abspath(__file__))
    return os.path.normpath(
        os.path.join(base, "..", "..", "..", "firebase-info", "noolva-firebase-adminsdk-fbsvc-4ee4f55b6f.json")
    )


def is_fcm_configured() -> bool:
    path = os.getenv("FIREBASE_CREDENTIALS_PATH") or _default_credentials_path()
    return bool(path and os.path.isfile(path))


def _ensure_app():
    global _app
    if _app is not None:
        return _app
    path = os.getenv("FIREBASE_CREDENTIALS_PATH") or _default_credentials_path()
    if not path or not os.path.isfile(path):
        logger.warning("FCM: no credentials file at %s — set FIREBASE_CREDENTIALS_PATH", path)
        return None
    try:
        import firebase_admin
        from firebase_admin import credentials

        cred = credentials.Certificate(path)
        _app = firebase_admin.initialize_app(cred)
        logger.info("FCM: Firebase app initialized (credentials: %s)", path)
        return _app
    except Exception as e:
        logger.exception("FCM: failed to initialize Firebase: %s", e)
        return None


def _send_sync(token: str, data: Dict[str, str]) -> Tuple[bool, Optional[str]]:
    """Blocking send; run via executor. Returns (ok, error_message)."""
    app = _ensure_app()
    if app is None:
        return False, "fcm_not_configured"
    try:
        from firebase_admin import messaging

        msg = messaging.Message(
            token=token,
            data=data,
            android=messaging.AndroidConfig(priority="high"),
        )
        messaging.send(msg, app=app)
        return True, None
    except Exception as e:
        return False, str(e)


async def send_data_message(token: str, data: Dict[str, Any]) -> Tuple[bool, Optional[str]]:
    """Send high-priority data-only message. All values must be JSON-serializable as strings."""
    str_data: Dict[str, str] = {}
    for k, v in data.items():
        if v is None:
            continue
        if isinstance(v, (dict, list)):
            str_data[str(k)] = json.dumps(v, default=str)
        else:
            str_data[str(k)] = str(v)
    loop = asyncio.get_event_loop()

    def _run():
        return _send_sync(token, str_data)

    return await loop.run_in_executor(None, _run)


async def send_to_tokens(tokens: List[str], data: Dict[str, Any]) -> Dict[str, Any]:
    """Send same payload to multiple tokens. Returns counts and sample errors (no full tokens)."""
    sent = 0
    failed = 0
    errors: List[Dict[str, str]] = []
    for token in tokens:
        if not token or not str(token).strip():
            failed += 1
            continue
        ok, err = await send_data_message(str(token).strip(), data)
        if ok:
            sent += 1
        else:
            failed += 1
            if len(errors) < 5:
                prefix = str(token)[:12] + "…" if len(str(token)) > 12 else str(token)
                errors.append({"token_prefix": prefix, "error": err or "unknown"})
    return {"sent": sent, "failed": failed, "errors": errors}
