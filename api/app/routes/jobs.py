"""
Jobs API: submit job, get status, list jobs; schedulers CRUD (cron-based job creation).
"""
import logging
import os
import uuid
import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional

from fastapi import APIRouter, HTTPException, Header, Query
from pydantic import BaseModel

from classes.postgres_db import PostgresDB
from middlewares.auth import resolve_bearer_to_user

try:
    from croniter import croniter
except ImportError:
    croniter = None


def _next_run_from_cron(cron_expression: str, from_time: Optional[datetime] = None) -> Optional[datetime]:
    """Return next run datetime for cron expression (UTC)."""
    if not croniter:
        return None
    try:
        base = from_time or datetime.now(timezone.utc)
        it = croniter(cron_expression, base)
        return it.get_next(datetime)
    except Exception:
        return None


def _next_n_runs_from_cron(cron_expression: str, count: int = 3, from_time: Optional[datetime] = None) -> List[datetime]:
    """Return next N run datetimes for cron expression (UTC)."""
    if not croniter or count < 1:
        return []
    try:
        base = from_time or datetime.now(timezone.utc)
        it = croniter(cron_expression, base)
        return [it.get_next(datetime) for _ in range(count)]
    except Exception:
        return []

router = APIRouter()
logger = logging.getLogger("noolva_api.jobs.routes")


async def _require_user(authorization: Optional[str] = Header(None)):
    user = await resolve_bearer_to_user(authorization)
    if not user:
        raise HTTPException(status_code=401, detail="Authentication required (Bearer JWT or PAT)")
    return user


class SubmitJobRequest(BaseModel):
    template_name: str
    payload: Dict[str, Any] = {}
    schedule_time: Optional[str] = None  # ISO datetime or null = run asap


class RegisterWorkerRequest(BaseModel):
    worker_id: str
    worker_type: str = "remote"
    hostname: Optional[str] = None
    capabilities: Dict[str, Any] = {}
    max_concurrency: int = 1


@router.post("/jobs", response_model=Dict[str, Any])
async def submit_job(
    body: SubmitJobRequest,
    authorization: Optional[str] = Header(None),
):
    """Submit a job. Requires auth (JWT or PAT)."""
    await _require_user(authorization)
    template = await PostgresDB.fetchrow(
        "SELECT id FROM public.job_templates WHERE name = $1 AND COALESCE(is_active, true) = true",
        body.template_name,
    )
    if not template:
        raise HTTPException(status_code=400, detail=f"Unknown or inactive template: {body.template_name}")
    job_id = uuid.uuid4()
    schedule_time = body.schedule_time  # store as-is; DB column is TIMESTAMPTZ
    await PostgresDB.execute(
        """
        INSERT INTO public.jobs (id, template_id, payload, schedule_time, status)
        VALUES ($1, $2, $3, $4::timestamptz, 'pending')
        """,
        job_id,
        template["id"],
        body.payload,
        schedule_time,
    )
    return {"job_id": str(job_id), "status": "pending"}


