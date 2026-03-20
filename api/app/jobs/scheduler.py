"""
Scheduler task: poll DB for pending jobs (schedule_time <= now), mark queued, push to ready_queue.
Evaluate schedulers table (cron) and create pending jobs when due. Move due items from delayed_queue into ready_queue.
"""
import asyncio
import logging
import os
import time
import uuid
from datetime import datetime, timezone
from typing import Optional

from classes.postgres_db import PostgresDB
from jobs.queue_manager import get_queue_manager

logger = logging.getLogger("noolva_api.jobs.scheduler")

try:
    from croniter import croniter
except ImportError:
    croniter = None


def _next_run_from_cron(cron_expression: str, from_time: Optional[datetime] = None) -> Optional[datetime]:
    if not croniter:
        return None
    try:
        base = from_time or datetime.now(timezone.utc)
        it = croniter(cron_expression, base)
        return it.get_next(datetime)
    except Exception:
        return None


async def _run_due_schedulers():
    """Find schedulers where next_run_at <= now(), claim by updating next_run_at, then insert a job for each."""
    rows = await PostgresDB.fetch(
        """SELECT s.id, s.name, s.cron_expression, s.template_id, s.payload
           FROM public.schedulers s
           INNER JOIN public.job_templates t ON s.template_id = t.id AND COALESCE(t.is_active, true) = true
           WHERE s.is_enabled = true AND s.next_run_at IS NOT NULL AND s.next_run_at <= now()
           FOR UPDATE OF s SKIP LOCKED"""
    )
    for r in rows:
        try:
            job_id = uuid.uuid4()
            await PostgresDB.execute(
                """INSERT INTO public.jobs (id, template_id, payload, schedule_time, status)
                   VALUES ($1, $2, $3, now(), 'pending')""",
                job_id,
                r["template_id"],
                r["payload"] or {},
            )
            next_run = _next_run_from_cron(r["cron_expression"])
            next_run_ts = next_run.isoformat() if next_run else None
            await PostgresDB.execute(
                """UPDATE public.schedulers SET last_run_at = now(), next_run_at = $2, updated_at = now() WHERE id = $1""",
                r["id"],
                next_run,
            )
            logger.info("Scheduler %s triggered job %s, next_run %s", r["name"], job_id, next_run_ts)
        except Exception as e:
            logger.exception("Scheduler %s failed: %s", r.get("name"), e)


async def scheduler_task():
    if os.getenv("ENABLE_SCHEDULER", "true").lower() not in ("true", "1", "yes"):
        logger.info("Scheduler disabled by ENABLE_SCHEDULER")
        return
    interval = float(os.getenv("SCHEDULER_INTERVAL", "5"))
    fetch_limit = int(os.getenv("SCHEDULER_FETCH_LIMIT", "100"))
    qm = get_queue_manager()

    while True:
        try:
            # Cron schedulers: create pending jobs for due schedulers
            await _run_due_schedulers()

            # Select then update: claim pending jobs
            rows = await PostgresDB.fetch(
                """
                WITH claimed AS (
                    SELECT id FROM public.jobs
                    WHERE status = 'pending'
                      AND (schedule_time IS NULL OR schedule_time <= now())
                    ORDER BY schedule_time NULLS FIRST, created_at
                    LIMIT $1
                    FOR UPDATE SKIP LOCKED
                )
                UPDATE public.jobs j
                SET status = 'queued', updated_at = now()
                FROM claimed c WHERE j.id = c.id
                RETURNING j.id, j.template_id, j.payload, j.retry_count
                """,
                fetch_limit,
            )
            for row in rows:
                job = {
                    "id": str(row["id"]),
                    "template_id": str(row["template_id"]) if row.get("template_id") else None,
                    "payload": row.get("payload") or {},
                    "retry_count": row.get("retry_count") or 0,
                }
                if not qm.ready_put_nowait(job, priority=0):
                    # Revert to pending so next cycle picks it up
                    await PostgresDB.execute(
                        "UPDATE public.jobs SET status = 'pending', updated_at = now() WHERE id = $1",
                        row["id"],
                    )

            # Move due delayed jobs into ready queue
            now_ts = time.time()
            for pri, job in qm.pop_due_delayed(now_ts):
                qm.ready_put_nowait(job, priority=pri)

        except Exception as e:
            logger.exception("Scheduler cycle error: %s", e)

        await asyncio.sleep(interval)
