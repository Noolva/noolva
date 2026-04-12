# Flattening and data lifecycle

This document describes the **WARM-tier flattening** configuration and the **data lifecycle** tiering hooks in Noolva: database tables, Developer Console UIs, read-only API surfaces, and scheduled jobs/workflows.

Canonical schema lives in [`db-structure/noolvandb_schema.sql`](../db-structure/noolvandb_schema.sql). Migrations for existing databases:

- [`db-structure/update_old_db_flattening_policies_and_jobs.sql`](../db-structure/update_old_db_flattening_policies_and_jobs.sql)
- [`db-structure/update_old_db_data_lifecycle_and_jobs.sql`](../db-structure/update_old_db_data_lifecycle_and_jobs.sql)

Release bundle copies (apply in order after prior release SQL): `release_1.0.5_db_updates_pip_migration_infos/03_*.sql`, `04_*.sql`.

---

## Conceptual tiers

| Tier | Role | Implementation in this stack |
|------|------|------------------------------|
| **HOT** | Transactional, high churn | Normal `data_models` / Postgres tables. Writes go here. |
| **WARM** | Read-optimized, denormalized or flattened | `flattening_table_policy` + `flattening_relation_policy`; refresh jobs; **GET-only** Auto CRUD on the flattened model. |
| **COOL** | Older but queryable, often separate table | `data_lifecycle_policy` with `destination_type = postgres_archive` (handler stub today; evolves to archive table sync). |
| **COLD** | Long-retention / analytics | `destination_type = iceberg` (**stub** until Iceberg integration exists). |

Lifecycle policies may also use **`s3`** destination with `movement_type = copy` to export JSON into the default integration bucket under `public/lifecycle_data/…` or `private/lifecycle_data/…` (implementation is phased; sync job updates tracking timestamps even when movement logic is minimal).

---

## Flattening (WARM)

### Tables

- **`flattening_table_policy`** — One row per **flattened physical table** (the read model).
  - `table_name`: must match a row in `public.data_models.table_name` before the policy can be saved (Developer Console enforces this when creating read endpoints).
  - Snapshot mode is **not used**. Policies are always treated as active (`is_snapshot=false`) and require `refresh_strategy` + `refresh_interval_minutes`.
  - `is_active`, `batch_size`, `last_refreshed`, `last_processed_value` support operations and future incremental checkpoints.

- **`flattening_relation_policy`** — How each **relation** on that table is materialized.
  - `relation_type`: `m2o` → strategy must be `denormalize`; `o2m` → `json` or `separate`.
  - `include_fields`: used only for `denormalize` (comma-separated in UI; must be empty for `json` / `separate`).
  - `target_table`: required when `strategy = separate`.
  - **FK:** `table_name` references `flattening_table_policy(table_name)` with `ON DELETE CASCADE`.

The **flattening engine** (SQL generation, denormalize/json/separate execution) is intentionally **out of scope** for the first iteration; the job handler updates `last_refreshed` / `last_processed_value` so scheduling and plumbing can be tested end-to-end.

### Read-only Auto CRUD endpoints

When a table policy is **created or updated**, the API upserts two rows in `api_endpoints`:

- `GET /data-models/auto/{model_name}/records`
- `GET /data-models/auto/{model_name}/records/{record_id}`

with `type = auto_crud`, `related_model_id` set to the flattened model, and `custom_json` including:

- `flattening_read_only: true`
- `flattening_table_policy_id: <id>`

**POST/PUT/DELETE** are **not** registered for this surface. If the same model already had write routes from App Studio, this logic **does not remove** them; the recommended pattern is a **dedicated** read-only flattened model.

On **delete** of a table policy, only endpoints whose `custom_json` matches that policy id are removed.

### Developer Console

- Menu: **Flattened Datas** (`dev_console_flattened_datas`).
- React: [`admin/src/pages/FlattenedDatas.jsx`](../admin/src/pages/FlattenedDatas.jsx).
- API prefix: **`/api/dev-console/flattening-policies`** (`table-policies`, `relation-policies`).

### Jobs and workflow

| Template | Kind | Purpose |
|----------|------|---------|
| `dispatch_flattening_refreshes` | workflow | 1) `custom_query_endpoint` → `/job-workflows/flattening_policies_due` 2) `create_jobs_from_records` → enqueue `refresh_flattening_table` per due row. |
| `refresh_flattening_table` | task | `core_function` — loads policy by `policy_id`; checkpoint logic + `last_refreshed` / `last_processed_value`. |

Attach **`dispatch_flattening_refreshes`** to a **scheduler** at whatever cadence you want; **due logic** uses `last_refreshed` + `refresh_interval_minutes` so rows are not spammed.

