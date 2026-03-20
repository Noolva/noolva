"""
Worker task: pull job from ready_queue, load template, run handler, update DB (and job_step_runs for workflows).
"""
import asyncio
import json
import logging
import os
import time
import uuid
from typing import Any, Dict, Optional

from classes.postgres_db import PostgresDB
from jobs.queue_manager import get_queue_manager
from jobs.handlers.registry import ensure_handlers_loaded, get_handler, run_core_function

logger = logging.getLogger("noolva_api.jobs.worker")


async def run_job(job: Dict[str, Any], worker_id: str) -> None:
    job_id = job.get("id")
    template_id = job.get("template_id")
    payload = job.get("payload") or {}
    timeout_sec = int(os.getenv("DEFAULT_JOB_TIMEOUT_SECONDS", "300"))
    max_retries = int(os.getenv("DEFAULT_JOB_MAX_RETRIES", "3"))

    # Claim in DB (idempotent: only if still queued, so we don't double-run with remote worker)
    try:
        jid = uuid.UUID(job_id) if isinstance(job_id, str) else job_id
        r = await PostgresDB.execute(
            """
            UPDATE public.jobs
            SET status = 'running', worker_id = $1, started_at = now(), updated_at = now()
            WHERE id = $2 AND status = 'queued'
            """,
            worker_id,
            jid,
        )
        if r and "UPDATE 0" in r:
            logger.info("Worker %s: job %s already claimed by another worker, skipping", worker_id, job_id)
            return
    except Exception as e:
        logger.exception("Worker %s: failed to mark job %s running: %s", worker_id, job_id, e)
        return

    template = None
    if template_id:
        template = await PostgresDB.fetchrow(
            "SELECT id, name, handler_type, handler_function_name, workflow_definition FROM public.job_templates WHERE id = $1",
            uuid.UUID(template_id) if isinstance(template_id, str) else template_id,
        )

    try:
        if template and template.get("workflow_definition"):
            result = await _run_workflow(job_id, template, payload, worker_id, timeout_sec)
        elif template and template.get("handler_type") == "core_function":
            ensure_handlers_loaded()
            fn_name = template.get("handler_function_name")
            if not fn_name:
                raise ValueError("handler_function_name required for core_function")
            result = await asyncio.wait_for(run_core_function(fn_name, payload), timeout=timeout_sec)
        elif template and template.get("handler_type") == "custom_script":
            result = await _run_script(template.get("script_path"), payload, timeout_sec)
        else:
            # No template or unknown: try by name
            ensure_handlers_loaded()
            name = template.get("name") if template else payload.get("_handler") or "send_email"
            fn = get_handler(name)
            if fn:
                result = await asyncio.wait_for(run_core_function(name, payload), timeout=timeout_sec)
            else:
                raise ValueError(f"No handler for template {template_id or 'none'}")
    except asyncio.TimeoutError:
        await _mark_failed(job_id, "Job timed out", worker_id)
        _maybe_retry(job_id, job.get("retry_count", 0), max_retries)
        return
    except Exception as e:
        logger.exception("Worker %s: job %s failed: %s", worker_id, job_id, e)
        await _mark_failed(job_id, str(e), worker_id)
        _maybe_retry(job_id, job.get("retry_count", 0), max_retries)
        return

    result_json = json.dumps(result, default=str) if result is not None else "{}"
    await PostgresDB.execute(
        """
        UPDATE public.jobs
        SET status = 'success', result = $1::jsonb, completed_at = now(), updated_at = now()
        WHERE id = $2
        """,
        result_json,
        uuid.UUID(job_id) if isinstance(job_id, str) else job_id,
    )
    logger.info("Worker %s: job %s success", worker_id, job_id)


async def _mark_failed(job_id: str, error_msg: str, worker_id: str):
    result_json = json.dumps({"error": error_msg})
    await PostgresDB.execute(
        """
        UPDATE public.jobs
        SET status = 'failed', result = $1::jsonb, completed_at = now(), updated_at = now()
        WHERE id = $2
        """,
        result_json,
        uuid.UUID(job_id) if isinstance(job_id, str) else job_id,
    )


def _maybe_retry(job_id: str, retry_count: int, max_retries: int):
    if retry_count < max_retries:
        # Re-queue by resetting status to pending (scheduler will pick up)
        asyncio.create_task(_reset_pending(job_id, retry_count + 1))


async def _reset_pending(job_id: str, new_retry_count: int):
    await PostgresDB.execute(
        "UPDATE public.jobs SET status = 'pending', retry_count = $1, updated_at = now() WHERE id = $2",
        new_retry_count,
        uuid.UUID(job_id) if isinstance(job_id, str) else job_id,
    )


