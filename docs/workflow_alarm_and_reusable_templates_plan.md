# Alarm Workflow and Reusable Job Templates — Plan (Confirmed)

This plan is aligned with your **existing** job templates. Below: what is **re-used** as-is, what needs **code/handler** work, and what is **newly inserted** (templates + handlers).

---

## 1. Existing templates (re-used, no new INSERT)

These 8 templates already exist in your DB. **No new template rows** for them.

| Template name                 | template_id (example)     | handler_function_name   | Use in this plan |
|------------------------------|---------------------------|--------------------------|------------------|
| auto_crud_delete_record      | f8a30f59-...              | run_auto_crud            | Re-use as-is     |
| **auto_crud_get_records**    | 703d37d4-...              | run_auto_crud            | **Re-use**; handler must support get/list |
| auto_crud_post_records       | e7886948-...              | run_auto_crud            | Re-use as-is     |
| auto_crud_put_record         | 69291d66-...              | run_auto_crud            | Re-use as-is     |
| custom_query_endpoint        | 4d5f224a-...              | run_custom_query_endpoint| Re-use as-is     |
| generate_report              | 2fc12db0-...              | generate_report          | Re-use as-is     |
| notification_push            | 84d252b9-...              | notification_push        | Re-use as-is     |
| send_email                   | 65e43f88-...              | send_email               | Re-use as-is     |

- **Workflow step** “task” is the **template name**. The worker calls `get_handler("auto_crud_get_records")` for a step with `"task": "auto_crud_get_records"`. So we need a handler **registered under the name** `"auto_crud_get_records"` for that step to run (in addition to `run_auto_crud` used when the template is run as a single task).

---

## 2. Handler work (no new templates)

### 2.1 `run_auto_crud` and get-records support

- Your templates use **handler_function_name: `run_auto_crud`**. Currently the codebase only has `run_auto_crud_internal` and `run_auto_crud_remote` (create/update/delete). There is **no** `run_auto_crud` registered.
- **Add**: A single **run_auto_crud(payload)** that:
  - Reads `operation` from payload: `get_records` | `create` | `update` | `delete`.
  - For `create` / `update` / `delete`: delegates to existing `run_auto_crud_internal` (or remote, e.g. from payload flag).
  - For **get_records**: implements list (model_name, filters, limit, offset), resolves `$system.now` in filters, calls internal list API or `_auto_list_records_impl`, returns `{ "records": [...], "model_name", "limit", "offset" }`.
- **Register**: `register_handler("run_auto_crud", run_auto_crud)`.
- **Register for workflow steps**: `register_handler("auto_crud_get_records", ...)` so that step `"task": "auto_crud_get_records"` works. This can be a thin wrapper that calls `run_auto_crud({ **payload, "operation": "get_records" })`.

So: **re-use** the existing **auto_crud_get_records** template; **add** handler implementation and registration.

### 2.2 Fetching “pending alarms” (e.g. with next_alarm_time <= now): use custom_query

- For the alarm workflow, **use the existing custom_query_endpoint** instead of extending the list API with operator filters.
- Define a **custom_query API endpoint** (in `api_endpoints`, type `custom_query`) whose SQL does e.g. `SELECT * FROM alarms WHERE status = 'pending' AND next_alarm_time <= now()` (with LIMIT/OFFSET added by the API). Row access policies are applied by the custom endpoint.
- Workflow step 1: use task **custom_query_endpoint** with input `{ "endpoint_path": "/job-workflows/pending_alarms", "method": "GET", "limit": 100, "offset": 0 }`, output `"alarm_list"`. The handler resolves path to endpoint_id at runtime (portable). The endpoint returns `{ "records": [...], "columns", "limit", "offset", "row_count" }`, so the next step uses **$alarm_list.body.records**.
- **No change** to list API filter handling is required for this workflow. Optionally, operator filters (`$lte`, `$gte`) could be added to the list API later for other use cases; for “pending alarms” we rely on custom_query.

---

## 3. Newly inserted (templates + handler)

These do **not** exist today. Add them.

### 3.1 Task template: **create_jobs_from_records**

