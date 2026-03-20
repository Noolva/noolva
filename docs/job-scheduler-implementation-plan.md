# Job Scheduler System — Implementation Plan

**Implementation completed.** DB migration, QueueManager, scheduler, workers, jobs API, remote worker script, and workflow execution are in place. Old `queue_handler` / `job_workers` are deprecated (see comments in code).

## Overview

Replace the old **job_queue** + **actions** tables and in-memory `queue_handler` with a PostgreSQL-backed job system: **scheduler** → **QueueManager** (ready_queue, delayed_queue, cron_registry) → **workers** (local, remote, websocket, mobile). All job state lives in PostgreSQL.

---

## 1. Database Changes

### 1.1 Drop Old Objects

- **Drop order** (respect FKs):
  1. `job_queue` (references `actions`, `workflows`, `workflow_runs`, `companies`, `users`)
  2. `actions`
- **Optional (if unused):** `workflow_runs`, then `workflows`. No API code currently references these; confirm before dropping.

### 1.2 New Tables

| Table | Purpose |
|-------|--------|
| `workers` | Worker registry: worker_id, worker_type (local \| remote \| websocket \| mobile), hostname, status, capabilities, max_concurrency, running_jobs, last_heartbeat, metadata |
| `job_templates` | Template definitions: name, input_schema, workflow_definition (JSON), handler_type (core_function \| custom_script \| dedicated_worker), handler_function_name / script_path, runnable_in, capabilities, retry_policy_json, default_timeout_seconds, etc. |
| `jobs` | Job instances: id (UUID), template_id → job_templates, payload (JSONB), schedule_time, status (pending \| queued \| running \| success \| failed), retry_count, created_at, updated_at |
| `job_step_runs` | Per-step execution: id, job_id → jobs, step_id, worker_id → workers, status, input_data, output_data, started_at, finished_at |

- Add `workers` first (no dependency on job tables).
- Add `job_templates`, then `jobs` (FK to job_templates), then `job_step_runs` (FK to jobs, workers).
- Indexes: `jobs(status)`, `jobs(schedule_time)`, `jobs(template_id)`, `job_step_runs(job_id)`, `workers(worker_type, status)`.

### 1.3 Migration Files (per .cursorrules)

- **Schema:** Update `db-structure/noolvandb_schema.sql`: remove `actions` and `job_queue` (and optionally `workflow_runs`, `workflows`); add `workers`, `job_templates`, `jobs`, `job_step_runs` with indexes.
- **Existing DBs:** Add `db-structure/update_old_db_job_scheduler.sql`:
  - Drop `job_queue`, then `actions` (and optionally workflow_runs, workflows).
  - Create `workers`, `job_templates`, `jobs`, `job_step_runs` (same DDL as in schema).
- **Feeds:** If any seed data for old `actions` is to be preserved as `job_templates`, add a seed script or section in `db-structure/noolvandb_feeds.sql` for initial `job_templates` (e.g. send_email, generate_report).

---

## 2. Environment Variables

Add to `api/.env` (and document in `how-to-run-api`):

```bash
# ---------------------------------------------------------
# JOB SCHEDULER SYSTEM CONFIGURATION
# ---------------------------------------------------------
ENABLE_SCHEDULER=true
SCHEDULER_INTERVAL=5
SCHEDULER_FETCH_LIMIT=100

# Workers
WORKER_COUNT=2
WORKER_CONCURRENCY=3

# Queue
QUEUE_MAX_SIZE=10000

# Job execution safety
DEFAULT_JOB_TIMEOUT_SECONDS=300
DEFAULT_JOB_MAX_RETRIES=3

# Memory limits (MB)
WORKER_MEMORY_LIMIT_MB=512
SERVER_MEMORY_LIMIT_MB=1024
```

Note: In your spec the second `DEFAULT_JOB_TIMEOUT_SECONDS=300` was for retries; use `DEFAULT_JOB_MAX_RETRIES=3` as above.

---

## 3. Application Architecture

### 3.1 Main Server (Noolva API)

