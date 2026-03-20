"""
Auto-CRUD handlers for jobs:
- run_auto_crud_internal: call this API's auto CRUD endpoints using a PAT
- run_auto_crud_remote: call a remote Noolva API using PAT / integration-like payload

Expected payload (both handlers):
- model_name: string (data model name used in /data-models/auto/{model_name}/records)
- operation: 'create' | 'update' | 'delete'
- data: dict (for create/update)
- record_id: optional id (for update/delete)
- pat: optional PAT token; if absent, AUTO_CRUD_INTERNAL_PAT / AUTO_CRUD_REMOTE_PAT env is used
- base_url / remote_base_url: optional; for internal we fall back to APPLICATION_PORT on localhost
"""
import logging
import os
from typing import Any, Dict, Optional

import httpx

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.auto_crud")


def _resolve_base_url(payload: Dict[str, Any], internal: bool) -> str:
    if internal:
        url = (
            payload.get("base_url")
            or os.getenv("AUTO_CRUD_INTERNAL_BASE_URL")
            or os.getenv("API_BASE_URL")
        )
        if not url:
            port = os.getenv("APPLICATION_PORT", "9001")
            url = f"http://localhost:{port}"
    else:
        url = payload.get("remote_base_url") or payload.get("base_url") or os.getenv("AUTO_CRUD_REMOTE_BASE_URL") or ""
    return url.rstrip("/")


def _resolve_pat(payload: Dict[str, Any], internal: bool) -> Optional[str]:
    if "pat" in payload:
        return payload.get("pat")
    if internal:
        return os.getenv("AUTO_CRUD_INTERNAL_PAT")
    return payload.get("remote_pat") or os.getenv("AUTO_CRUD_REMOTE_PAT")


def _build_auto_crud_request(
    base_url: str, payload: Dict[str, Any]
) -> Dict[str, Any]:
    model_name = payload.get("model_name") or payload.get("model_code") or payload.get("model")
    operation = (payload.get("operation") or "").lower()
    if not model_name or operation not in {"create", "update", "delete"}:
        raise ValueError("model_name and operation (create|update|delete) are required")

    base_path = f"/data-models/auto/{model_name}/records"
    record_id = payload.get("record_id")
    data = payload.get("data") or {}

    if operation == "create":
        method = "POST"
        url = f"{base_url}{base_path}"
    elif operation == "update":
        if not record_id:
            raise ValueError("record_id is required for update operation")
        method = "PUT"
        url = f"{base_url}{base_path}/{record_id}"
    else:  # delete
        if not record_id:
            raise ValueError("record_id is required for delete operation")
        method = "DELETE"
        url = f"{base_url}{base_path}/{record_id}"

    return {"method": method, "url": url, "json": data}


async def _execute_http_request(
    method: str, url: str, pat: Optional[str], json: Optional[Dict[str, Any]]
) -> Dict[str, Any]:
    headers = {}
    if pat:
        headers["Authorization"] = f"Bearer {pat}"

    timeout = float(os.getenv("AUTO_CRUD_HTTP_TIMEOUT", "30"))

    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.request(method, url, json=json, headers=headers)
        try:
            body = resp.json()
        except Exception:
            body = resp.text
        if resp.status_code >= 400:
            logger.warning("auto_crud HTTP %s %s -> %s", method, url, resp.status_code)
        return {
            "status_code": resp.status_code,
            "body": body,
            "ok": 200 <= resp.status_code < 300,
        }


async def run_auto_crud_internal(payload: Dict[str, Any]) -> Dict[str, Any]:
    base_url = _resolve_base_url(payload, internal=True)
    if not base_url:
        raise ValueError("Unable to resolve base_url for internal auto-CRUD")
    pat = _resolve_pat(payload, internal=True)
    if not pat:
        raise ValueError("PAT (payload.pat or AUTO_CRUD_INTERNAL_PAT) required for internal auto-CRUD")
    req = _build_auto_crud_request(base_url, payload)
    logger.info(
        "run_auto_crud_internal: %s %s model=%s operation=%s",
        req["method"],
        req["url"],
        payload.get("model_name") or payload.get("model_code"),
        payload.get("operation"),
    )
    return await _execute_http_request(req["method"], req["url"], pat, req["json"])