- **Template**: One new row in `job_templates`:
  - name: `create_jobs_from_records`
  - template_category: `task`
  - handler_type: `core_function`
  - handler_function_name: `create_jobs_from_records`
  - description: e.g. “Create one job per record from a list, using a given job template and payload mapping.”
  - Same defaults as your other tasks (timeout 300, parallel, etc.).
- **Handler**: New handler **create_jobs_from_records(payload)**:
  - Input: `records` (array), `job_template_name` (string), `payload_mapping` (e.g. `{ "alarm_id": "$record.alarm_id" }`).
  - For each record, build job payload from `payload_mapping` (resolve `$record.<field>` from current record), INSERT into `public.jobs` (template_id from template name, status `pending`), optionally push to queue.
  - Return: `{ "created": N, "job_ids": [...] }`.
- **Register**: `register_handler("create_jobs_from_records", create_jobs_from_records)`.

### 3.2 Task template: **process_alarm**

- **Template**: One new row in `job_templates`:
  - name: `process_alarm`
  - template_category: `task`
  - handler_type: `core_function`
  - handler_function_name: `process_alarm` (or a stub name)
  - description: e.g. “Process one alarm (e.g. notify, update status).”
- **Handler**: Either a small **process_alarm(payload)** (e.g. payload has `alarm_id`; update alarm, send notification) or a **stub** that returns `{ "ok": true }` until you implement real logic.

### 3.3 Workflow template: **process_pending_alarms**

- **Template**: One new row in `job_templates`:
  - name: `process_pending_alarms`
  - template_category: `workflow`
  - workflow_definition: your JSON (see below)
  - No handler_type / handler_function_name (workflow is driven by steps).
- **workflow_definition** using **custom_query_endpoint** for step 1 (no list API operator support needed):

```json
{
  "version": "1.0",
  "execution": "sequential",
  "steps": [
    {
      "id": "fetch_pending_alarms",
      "task": "custom_query_endpoint",
      "input": {
        "endpoint_path": "/job-workflows/pending_alarms",
        "method": "GET",
        "limit": 100,
        "offset": 0
      },
      "output": "alarm_list"
    },
    {
      "id": "create_alarm_jobs",
      "task": "create_jobs_from_records",
      "depends_on": ["fetch_pending_alarms"],
      "input": {
        "records": "$alarm_list.body.records",
        "job_template_name": "process_alarm",
        "payload_mapping": {
          "alarm_id": "$record.alarm_id"
        }
      }
    }
  ]
}
```

- **Note**: Use **endpoint_path** (e.g. `"/job-workflows/pending_alarms"`) instead of `endpoint_id` so the workflow is portable across environments. The custom_query_endpoint handler resolves path + method to endpoint_id at runtime. The custom endpoint response has `records`; the worker binds it as `$alarm_list.body.records`.

---

## 4. Summary table

| Item | Action | Notes |
|------|--------|--------|
| auto_crud_delete_record | Re-use | No change |
| auto_crud_get_records   | Re-use template; add handler | Implement get_records in run_auto_crud; register run_auto_crud + auto_crud_get_records |
| auto_crud_post_records  | Re-use | Wire run_auto_crud to existing create path |
| auto_crud_put_record    | Re-use | Wire run_auto_crud to existing update path |
| custom_query_endpoint   | Re-use | No change |
| generate_report         | Re-use | No change |
| notification_push       | Re-use | No change |
| send_email              | Re-use | No change |
| **create_jobs_from_records** | **New** | New template row + new handler |
| **process_alarm**       | **New** | New template row + new handler (or stub) |
| **process_pending_alarms** | **New** | New workflow template row only |
| Fetch pending alarms | Re-use custom_query_endpoint | Step 1 uses custom_query_endpoint + saved endpoint; no list API change |
| Worker expression + output binding | Extend | Support `input`/`inputs`, `output` → ctx[name], `$alarm_list.records` |

---

## 5. Implementation order

