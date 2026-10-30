# 02 — Lifecycle archive engine (sync_lifecycle_table)

Date: 2026-10-11
Type: noolva-api change (requires server upload + restart)

## What changed
`sync_lifecycle_table` is no longer a stub:
- `postgres_archive`: resolves physical source (policy `archive_source_table`,
  else the policy's table — for the my_tasks design this is `flat_my_tasks`),
  ensures `archived_*` table exists (`LIKE source INCLUDING DEFAULTS`), copies
  one eligible batch via `archive_batch_postgres` (time/filter eligibility,
  skips PKs already in archive), writes a `data_lifecycle_batch_ledger` row
  (`operation='archive'`), updates `last_synced_at`, `last_processed_value`,
  and `last_archive_completed_at` (only when rows were copied).
- `iceberg`: exports one eligible batch from the archived_* source to Parquet
  (`export_archived_batch_to_parquet`, optional PyIceberg append), ledger
  `operation='iceberg_export'` with `extra.pk_values` + `file_path` (needed by
  tier-2 purge), same timestamp updates.
- `s3`: not implemented in the 1.0.6 engine — stamps `last_synced_at` and logs a
  warning (no data moved).
- `movement_type='move'` intent is honored by the purge job, NOT by archive:
  archive always copies; deletion happens only in `purge_lifecycle_after_archive`
  after rows are verified present in the archive.

## Files touched (upload to server)
- `api/app/jobs/handlers/sync_lifecycle_table.py`

## DB changes
- `reelase_1.0.6_db_updates/02_lifecycle_sync_purge_schedulers.sql`
  (schedulers `Process Lifecycle Syncs` — dispatches due policies every 5 min)
- `reelase_1.0.6_db_updates/03_data_lifecycle_my_tasks_completed.sql`
  (lifecycle policy: completed my_tasks > 1y → archived_flat_my_tasks)

## Deploy
1. Upload the file above to the server path.
2. Restart noolva-api. Restart time: `____ (fill after deploy) ____`
3. Confirm scheduler `Process Lifecycle Syncs` is enabled (schedulers table).

## Verify
- Create/enable a lifecycle policy → within 5 min a `sync_lifecycle_table` job
  runs; `data_lifecycle_batch_ledger` gets an `archive` row;
  `archived_flat_my_tasks` gains rows; `last_archive_completed_at` set.
- Re-run: no duplicate rows in archive (PK dedupe).
