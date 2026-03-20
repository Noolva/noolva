"""
Remote worker script: register with API, poll for claimed jobs, run handlers, submit results.
Run from repo root: python -m app.jobs.remote_worker
Or from api/: python -m app.jobs.remote_worker
Requires: API_BASE_URL (e.g. http://localhost:9001), AUTH_TOKEN (Bearer PAT or JWT), WORKER_ID (e.g. vm-worker-1).
"""
import asyncio
import logging
import os
import sys

# Ensure app is on path when run as script
if __name__ == "__main__":
    api_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
    if api_dir not in sys.path:
        sys.path.insert(0, api_dir)

import httpx

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger("remote_worker")

API_BASE = os.getenv("API_BASE_URL", "http://localhost:9001").rstrip("/")
AUTH_TOKEN = os.getenv("AUTH_TOKEN") or os.getenv("PAT")
WORKER_ID = os.getenv("WORKER_ID", "remote-worker-1")
WORKER_TYPE = os.getenv("WORKER_TYPE", "remote")
POLL_INTERVAL = float(os.getenv("POLL_INTERVAL", "5"))


async def register(client: httpx.AsyncClient) -> bool:
    headers = {"Authorization": f"Bearer {AUTH_TOKEN}", "Content-Type": "application/json"}
    try:
        r = await client.post(
            f"{API_BASE}/workers/register",
            json={"worker_id": WORKER_ID, "worker_type": WORKER_TYPE, "hostname": os.getenv("HOSTNAME", "")},
            headers=headers,
        )
        if r.status_code in (200, 201):
            logger.info("Registered as %s", WORKER_ID)
            return True
        logger.error("Register failed: %s %s", r.status_code, r.text)
        return False
    except Exception as e:
        logger.exception("Register error: %s", e)
        return False


async def claim(client: httpx.AsyncClient):
    headers = {"Authorization": f"Bearer {AUTH_TOKEN}"}
    try:
        r = await client.get(f"{API_BASE}/jobs/claim", params={"worker_id": WORKER_ID}, headers=headers)
        if r.status_code != 200:
            return None
        data = r.json()
        if data is None or not data.get("job_id"):
            return None
        return data
    except Exception as e:
        logger.exception("Claim error: %s", e)
        return None


async def get_template(client: httpx.AsyncClient, template_id: str):
    headers = {"Authorization": f"Bearer {AUTH_TOKEN}"}
    try:
        r = await client.get(f"{API_BASE}/job-templates/{template_id}", headers=headers)
        if r.status_code != 200:
            return None
        return r.json()
    except Exception as e:
        logger.exception("Get template error: %s", e)
        return None


async def submit_result(client: httpx.AsyncClient, job_id: str, status: str, result: dict):
    headers = {"Authorization": f"Bearer {AUTH_TOKEN}", "Content-Type": "application/json"}
    try:
        r = await client.post(
            f"{API_BASE}/jobs/{job_id}/result",
            json={"status": status, "result": result},
            headers=headers,
        )
        if r.status_code != 200:
            logger.error("Submit result failed: %s %s", r.status_code, r.text)
    except Exception as e:
        logger.exception("Submit result error: %s", e)


async def run_handler(handler_type: str, handler_function_name: str, payload: dict) -> tuple[str, dict]:
    """Run handler in-process (same code as API). Returns (status, result)."""
    if handler_type != "core_function":
        return "failed", {"error": "Only core_function supported in remote worker"}
    try:
        from app.jobs.handlers.registry import ensure_handlers_loaded, run_core_function
        ensure_handlers_loaded()
        out = await run_core_function(handler_function_name, payload)
        return "success", out
    except Exception as e:
        logger.exception("Handler error: %s", e)
        return "failed", {"error": str(e)}


async def run_worker_loop(client: httpx.AsyncClient):
    while True:
        job = await claim(client)
        if not job:
            await asyncio.sleep(POLL_INTERVAL)
            continue
        job_id = job["job_id"]
        template_id = job.get("template_id")
        payload = job.get("payload") or {}
        if not template_id:
            await submit_result(client, job_id, "failed", {"error": "No template_id"})
            continue
        template = await get_template(client, template_id)
        if not template:
            await submit_result(client, job_id, "failed", {"error": "Template not found"})
            continue
        status, result = await run_handler(
            template.get("handler_type", "core_function"),
            template.get("handler_function_name", ""),
            payload,
        )
        await submit_result(client, job_id, status, result)
        logger.info("Job %s finished with %s", job_id, status)


async def main():
    if not AUTH_TOKEN:
        logger.error("Set AUTH_TOKEN or PAT environment variable")
        sys.exit(1)
    async with httpx.AsyncClient() as client:
        if not await register(client):
            sys.exit(2)
        await run_worker_loop(client)


if __name__ == "__main__":
    asyncio.run(main())