1. Worker: accept `input`/`inputs`, output-name binding, resolve `$<name>.<path>` (e.g. `$alarm_list.records`). (`$system.now` not needed for custom_query path.)
2. run_auto_crud + get_records: implement and register `run_auto_crud` and `auto_crud_get_records` (for workflows that need simple equality filters via auto_crud).
3. create_jobs_from_records: implement handler and add template row.
4. process_alarm: stub (or real) handler and add template row.
5. process_pending_alarms: add workflow template row (step 1 = custom_query_endpoint, step 2 = create_jobs_from_records).
6. DB: seed/update script only for the **3 new templates**. No INSERT for the 8 existing ones.
7. Docs: update job_templates_guide (expressions, output binding, alarm example using custom_query_endpoint).
8. **Optional**: Define a custom_query API endpoint (e.g. path “/job-workflows/pending_alarms”) with SQL for pending alarms; reference it in the workflow by **endpoint_path** so the workflow is portable.

---

## 6. Custom query endpoint: pending_alarms (included in migration)

The migration file **update_old_db_workflow_alarm_templates.sql** inserts an `api_endpoints` row for the pending_alarms query. Use this SQL (or adjust table/columns to match your schema):

```sql
INSERT INTO public.api_endpoints (path, method, type, related_model_id, reference_model_ids, custom_json)
VALUES (
    '/job-workflows/pending_alarms',
    'GET',
    'custom_query',
    NULL,
    '{}',
    '{"query": "SELECT * FROM public.alarms WHERE status = ''pending'' AND next_alarm_time <= now()"}'::jsonb
)
ON CONFLICT (path, method) DO UPDATE SET type = EXCLUDED.type, custom_json = EXCLUDED.custom_json;
```

- Replace `public.alarms` with your table name if different (e.g. if the data model uses another `table_name`).
- Ensure the table has at least: `status`, `next_alarm_time` (e.g. TIMESTAMPTZ). For push-to-device, a `device_id` column is used in the workflow’s `payload_mapping` so each process_alarm job receives `device_id` and can push to that WebSocket.

---

## 7. Handling the alarm on a device connected via WebSocket

When a device connects at **/ws/{device_id}** (e.g. `/ws/device123`) with a valid token, it is registered as a worker and its connection is stored in a **connection manager** (`app/ws_connections.py`).

**Flow:**

1. **Device connects**: Client opens `wss://.../ws/device123?token=...`. Server accepts, registers the worker, and calls `register_device_connection("device123", websocket)`.
2. **Workflow runs**: Scheduler (or manual POST /jobs) runs the **process_pending_alarms** workflow. Step 1 returns pending alarms (each record can include `device_id` if your table has it). Step 2 creates one **process_alarm** job per alarm with `payload_mapping` e.g. `alarm_id: $record.id`, `device_id: $record.device_id`.
3. **process_alarm job**: Handler runs with payload `{ alarm_id, device_id, ... }`. If `device_id` is present, it calls **push_to_device(device_id, message)** where `message = { "type": "alarm", "alarm_id": ..., "payload": {...} }`.
4. **Push**: `push_to_device` looks up the WebSocket for that `device_id` in the connection manager. If found, it sends the JSON message over the same WebSocket. The device receives e.g. `{"type":"alarm","alarm_id":"...","payload":{...}}` and can show the alarm, play sound, etc.
5. **Disconnect**: When the client closes the connection, the server calls `unregister_device_connection(device_id)` so no further pushes are sent to that socket.

**Device-side:** Subscribe to the WebSocket and handle messages with `type === "alarm"` to show the alarm (and optionally `type === "pong"` for heartbeat). No polling required.

**If the device is offline:** The process_alarm job still completes; `pushed_to_device` will be `false`. You can later extend process_alarm to enqueue a notification or retry push when the device reconnects.

---

## 8. DB migration file

- **File**: `db-structure/update_old_db_workflow_alarm_templates.sql`.
- **Content**:
  - INSERT the **pending_alarms** custom_query `api_endpoints` row (path `/job-workflows/pending_alarms`, query as in section 6).
  - INSERT the **3 new** job_templates: create_jobs_from_records, process_alarm, process_pending_alarms (workflow_definition uses endpoint_path for portability). ON CONFLICT (name) DO UPDATE so existing DBs get them.
- Do **not** re-insert or alter the 8 existing templates.

This keeps your existing templates as the source of truth and limits new inserts to the endpoint and the three templates above.