async def run_auto_crud_remote(payload: Dict[str, Any]) -> Dict[str, Any]:
    base_url = _resolve_base_url(payload, internal=False)
    if not base_url:
        raise ValueError("remote_base_url or AUTO_CRUD_REMOTE_BASE_URL required for remote auto-CRUD")
    pat = _resolve_pat(payload, internal=False)
    if not pat:
        raise ValueError("remote_pat (payload.remote_pat) or AUTO_CRUD_REMOTE_PAT required for remote auto-CRUD")
    req = _build_auto_crud_request(base_url, payload)
    logger.info(
        "run_auto_crud_remote: %s %s model=%s operation=%s",
        req["method"],
        req["url"],
        payload.get("model_name") or payload.get("model_code"),
        payload.get("operation"),
    )
    return await _execute_http_request(req["method"], req["url"], pat, req["json"])


async def _get_records_internal(payload: Dict[str, Any]) -> Dict[str, Any]:
    """List records via GET /data-models/auto/{model_name}/records (internal PAT)."""
    base_url = _resolve_base_url(payload, internal=True)
    if not base_url:
        raise ValueError("Unable to resolve base_url for internal auto-CRUD")
    pat = _resolve_pat(payload, internal=True)
    if not pat:
        raise ValueError("PAT (payload.pat or AUTO_CRUD_INTERNAL_PAT) required for internal auto-CRUD")
    model_name = payload.get("model_name") or payload.get("model_code") or payload.get("model")
    if not model_name:
        raise ValueError("model_name required for get_records")
    limit = int(payload.get("limit") or 100)
    offset = int(payload.get("offset") or 0)
    url = f"{base_url}/data-models/auto/{model_name}/records"
    params = {"limit": min(max(limit, 1), 1000), "offset": max(offset, 0)}
    filters = payload.get("filters") or {}
    if isinstance(filters, dict):
        for k, v in filters.items():
            if v is not None and k not in ("limit", "offset", "fields"):
                params[k] = v
    headers = {"Authorization": f"Bearer {pat}"} if pat else {}
    timeout = float(os.getenv("AUTO_CRUD_HTTP_TIMEOUT", "30"))
    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.get(url, params=params, headers=headers)
        try:
            body = resp.json()
        except Exception:
            body = resp.text
    if resp.status_code >= 400:
        logger.warning("auto_crud get_records HTTP GET %s -> %s", url, resp.status_code)
        return {"records": [], "model_name": model_name, "limit": limit, "offset": offset, "ok": False, "status_code": resp.status_code}
    return {
        "records": body.get("records", []) if isinstance(body, dict) else [],
        "model_name": model_name,
        "limit": limit,
        "offset": offset,
        "ok": True,
    }


async def run_auto_crud(payload: Dict[str, Any]) -> Dict[str, Any]:
    """
    Single entry point for auto_crud templates. Dispatches by payload.operation:
    - get_records: list records (model_name, filters, limit, offset)
    - create | update | delete: delegate to run_auto_crud_internal (or remote if payload.remote=True)
    """
    operation = (payload.get("operation") or "").lower()
    if operation == "get_records":
        return await _get_records_internal(payload)
    if operation in ("create", "update", "delete"):
        if payload.get("remote"):
            return await run_auto_crud_remote(payload)
        return await run_auto_crud_internal(payload)
    raise ValueError("operation must be get_records, create, update, or delete")


async def _auto_crud_get_records_wrapper(payload: Dict[str, Any]):
    """Thin wrapper so workflow step task 'auto_crud_get_records' works (template name = handler name)."""
    return await run_auto_crud({**payload, "operation": "get_records"})


register_handler("run_auto_crud_internal", run_auto_crud_internal)
register_handler("run_auto_crud_remote", run_auto_crud_remote)
register_handler("run_auto_crud", run_auto_crud)
register_handler("auto_crud_get_records", _auto_crud_get_records_wrapper)

