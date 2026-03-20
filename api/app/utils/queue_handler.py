"""
DEPRECATED: Use the job scheduler (POST /jobs, GET /jobs/{id}) and background workers instead.
See docs/job-scheduler-implementation-plan.md. This in-memory queue is not persisted.
"""
import queue
import threading
import uuid
import time
from concurrent.futures import ThreadPoolExecutor
from job_workers import handle_job

# Config
MAX_WORKERS = 5
MAX_RETRIES = 3

# Shared job queue and job registry
job_queue = queue.Queue()
executor = ThreadPoolExecutor(max_workers=MAX_WORKERS)
job_registry = {}  # job_id: {status, result, retries, logs, etc.}

def queue_listener():
    while True:
        job = job_queue.get()
        if job is None:
            break
        executor.submit(process_job, job)

def process_job(job):
    job_id = job["id"]
    job_registry[job_id]["status"] = "running"
    job_registry[job_id]["start_time"] = time.time()

    try:
        result = handle_job(job["type"], job["payload"])
        job_registry[job_id]["status"] = "success"
        job_registry[job_id]["result"] = result
    except Exception as e:
        job_registry[job_id]["status"] = "failed"
        job_registry[job_id]["error"] = str(e)
        job_registry[job_id]["retries"] += 1

        if job_registry[job_id]["retries"] <= MAX_RETRIES:
            job_queue.put(job)  # Retry
        else:
            job_registry[job_id]["logs"].append(f"Failed after {MAX_RETRIES} retries")

# Start the listener thread
listener_thread = threading.Thread(target=queue_listener, daemon=True)
listener_thread.start()

def enqueue_job(job_type, payload):
    job_id = str(uuid.uuid4())
    job = {"id": job_id, "type": job_type, "payload": payload}
    job_registry[job_id] = {
        "status": "queued",
        "result": None,
        "retries": 0,
        "logs": [],
        "submitted_at": time.time(),
    }
    job_queue.put(job)
    return job_id

def get_job_status(job_id):
    return job_registry.get(job_id, {"error": "Job not found"})