**Prerequisite:** the `create_jobs_from_records` job template must exist (same pattern as alarm workflows; see [`db-structure/update_old_db_workflow_alarm_templates.sql`](../db-structure/update_old_db_workflow_alarm_templates.sql)).

---

## Data lifecycle

### Types and table

PostgreSQL enums (see schema / migration `04`):

- `destination_type_enum`: `s3`, `postgres_archive`, `iceberg`
- `movement_type_enum`: `move`, `copy`
- `sync_strategy_enum`: `FULL`, `INCREMENTAL`
- `transfer_mode_enum`: `time_based`, `condition_based`, `time_and_condition`

**`data_lifecycle_policy`** holds **source** `table_name`, **PK** column name, **transfer mode** (`time_column` / `filter_condition` as required by mode), **destination** settings, **movement** and **sync** strategy, **`sync_interval_minutes`**, and **`last_synced_at`** / **`last_processed_value`**.

Validation in [`api/app/utils/data_lifecycle_policy.py`](../api/app/utils/data_lifecycle_policy.py) enforces sensible combinations (e.g. `postgres_archive` requires `destination_table`; `s3` requires `is_public_on_s3` to be set for path choice).

### Developer Console

- Menu: **Data Life Cycles** (`dev_console_data_lifecycle`).
- React: [`admin/src/pages/DataLifecyclePolicies.jsx`](../admin/src/pages/DataLifecyclePolicies.jsx).
- API prefix: **`/api/dev-console/data-lifecycle-policies`**.

### Jobs and workflow

| Template | Kind | Purpose |
|----------|------|---------|
| `dispatch_lifecycle_syncs` | workflow | Due rows from `/job-workflows/lifecycle_policies_due` → one `sync_lifecycle_table` job per policy. |
| `sync_lifecycle_table` | task | Loads policy; **stub** for real S3/archive/Iceberg movement; updates `last_synced_at`; logs skip for `iceberg`. |
| `purge_soft_deleted` | task | Hard-deletes rows where `deleted_at` is older than `retention_days` (default **30**) for a given `table_name` (requires column to exist). |

---

## Soft delete and lists

New **data models** created through the API get a physical **`deleted_at`** column and a **system field** row. **Auto CRUD** list and get-by-id automatically filter **`deleted_at IS NULL`** when the model defines that field, so soft-deleted rows disappear from default reads without breaking older tables that have no column.

The **`purge_soft_deleted`** template is for periodic cleanup of rows that have been soft-deleted longer than the retention window.

---

## Model deletion guards

[`api/app/routes/data_models.py`](../api/app/routes/data_models.py) **delete-check** blocks removal when the model’s physical `table_name` is referenced by:

- `flattening_table_policy` or `flattening_relation_policy`
- `data_lifecycle_policy`

If those tables are not migrated yet, the check fails open with a log warning so existing environments keep working until SQL is applied.

---

## Operations checklist

1. Run DB migrations (`03` then `04`, or canonical files under `db-structure/`).
2. Ensure **`create_jobs_from_records`** (and custom_query endpoints) exist from prior job/workflow setup.
3. **Restart API** and **job workers** (new handlers: `refresh_flattening_table`, `sync_lifecycle_table`, `purge_soft_deleted`).
4. Re-seed or manually add **Developer Console** menus if needed (`noolvandb_feeds.sql` block for `developer_console`).
5. Register schedulers for `dispatch_flattening_refreshes` and/or `dispatch_lifecycle_syncs` as needed.
6. For WARM reads: create the **flattened table as a Data Model**, then add the **flattening table policy** so GET-only routes appear.

---

## Related code (quick index)

| Area | Location |
|------|----------|
| Flattening routes | [`api/app/routes/flattening_policies.py`](../api/app/routes/flattening_policies.py) |
| Flattening helpers | [`api/app/utils/flattening_policy.py`](../api/app/utils/flattening_policy.py) |
| Lifecycle routes | [`api/app/routes/data_lifecycle_policies.py`](../api/app/routes/data_lifecycle_policies.py) |
| Lifecycle helpers | [`api/app/utils/data_lifecycle_policy.py`](../api/app/utils/data_lifecycle_policy.py) |
| Job handlers | [`api/app/jobs/handlers/refresh_flattening_table.py`](../api/app/jobs/handlers/refresh_flattening_table.py), [`sync_lifecycle_table.py`](../api/app/jobs/handlers/sync_lifecycle_table.py), [`purge_soft_deleted.py`](../api/app/jobs/handlers/purge_soft_deleted.py) |
| Router registration | [`api/app/main.py`](../api/app/main.py) |

For general job/workflow step shapes, see [`docs/job_templates_guide.md`](job_templates_guide.md) and the alarm workflow doc in the same folder.

**Client instances / offline sync** (native apps using flattened S3 + HOT Auto CRUD) is documented in [`docs/client_offline_sync.md`](client_offline_sync.md).
