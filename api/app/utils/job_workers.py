"""
DEPRECATED: Use app.jobs.handlers registry and POST /jobs API. See docs/job-scheduler-implementation-plan.md.
"""
def handle_job(job):
    job_type = job["type"]
    payload = job["payload"]

    if job_type == "email":
        send_email(payload)
    elif job_type == "notify":
        send_notification(payload)
    elif job_type == "s3_upload":
        upload_to_s3(payload)
    elif job_type == "ai_request":
        process_ai(payload)
    elif job_type == "recreate_tables":
        recreate_tables(payload)
    else:
        print(f"Unknown job: {job_type}")

def send_email(payload):
    print("📧 Sending email:", payload)

def send_notification(payload):
    print("🔔 Notifying:", payload)

def upload_to_s3(payload):
    print("🗃 Uploading to S3:", payload)

def process_ai(payload):
    print("🤖 Processing AI Request:", payload)

def recreate_tables(payload):
    print("🛠 Recreating tables:", payload)

""" from queue_handler import enqueue_job, get_job_status

app = FastAPI()

@app.post("/upload")
async def upload(data: dict):
    job_id = enqueue_job("s3_upload", data)
    return {"job_id": job_id}

@app.get("/job-status/{job_id}")
async def status(job_id: str):
    return get_job_status(job_id) """