def _resolve_expression(val: Any, ctx: Dict[str, Any]) -> Any:
    """Resolve $foo.bar.baz from ctx (input, step.<id>.output, or output name like alarm_list)."""
    if not isinstance(val, str) or not val.startswith("$"):
        return val
    path = val[1:].strip()
    if not path:
        return val
    parts = path.split(".")
    key = parts[0]
    # $record.xxx is resolved per-record in create_jobs_from_records, not here
    if key == "record":
        return val
    if key == "input":
        obj = ctx.get("input", {})
        if len(parts) == 1:
            return obj
        for p in parts[1:]:
            obj = obj.get(p) if isinstance(obj, dict) else getattr(obj, p, None)
        return obj
    if key == "step" and len(parts) >= 2:
        step_out = ctx.get("step", {}).get(parts[1], {}).get("output")
        for p in parts[2:]:
            step_out = step_out.get(p) if isinstance(step_out, dict) else getattr(step_out, p, None)
        return step_out
    # Output-name binding: $alarm_list.records
    obj = ctx.get(key)
    if obj is None and key in ctx.get("step", {}):
        obj = ctx["step"][key].get("output")
    for p in parts[1:]:
        obj = obj.get(p) if isinstance(obj, dict) else getattr(obj, p, None)
    return obj


def _resolve_step_input(step_input: Dict[str, Any], ctx: Dict[str, Any]) -> Dict[str, Any]:
    """Recursively resolve $ expressions in step input (including nested dicts)."""
    resolved = {}
    for k, v in step_input.items():
        if isinstance(v, dict):
            resolved[k] = _resolve_step_input(v, ctx)
        elif isinstance(v, str) and v.startswith("$"):
            resolved[k] = _resolve_expression(v, ctx)
        else:
            resolved[k] = v
    return resolved


async def _run_workflow(
    job_id: str, template: Dict, payload: Dict, worker_id: str, timeout_sec: int
) -> Dict[str, Any]:
    wf_raw = template.get("workflow_definition") or {}
    if isinstance(wf_raw, str):
        try:
            wf = json.loads(wf_raw) if wf_raw.strip() else {}
        except json.JSONDecodeError:
            wf = {}
    else:
        wf = wf_raw if isinstance(wf_raw, dict) else {}
    steps = wf.get("steps") or []
    execution = wf.get("execution", "sequential")
    ctx = {"input": payload, "step": {}}

    for step in steps:
        step_id = step.get("id", "")
        task_name = step.get("task", "")
        step_input = step.get("input") or step.get("inputs") or {}
        resolved = _resolve_step_input(step_input, ctx)
        if task_name == "create_jobs_from_records" and "records" in resolved:
            logger.info("create_jobs_from_records step: resolved records count=%s", len(resolved.get("records") or []))

        # Create step run record
        step_run_id = uuid.uuid4()
        input_data_json = json.dumps(resolved, default=str) if resolved else "{}"
        await PostgresDB.execute(
            """
            INSERT INTO public.job_step_runs (id, job_id, step_id, worker_id, status, input_data, started_at)
            VALUES ($1, $2, $3, $4, 'running', $5::jsonb, now())
            """,
            step_run_id,
            uuid.UUID(job_id) if isinstance(job_id, str) else job_id,
            step_id,
            worker_id,
            input_data_json,
        )

        ensure_handlers_loaded()
        fn = get_handler(task_name)
        if not fn:
            raise ValueError(f"Unknown task in workflow: {task_name}")
        step_result = await asyncio.wait_for(run_core_function(task_name, resolved), timeout=timeout_sec)
        ctx["step"][step_id] = {"output": step_result}
        output_name = step.get("output")
        if output_name:
            ctx[output_name] = step_result

        output_data_json = json.dumps(step_result, default=str) if step_result is not None else "{}"
        await PostgresDB.execute(
            """
            UPDATE public.job_step_runs SET status = 'success', output_data = $1::jsonb, finished_at = now() WHERE id = $2
            """,
            output_data_json,
            step_run_id,
        )

    return ctx["step"]


async def _run_script(script_path: Optional[str], payload: Dict, timeout_sec: int) -> Dict[str, Any]:
    if not script_path:
        raise ValueError("script_path required for custom_script")
    # Subprocess run (stub)
    logger.warning("custom_script not implemented: %s", script_path)
    return {"ok": False, "error": "custom_script not implemented"}


async def worker_loop(worker_id: str):
    qm = get_queue_manager()
    get_timeout = 1.0
    while True:
        job = await qm.ready_get(timeout=get_timeout)
        if job:
            await run_job(job, worker_id)
        await asyncio.sleep(0)