- **FastAPI** — existing app.
- **QueueManager** (new module, e.g. `api/app/jobs/queue_manager.py`):
  - `ready_queue`: `asyncio.PriorityQueue` (priority from job payload or schedule_time).
  - `delayed_queue`: heap (or sorted structure) for `schedule_time`; scheduler moves due jobs into `ready_queue`.
  - `cron_registry`: dict of cron expression → template_id / job creation logic; scheduler evaluates and enqueues.
- **scheduler_task()** (async loop):
  - If `ENABLE_SCHEDULER` false, skip.
  - Every `SCHEDULER_INTERVAL` seconds: poll PostgreSQL for jobs where `status = 'pending'` and `schedule_time <= now()` (or null), limit `SCHEDULER_FETCH_LIMIT`; set `status = 'queued'` and push to `ready_queue`; optionally evaluate `cron_registry` and insert new jobs.
  - Move due items from `delayed_queue` into `ready_queue`.

**Where to add cron jobs:** There is no UI for cron yet. Register in code via `QueueManager.cron_register(key, config)` after getting the singleton with `get_queue_manager()`. Example: in `main.py` lifespan (after DB connect) or in a dedicated module (e.g. `api/app/jobs/cron_registry.py`) that you import from lifespan:

```python
from jobs.queue_manager import get_queue_manager
qm = get_queue_manager()
qm.cron_register("daily_cleanup", {"cron": "0 2 * * *", "template_name": "generate_report", "payload": {"type": "daily"}})
```

The scheduler does not yet evaluate `cron_registry` each cycle (e.g. with a cron parser to create pending jobs in the DB); that logic can be added in `scheduler.py` when needed.

### 3.4 Auto-CRUD job templates (internal and remote)

Two generic job templates are used to run background auto-CRUD operations on data models:

- `auto_crud_internal`:
  - `handler_type = 'core_function'`
  - `handler_function_name = 'run_auto_crud_internal'`
  - `runnable_in = ['local']`
  - Payload (stored in `jobs.payload`) includes:
    - `model_name` (or `model_code`)
    - `operation` (`create` | `update` | `delete`)
    - `record_id` (for update/delete)
    - `data` (for create/update)
    - `creator_user_id`, `run_as_user_id` (identity under which the job executes)
- `auto_crud_remote`:
  - `handler_type = 'core_function'`
  - `handler_function_name = 'run_auto_crud_remote'`
  - `runnable_in = ['local','remote']`
  - Same payload fields as internal, plus:
    - `remote_base_url` (remote Noolva API base URL)
    - (Future) `remote_integration_id` for credentials, if needed

These templates are seeded for **new DBs** in `noolvandb_schema.sql` (or can be added as part of feeds) and for existing DBs via `db-structure/update_old_db_auto_crud_templates.sql`.
- **worker_task_1() … worker_task_N()** (N = WORKER_COUNT):
  - Each runs a loop: get job from `ready_queue` (with timeout), claim in DB (status → `running`, set worker_id if using workers table), execute handler, then set `success`/`failed` and update `job_step_runs` for workflow steps.
- **Lifespan:** In `main.py` lifespan, start scheduler_task and worker tasks as background asyncio tasks; cancel them on shutdown.

### 3.2 Handler Types

| Type | Where | Example |
|------|--------|--------|
| core_function | In API repo | send_email, generate_report — call Python function by name (e.g. registry map). |
| custom_script | External script | script_path e.g. `/scripts/rag_pipeline.py` — subprocess or dedicated runner. |
| dedicated_worker | Specific worker type | Only run on workers that advertise capability / type (e.g. laptop). |

Execution layer resolves handler from `job_templates.handler_type` + `handler_function_name` or `script_path`; for workflows, run steps per `workflow_definition` (see below).

### 3.3 Workflow Execution

- `workflow_definition` JSON: `execution: "sequential"`, `steps: [{ id, task, requirements, inputs }]`.
- Runner: for each step, resolve task name to a job_template or core task; resolve `inputs` from `$input.*` and `$step.<step_id>.output`; create `job_step_runs` row; assign to worker (by capabilities / runnable_in); on success, set output and continue; on failure, mark job failed and optionally retry per retry_policy.

