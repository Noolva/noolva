# 01 — Flattening engine (real materialization)

Date: 2026-10-11
Type: noolva-api change (requires server upload + restart)

## What changed
`refresh_flattening_table` is no longer a stub. For each active postgres
flattening policy it now:
1. Creates the flat table if missing (`LIKE source INCLUDING DEFAULTS`) and adds
   relation columns (idempotent).
2. m2o `denormalize` relations → TEXT columns named `{relation}__{field}`
   (e.g. `business_id__name`, `project_id__project_name`). Target table resolved
   via real Postgres FK, else via `data_model_fields` relation config
   (`target_model` / `target_field`) — my_tasks has logical FKs only.
   Joins use `::text = ::text` to tolerate varchar↔int (e.g. `priority` → `priority_id`).
3. o2m `json` relations → JSONB array column named `{child_table}_items`
   containing full child rows (`to_jsonb(child)`), ordered by `idate`, pk.
   For my_tasks: `task_comments_items` (followup messages + activity logs —
   `activity_type='comment'` = followup, other values = activity entries) and
   `task_attachments_items` (attachments).
4. Materializes rows in `batch_size` chunks: DELETE touched pks + INSERT joined
   rows. `FULL` also deletes stale flat rows; `INCREMENTAL` tracks
   `last_processed_value` on source `last_updated`.
5. Ensures the flat Data Model (`flattened_my_tasks`) + fields and GET-only
   read endpoints on the flat model (`/data-models/auto/flattened_my_tasks/records`).
6. Updates `last_refreshed` / `last_processed_value`.

s3/iceberg flattening destinations are skipped by this engine (client-offline /
lifecycle own those paths).

## Files touched (upload to server)
- `api/app/jobs/handlers/refresh_flattening_table.py`
- `api/app/utils/flattening_materializer.py`

## DB changes
See `reelase_1.0.6_db_updates/01_flattening_my_tasks_engine.sql`
(policy + m2o/o2m relations for my_tasks; job-template description).

## Deploy
1. Upload the 2 files above to the server paths.
2. Restart noolva-api. Restart time: `____ (fill after deploy) ____`

## Verify
- Jobs: a `refresh_flattening_table` job completes with
  `engine=postgres_v1`, `rows_upserted=132`.
- `SELECT count(*) FROM flat_my_tasks;` matches `my_tasks` hot rows.
- `flat_my_tasks.task_comments_items` / `task_attachments_items` are non-null arrays.
- `GET /data-models/auto/flattened_my_tasks/records` returns rows.
- Dev DB already has the flat table + model + endpoints hand-seeded (model_id 69).