@router.get("/jobs/{job_id}", response_model=Dict[str, Any])
async def get_job_status(
    job_id: str,
    authorization: Optional[str] = Header(None),
):
    """Get job status and result."""
    await _require_user(authorization)
    try:
        uid = uuid.UUID(job_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid job_id")
    row = await PostgresDB.fetchrow(
        "SELECT id, template_id, status, retry_count, result, started_at, completed_at, created_at FROM public.jobs WHERE id = $1",
        uid,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Job not found")
    return {
        "job_id": str(row["id"]),
        "template_id": str(row["template_id"]) if row.get("template_id") else None,
        "status": row["status"],
        "retry_count": row.get("retry_count", 0),
        "result": row.get("result"),
        "started_at": row["started_at"].isoformat() if row.get("started_at") else None,
        "completed_at": row["completed_at"].isoformat() if row.get("completed_at") else None,
        "created_at": row["created_at"].isoformat() if row.get("created_at") else None,
    }


@router.get("/jobs", response_model=List[Dict[str, Any]])
async def list_jobs(
    status: Optional[str] = Query(None),
    limit: int = Query(50, ge=1, le=200),
    authorization: Optional[str] = Header(None),
):
    """List jobs, optionally filtered by status."""
    await _require_user(authorization)
    if status:
        rows = await PostgresDB.fetch(
            """SELECT j.id, j.template_id, j.status, j.retry_count, j.created_at, j.result, t.name AS template_name
               FROM public.jobs j
               LEFT JOIN public.job_templates t ON j.template_id = t.id
               WHERE j.status = $1 ORDER BY j.created_at DESC LIMIT $2""",
            status,
            limit,
        )
    else:
        rows = await PostgresDB.fetch(
            """SELECT j.id, j.template_id, j.status, j.retry_count, j.created_at, j.result, t.name AS template_name
               FROM public.jobs j
               LEFT JOIN public.job_templates t ON j.template_id = t.id
               ORDER BY j.created_at DESC LIMIT $1""",
            limit,
        )
    return [
        {
            "job_id": str(r["id"]),
            "template_id": str(r["template_id"]) if r.get("template_id") else None,
            "template_name": r.get("template_name"),
            "status": r["status"],
            "retry_count": r.get("retry_count", 0),
            "created_at": r["created_at"].isoformat() if r.get("created_at") else None,
            "result": r.get("result"),
        }
        for r in rows
    ]


@router.get("/workers", response_model=List[Dict[str, Any]])
async def list_workers(authorization: Optional[str] = Header(None)):
    """List all registered workers."""
    await _require_user(authorization)
    rows = await PostgresDB.fetch(
        "SELECT worker_id, worker_type, hostname, status, max_concurrency, running_jobs, last_heartbeat, registered_at FROM public.workers ORDER BY worker_type, worker_id"
    )
    return [
        {
            "worker_id": r["worker_id"],
            "worker_type": r["worker_type"],
            "hostname": r.get("hostname"),
            "status": r.get("status"),
            "max_concurrency": r.get("max_concurrency", 0),
            "running_jobs": r.get("running_jobs", 0),
            "last_heartbeat": r["last_heartbeat"].isoformat() if r.get("last_heartbeat") else None,
            "registered_at": r["registered_at"].isoformat() if r.get("registered_at") else None,
        }
        for r in rows
    ]


@router.get("/job-templates", response_model=List[Dict[str, Any]])
async def list_job_templates(
    authorization: Optional[str] = Header(None),
    active_only: bool = Query(False, description="If true, return only active templates"),
):
    """List all job templates."""
    await _require_user(authorization)
    if active_only:
        rows = await PostgresDB.fetch(
            """SELECT id, name, description, template_category, handler_type, handler_function_name,
                      default_timeout_seconds, queue_concurrency_mode, queue_concurrency_limit, is_active
               FROM public.job_templates WHERE COALESCE(is_active, true) = true ORDER BY name"""
        )
    else:
        rows = await PostgresDB.fetch(
            """SELECT id, name, description, template_category, handler_type, handler_function_name,
                      default_timeout_seconds, queue_concurrency_mode, queue_concurrency_limit, is_active
               FROM public.job_templates ORDER BY name"""
        )
    return [
        {
            "template_id": str(r["id"]),
            "name": r["name"],
            "description": r.get("description"),
            "template_category": r.get("template_category") or "task",
            "handler_type": r.get("handler_type"),
            "handler_function_name": r.get("handler_function_name"),
            "default_timeout_seconds": r.get("default_timeout_seconds"),
            "queue_concurrency_mode": r.get("queue_concurrency_mode"),
            "queue_concurrency_limit": r.get("queue_concurrency_limit"),
            "is_active": r.get("is_active", True),
        }
        for r in rows
    ]


@router.get("/job-templates/{template_id}", response_model=Dict[str, Any])
async def get_job_template(
    template_id: str,
    authorization: Optional[str] = Header(None),
):
    """Get job template by id (for remote workers and edit form)."""
    await _require_user(authorization)
    try:
        uid = uuid.UUID(template_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid template_id")
    row = await PostgresDB.fetchrow(
        """SELECT id, name, description, template_category, handler_type, handler_function_name,
                  input_schema, workflow_definition, output_schema,
                  runnable_in, capabilities,
                  default_timeout_seconds, queue_concurrency_mode, queue_concurrency_limit,
                  retry_policy_json, is_idempotent, is_active, version
           FROM public.job_templates WHERE id = $1""",
        uid,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Template not found")
    return {
        "template_id": str(row["id"]),
        "name": row["name"],
        "description": row.get("description"),
        "template_category": row.get("template_category") or "task",
        "handler_type": row.get("handler_type"),
        "handler_function_name": row.get("handler_function_name"),
        "input_schema": row.get("input_schema"),
        "workflow_definition": row.get("workflow_definition"),
        "output_schema": row.get("output_schema"),
        "runnable_in": row.get("runnable_in"),
        "capabilities": row.get("capabilities"),
        "default_timeout_seconds": row.get("default_timeout_seconds"),
        "queue_concurrency_mode": row.get("queue_concurrency_mode"),
        "queue_concurrency_limit": row.get("queue_concurrency_limit"),
        "retry_policy_json": row.get("retry_policy_json"),
        "is_idempotent": row.get("is_idempotent", False),
        "is_active": row.get("is_active", True),
        "version": row.get("version"),
    }


class JobTemplateCreate(BaseModel):
    name: str
    description: Optional[str] = None
    template_category: str = "task"  # task | workflow | system
    handler_type: str = "core_function"
    handler_function_name: Optional[str] = None
    default_timeout_seconds: int = 3600
    queue_concurrency_mode: str = "parallel"
    queue_concurrency_limit: int = 0
    is_idempotent: bool = False


class JobTemplateUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    template_category: Optional[str] = None  # task | workflow | system
    handler_type: Optional[str] = None
    handler_function_name: Optional[str] = None
    default_timeout_seconds: Optional[int] = None
    queue_concurrency_mode: Optional[str] = None
    queue_concurrency_limit: Optional[int] = None
    is_idempotent: Optional[bool] = None
    is_active: Optional[bool] = None
    input_schema: Optional[Dict[str, Any]] = None
    workflow_definition: Optional[Dict[str, Any]] = None
    output_schema: Optional[Dict[str, Any]] = None
    retry_policy_json: Optional[Dict[str, Any]] = None


@router.post("/job-templates", response_model=Dict[str, Any])
async def create_job_template(
    body: JobTemplateCreate,
    authorization: Optional[str] = Header(None),
):
    """Create a job template."""
    await _require_user(authorization)
    existing = await PostgresDB.fetchrow("SELECT id FROM public.job_templates WHERE name = $1", body.name)
    if existing:
        raise HTTPException(status_code=400, detail=f"Template with name '{body.name}' already exists")
    template_id = uuid.uuid4()
    await PostgresDB.execute(
        """INSERT INTO public.job_templates (id, name, description, template_category, handler_type, handler_function_name,
                   default_timeout_seconds, queue_concurrency_mode, queue_concurrency_limit, is_idempotent)
           VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)""",
        template_id,
        body.name,
        body.description,
        body.template_category or "task",
        body.handler_type,
        body.handler_function_name or body.name,
        body.default_timeout_seconds,
        body.queue_concurrency_mode,
        body.queue_concurrency_limit,
        body.is_idempotent,
    )
    return {"template_id": str(template_id), "name": body.name}


@router.put("/job-templates/{template_id}", response_model=Dict[str, Any])
async def update_job_template(
    template_id: str,
    body: JobTemplateUpdate,
    authorization: Optional[str] = Header(None),
):
    """Update a job template (including activate/deactivate)."""
    await _require_user(authorization)
    try:
        uid = uuid.UUID(template_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid template_id")
    existing = await PostgresDB.fetchrow("SELECT id FROM public.job_templates WHERE id = $1", uid)
    if not existing:
        raise HTTPException(status_code=404, detail="Template not found")
    updates = []
    args = []
    pos = 1
    if body.name is not None:
        updates.append(f"name = ${pos}")
        args.append(body.name)
        pos += 1
    if body.description is not None:
        updates.append(f"description = ${pos}")
        args.append(body.description)
        pos += 1
    if body.template_category is not None:
        updates.append(f"template_category = ${pos}")
        args.append(body.template_category)
        pos += 1
    if body.handler_type is not None:
        updates.append(f"handler_type = ${pos}")
        args.append(body.handler_type)
        pos += 1
    if body.handler_function_name is not None:
        updates.append(f"handler_function_name = ${pos}")
        args.append(body.handler_function_name)
        pos += 1
    if body.default_timeout_seconds is not None:
        updates.append(f"default_timeout_seconds = ${pos}")
        args.append(body.default_timeout_seconds)
        pos += 1
    if body.queue_concurrency_mode is not None:
        updates.append(f"queue_concurrency_mode = ${pos}")
        args.append(body.queue_concurrency_mode)
        pos += 1
    if body.queue_concurrency_limit is not None:
        updates.append(f"queue_concurrency_limit = ${pos}")
        args.append(body.queue_concurrency_limit)
        pos += 1
    if body.is_idempotent is not None:
        updates.append(f"is_idempotent = ${pos}")
        args.append(body.is_idempotent)
        pos += 1
    if body.is_active is not None:
        updates.append(f"is_active = ${pos}")
        args.append(body.is_active)
        pos += 1
    if body.input_schema is not None:
        updates.append(f"input_schema = ${pos}::jsonb")
        # Store as JSON string to satisfy asyncpg's expected type
        args.append(json.dumps(body.input_schema))
        pos += 1
    if body.workflow_definition is not None:
        updates.append(f"workflow_definition = ${pos}::jsonb")
        args.append(json.dumps(body.workflow_definition))
        pos += 1
    if body.output_schema is not None:
        updates.append(f"output_schema = ${pos}::jsonb")
        args.append(json.dumps(body.output_schema))
        pos += 1
    if body.retry_policy_json is not None:
        updates.append(f"retry_policy_json = ${pos}::jsonb")
        args.append(json.dumps(body.retry_policy_json))
        pos += 1
    if not updates:
        return await get_job_template(template_id, authorization)
    args.append(uid)
    await PostgresDB.execute(
        f"UPDATE public.job_templates SET {', '.join(updates)} WHERE id = ${pos}",
        *args,
    )
    return await get_job_template(template_id, authorization)


@router.post("/workers/register", response_model=Dict[str, Any])
async def register_worker(
    body: RegisterWorkerRequest,
    authorization: Optional[str] = Header(None),
):
    """Register a remote/websocket/mobile worker."""
    await _require_user(authorization)
    worker_id = body.worker_id
    worker_type = body.worker_type
    if not worker_id:
        raise HTTPException(status_code=400, detail="worker_id required")
    await PostgresDB.execute(
        """
        INSERT INTO public.workers (worker_id, worker_type, hostname, status, capabilities, max_concurrency, last_heartbeat)
        VALUES ($1, $2, $3, 'idle', $4::jsonb, $5, now())
        ON CONFLICT (worker_id) DO UPDATE SET
            worker_type = EXCLUDED.worker_type,
            hostname = EXCLUDED.hostname,
            status = 'idle',
            capabilities = COALESCE(EXCLUDED.capabilities::jsonb, workers.capabilities),
            last_heartbeat = now()
        """,
        worker_id,
        worker_type,
        body.hostname,
        body.capabilities,
        body.max_concurrency,
    )
    return {"worker_id": worker_id, "status": "registered"}


@router.get("/jobs/claim", response_model=Optional[Dict[str, Any]])
async def claim_job(
    worker_id: str = Query(..., description="Worker claiming the job"),
    authorization: Optional[str] = Header(None),
):
    """Claim one pending/queued job for the given worker (for remote workers). Returns job or null."""
    await _require_user(authorization)
    row = await PostgresDB.fetchrow(
        """
        WITH claimed AS (
            SELECT id FROM public.jobs
            WHERE status = 'queued'
            ORDER BY created_at
            LIMIT 1
            FOR UPDATE SKIP LOCKED
        )
        UPDATE public.jobs j
        SET status = 'running', worker_id = $1, started_at = now(), updated_at = now()
        FROM claimed c WHERE j.id = c.id
        RETURNING j.id, j.template_id, j.payload, j.retry_count
        """,
        worker_id,
    )
    if not row:
        return None
    return {
        "job_id": str(row["id"]),
        "template_id": str(row["template_id"]) if row.get("template_id") else None,
        "payload": row.get("payload") or {},
        "retry_count": row.get("retry_count", 0),
    }


@router.post("/jobs/{job_id}/result")
async def submit_job_result(
    job_id: str,
    body: Dict[str, Any],
    authorization: Optional[str] = Header(None),
):
    """Submit job result (for remote workers after executing a claimed job)."""
    await _require_user(authorization)
    try:
        uid = uuid.UUID(job_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid job_id")
    status = body.get("status", "success")
    result = body.get("result")
    await PostgresDB.execute(
        """
        UPDATE public.jobs
        SET status = $1, result = $2, completed_at = now(), updated_at = now()
        WHERE id = $3 AND status = 'running'
        """,
        status,
        result,
        uid,
    )
    return {"job_id": job_id, "status": status}


@router.post("/jobs/{job_id}/cancel")
async def cancel_job(
    job_id: str,
    authorization: Optional[str] = Header(None),
):
    """Mark job as cancelled (only if pending or queued)."""
    await _require_user(authorization)
    try:
        uid = uuid.UUID(job_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid job_id")
    r = await PostgresDB.execute(
        "UPDATE public.jobs SET status = 'cancelled', updated_at = now() WHERE id = $1 AND status IN ('pending','queued')",
        uid,
    )
    if "UPDATE 0" in r:
        raise HTTPException(status_code=404, detail="Job not found or not cancellable")
    return {"job_id": job_id, "status": "cancelled"}


# ---------- Schedulers (cron jobs) ----------


@router.get("/schedulers/next-runs", response_model=List[str])
async def get_cron_next_runs(
    cron: str = Query(..., description="Cron expression"),
    count: int = Query(3, ge=1, le=10, description="Number of next run times to return"),
    authorization: Optional[str] = Header(None),
):
    """Return next N run times (ISO UTC) for a cron expression. Used by scheduler UI."""
    await _require_user(authorization)
    runs = _next_n_runs_from_cron(cron, count=count)
    return [r.isoformat() for r in runs]


class SchedulerCreate(BaseModel):
    name: str
    description: Optional[str] = None
    cron_expression: str
    template_id: str
    payload: Dict[str, Any] = {}
    is_enabled: bool = True


class SchedulerUpdate(BaseModel):
    name: Optional[str] = None
    description: Optional[str] = None
    cron_expression: Optional[str] = None
    template_id: Optional[str] = None
    payload: Optional[Dict[str, Any]] = None
    is_enabled: Optional[bool] = None


@router.get("/schedulers", response_model=List[Dict[str, Any]])
async def list_schedulers(authorization: Optional[str] = Header(None)):
    """List all schedulers."""
    await _require_user(authorization)
    rows = await PostgresDB.fetch(
        """SELECT s.id, s.name, s.description, s.cron_expression, s.template_id, s.payload, s.is_enabled,
                  s.last_run_at, s.next_run_at, s.created_at, s.updated_at, t.name AS template_name
           FROM public.schedulers s
           LEFT JOIN public.job_templates t ON s.template_id = t.id
           ORDER BY s.name"""
    )
    return [
        {
            "id": str(r["id"]),
            "name": r["name"],
            "description": r.get("description"),
            "cron_expression": r["cron_expression"],
            "template_id": str(r["template_id"]),
            "template_name": r.get("template_name"),
            "payload": r.get("payload") or {},
            "is_enabled": r.get("is_enabled", True),
            "last_run_at": r["last_run_at"].isoformat() if r.get("last_run_at") else None,
            "next_run_at": r["next_run_at"].isoformat() if r.get("next_run_at") else None,
            "created_at": r["created_at"].isoformat() if r.get("created_at") else None,
            "updated_at": r["updated_at"].isoformat() if r.get("updated_at") else None,
        }
        for r in rows
    ]


@router.get("/schedulers/{scheduler_id}", response_model=Dict[str, Any])
async def get_scheduler(scheduler_id: str, authorization: Optional[str] = Header(None)):
    """Get one scheduler."""
    await _require_user(authorization)
    try:
        sid = uuid.UUID(scheduler_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scheduler_id")
    row = await PostgresDB.fetchrow(
        """SELECT s.id, s.name, s.description, s.cron_expression, s.template_id, s.payload, s.is_enabled,
                  s.last_run_at, s.next_run_at, s.created_at, s.updated_at, t.name AS template_name
           FROM public.schedulers s
           LEFT JOIN public.job_templates t ON s.template_id = t.id
           WHERE s.id = $1""",
        sid,
    )
    if not row:
        raise HTTPException(status_code=404, detail="Scheduler not found")
    return {
        "id": str(row["id"]),
        "name": row["name"],
        "description": row.get("description"),
        "cron_expression": row["cron_expression"],
        "template_id": str(row["template_id"]),
        "template_name": row.get("template_name"),
        "payload": row.get("payload") or {},
        "is_enabled": row.get("is_enabled", True),
        "last_run_at": row["last_run_at"].isoformat() if row.get("last_run_at") else None,
        "next_run_at": row["next_run_at"].isoformat() if row.get("next_run_at") else None,
        "created_at": row["created_at"].isoformat() if row.get("created_at") else None,
        "updated_at": row["updated_at"].isoformat() if row.get("updated_at") else None,
    }


@router.post("/schedulers", response_model=Dict[str, Any])
async def create_scheduler(body: SchedulerCreate, authorization: Optional[str] = Header(None)):
    """Create a scheduler (cron job)."""
    await _require_user(authorization)
    try:
        tid = uuid.UUID(body.template_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid template_id")
    template = await PostgresDB.fetchrow("SELECT id FROM public.job_templates WHERE id = $1", tid)
    if not template:
        raise HTTPException(status_code=400, detail="Template not found")
    next_run = _next_run_from_cron(body.cron_expression)
    if not next_run and body.cron_expression:
        raise HTTPException(status_code=400, detail="Invalid cron_expression (e.g. use: 0 2 * * * for 2am daily)")
    scheduler_id = uuid.uuid4()
    next_run_ts = next_run.isoformat() if next_run else None
    payload_json = json.dumps(body.payload) if body.payload is not None else "{}"
    await PostgresDB.execute(
        """INSERT INTO public.schedulers (id, name, description, cron_expression, template_id, payload, is_enabled, next_run_at, updated_at)
           VALUES ($1, $2, $3, $4, $5, $6::jsonb, $7, $8, now())""",
        scheduler_id,
        body.name,
        body.description,
        body.cron_expression,
        tid,
        payload_json,
        body.is_enabled,
        next_run,
    )
    return {"id": str(scheduler_id), "name": body.name, "cron_expression": body.cron_expression, "next_run_at": next_run_ts}


@router.put("/schedulers/{scheduler_id}", response_model=Dict[str, Any])
async def update_scheduler(
    scheduler_id: str,
    body: SchedulerUpdate,
    authorization: Optional[str] = Header(None),
):
    """Update a scheduler."""
    await _require_user(authorization)
    try:
        sid = uuid.UUID(scheduler_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scheduler_id")
    existing = await PostgresDB.fetchrow("SELECT id, cron_expression, template_id FROM public.schedulers WHERE id = $1", sid)
    if not existing:
        raise HTTPException(status_code=404, detail="Scheduler not found")
    updates = []
    args = []
    pos = 1
    if body.name is not None:
        updates.append(f"name = ${pos}")
        args.append(body.name)
        pos += 1
    if body.description is not None:
        updates.append(f"description = ${pos}")
        args.append(body.description)
        pos += 1
    if body.cron_expression is not None:
        next_run = _next_run_from_cron(body.cron_expression)
        if not next_run:
            raise HTTPException(status_code=400, detail="Invalid cron_expression")
        updates.append(f"cron_expression = ${pos}")
        args.append(body.cron_expression)
        pos += 1
        updates.append(f"next_run_at = ${pos}")
        args.append(next_run)
        pos += 1
    if body.template_id is not None:
        try:
            tid = uuid.UUID(body.template_id)
        except ValueError:
            raise HTTPException(status_code=400, detail="Invalid template_id")
        template = await PostgresDB.fetchrow("SELECT id FROM public.job_templates WHERE id = $1", tid)
        if not template:
            raise HTTPException(status_code=400, detail="Template not found")
        updates.append(f"template_id = ${pos}")
        args.append(tid)
        pos += 1
    if body.payload is not None:
        updates.append(f"payload = ${pos}::jsonb")
        args.append(json.dumps(body.payload))
        pos += 1
    if body.is_enabled is not None:
        updates.append(f"is_enabled = ${pos}")
        args.append(body.is_enabled)
        pos += 1
    if not updates:
        return await get_scheduler(scheduler_id, authorization)
    updates.append("updated_at = now()")
    args.append(sid)
    await PostgresDB.execute(
        f"UPDATE public.schedulers SET {', '.join(updates)} WHERE id = ${pos}",
        *args,
    )
    return await get_scheduler(scheduler_id, authorization)


@router.delete("/schedulers/{scheduler_id}")
async def delete_scheduler(scheduler_id: str, authorization: Optional[str] = Header(None)):
    """Delete a scheduler."""
    await _require_user(authorization)
    try:
        sid = uuid.UUID(scheduler_id)
    except ValueError:
        raise HTTPException(status_code=400, detail="Invalid scheduler_id")
    r = await PostgresDB.execute("DELETE FROM public.schedulers WHERE id = $1", sid)
    if "DELETE 0" in r:
        raise HTTPException(status_code=404, detail="Scheduler not found")
    return {"deleted": scheduler_id}