### 3.4 Workers Table Usage

- **Local workers:** On API startup, register N workers (e.g. `api1-local-1`, `api1-local-2`) with `worker_type = 'local'`, `max_concurrency = WORKER_CONCURRENCY`; heartbeat periodically; update `running_jobs` when claiming/releasing.
- **Remote / websocket / mobile:** Other processes (e.g. `remote_worker.py`) register with their `worker_id` and type; poll or receive jobs from API (or via WebSocket), update status and heartbeat. API assigns jobs to workers based on `runnable_in` and `capabilities` from `job_templates`.

---

## 4. Code Layout (Suggested)

```
api/app/
  jobs/
    __init__.py
    queue_manager.py    # QueueManager, ready_queue, delayed_queue, cron_registry
    scheduler.py        # scheduler_task()
    worker.py           # worker_task(), run one job (core_function / script / workflow step)
    handlers/           # core_function implementations
      __init__.py
      registry.py       # map handler_function_name -> callable
      send_email.py
      generate_report.py
    models.py           # Pydantic or dataclasses for Job, JobTemplate, Worker
  main.py               # lifespan: start scheduler + workers, stop on shutdown
```

Optional: `api/app/jobs/routes.py` for REST: submit job, get status, list jobs, cancel (set status to cancelled and don’t hand to workers).

---

## 5. Remote Worker (Separate Process)

- **Script:** e.g. `remote_worker.py` (or under `api/app/jobs/` as a runnable script).
- **Behavior:** Register with API (POST /workers/register or similar) with worker_id, worker_type=remote, hostname, capabilities; then poll GET /jobs/claim?worker_id=... (or long-poll); execute claimed job (same handler resolution as local); PATCH /jobs/:id/result and heartbeat.

---

## 6. Implementation Order

1. **DB:** Migration script to drop job_queue + actions; add workers, job_templates, jobs, job_step_runs; update noolvandb_schema.sql and feeds if needed.
2. **Env:** Add all new env vars to `.env` and how-to-run-api.
3. **QueueManager:** Implement ready_queue, delayed_queue, cron_registry and minimal methods (enqueue, dequeue, add_delayed, add_cron).
4. **Scheduler:** Implement scheduler_task (DB poll → enqueue; delayed_queue drain; cron tick).
5. **Worker:** Implement worker_task (get from queue, load template, run handler, update DB and job_step_runs).
6. **Handlers:** Registry + at least one core_function (e.g. send_email stub); resolve handler_type and handler_function_name from template.
7. **Lifespan:** Wire scheduler and workers in main.py; graceful shutdown.
8. **Jobs API:** Optional routes to submit job, get status, list.
9. **Remote worker:** remote_worker.py and any /workers, /jobs/claim endpoints.
10. **Workflows:** Implement sequential execution of workflow_definition and job_step_runs updates.
11. **Deprecate:** Remove or refactor `queue_handler.py` and `job_workers.py` to use the new system (or delete once all callers use the new jobs API).

---

## 7. Worker Types Summary

| worker_id      | type     | Where          |
|----------------|----------|----------------|
| server-worker-1 | local   | Main API       |
| vm-worker-1   | remote   | remote_worker.py on other servers |
| karan-laptop  | websocket| Laptops (future) |
| mobile-234    | mobile   | Firebase (future) |

PostgreSQL remains the single source of truth for job and worker state; the in-memory queues are only for fast dispatch between scheduler and workers on the same process.

---

## 8. Checklist Before Going Live

- [ ] Migration run on a copy of production DB; verify no remaining references to `job_queue` or `actions` in app code.
- [ ] Env vars documented and set in all environments.
- [ ] Scheduler and workers start only when `ENABLE_SCHEDULER=true`.
- [ ] Timeout and max retries applied; stuck jobs marked failed after DEFAULT_JOB_TIMEOUT_SECONDS.
- [ ] Memory limits (WORKER_MEMORY_LIMIT_MB, SERVER_MEMORY_LIMIT_MB) monitored or enforced (e.g. worker restart policy).
- [ ] At least one job_template seeded and one end-to-end job (e.g. send_email) tested.
