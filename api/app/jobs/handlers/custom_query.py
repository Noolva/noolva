"""
Custom Query handler for jobs.

- When job runs on API (local worker): executes the query directly via DB, no HTTP or PAT.
- When job runs on remote worker: calls the API via HTTP; requires PAT in payload or CUSTOM_QUERY_PAT env.

Expected payload:
- endpoint_id: int (optional) - api_endpoints.endpoint_id of the custom_query endpoint
- endpoint_path: str (optional) - path to resolve to endpoint_id (e.g. "/job-workflows/pending_alarms")
- method: str (optional, default "GET") - used with endpoint_path for lookup
- limit: int (optional, default 100)
- offset: int (optional, default 0)
- pat: str (optional) - Bearer token for remote worker; not needed for local
- base_url: str (optional) - for remote worker; used when calling API via HTTP
"""
import logging
import os
from typing import Any, Dict, Optional

import httpx

from .registry import register_handler

logger = logging.getLogger("noolva_api.jobs.handlers.custom_query")


def _resolve_base_url(payload: Dict[str, Any]) -> str:
    url = payload.get("base_url") or os.getenv("CUSTOM_QUERY_BASE_URL") or os.getenv("API_BASE_URL")
    if not url:
        port = os.getenv("APPLICATION_PORT", "9001")
        url = f"http://localhost:{port}"
    return url.rstrip("/")


def _resolve_pat(payload: Dict[str, Any]) -> Optional[str]:
    if "pat" in payload:
        return payload.get("pat")
    return os.getenv("CUSTOM_QUERY_PAT")


def _is_running_local() -> bool:
    """True if we have DB access (API process, local worker)."""
    from classes.postgres_db import PostgresDB
    return getattr(PostgresDB, "_pool", None) is not None


async def _resolve_endpoint_id(payload: Dict[str, Any]) -> int:
    endpoint_id = payload.get("endpoint_id")
    if endpoint_id is not None:
        return int(endpoint_id)
    path = (payload.get("endpoint_path") or "").strip()
    if not path:
        raise ValueError("endpoint_id or endpoint_path is required for custom query job")
    method = (payload.get("method") or "GET").upper()
    try:
        from classes.postgres_db import PostgresDB
        row = await PostgresDB.fetchrow(
            "SELECT endpoint_id FROM public.api_endpoints WHERE path = $1 AND method = $2 LIMIT 1",
            path,
            method,
        )
        if not row:
            raise ValueError(f"API endpoint not found for path={path!r} method={method!r}")
        return int(row["endpoint_id"])
    except ValueError:
        raise
    except Exception as e:
        raise ValueError(f"Failed to resolve endpoint_path {path!r}: {e}") from e


async def run_custom_query_endpoint(payload: Dict[str, Any]) -> Dict[str, Any]:
    endpoint_id = await _resolve_endpoint_id(payload)

    try:
        limit = int(payload.get("limit") or 100)
    except (TypeError, ValueError):
        limit = 100
    try:
        offset = int(payload.get("offset") or 0)
    except (TypeError, ValueError):
        offset = 0

    limit = min(max(limit, 1), 1000)
    offset = max(offset, 0)

    # Local: execute directly (no HTTP, no PAT)
    if _is_running_local():
        try:
            from routes.data_models import execute_custom_endpoint_direct
            body = await execute_custom_endpoint_direct(endpoint_id, limit=limit, offset=offset, user=None, request=None)
            row_count = body.get("row_count", len(body.get("records", [])))
            logger.info("run_custom_query_endpoint: direct execution endpoint_id=%s returned %d records", endpoint_id, row_count)
            return {"status_code": 200, "body": body, "ok": True}
        except Exception as e:
            logger.exception("run_custom_query_endpoint direct execution failed: %s", e)
            raise

    # Remote: call API via HTTP (requires PAT)
    base_url = _resolve_base_url(payload)
    pat = _resolve_pat(payload)
    url = f"{base_url}/data-models/custom-endpoint/{endpoint_id}"
    params = {"limit": limit, "offset": offset}
    headers = {"Authorization": f"Bearer {pat}"} if pat else {}

    timeout = float(os.getenv("CUSTOM_QUERY_HTTP_TIMEOUT", "30"))
    async with httpx.AsyncClient(timeout=timeout) as client:
        resp = await client.get(url, params=params, headers=headers)
        try:
            body = resp.json()
        except Exception:
            body = resp.text

    if resp.status_code >= 400:
        logger.warning(
            "run_custom_query_endpoint HTTP %s %s -> %s",
            resp.request.method,
            resp.request.url,
            resp.status_code,
        )

    return {
        "status_code": resp.status_code,
        "body": body,
        "ok": 200 <= resp.status_code < 300,
    }


register_handler("run_custom_query_endpoint", run_custom_query_endpoint)
# Template name for workflow steps (step "task": "custom_query_endpoint")
register_handler("custom_query_endpoint", run_custom_query_endpoint)

