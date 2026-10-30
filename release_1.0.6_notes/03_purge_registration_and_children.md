# 03 — Purge after archive: handler registration + hot child cleanup

Date: 2026-10-11
Type: noolva-api change (requires server upload + restart)

## What changed
1. `purge_lifecycle_after_archive` was implemented but never imported in the
   handler registry → jobs failed with "Unknown handler". It is now registered
   in both `_register_builtins()` and `ensure_handlers_loaded()`.
2. Tier-1 purge (`purge_tier1_flat_and_root`) now deletes HOT child rows
   declared via o2m relation policies (`strategy json|separate`,
   `relation_name = 'child_table.fk_column'`) using the declared FK column —
   no Postgres FK required. For my_tasks this purges `task_comments` and
   `task_attachments` rows for archived+verified task PKs, then flat rows, then
   hot root (`my_tasks`) rows. Existing separate-target/pg-FK cleanup kept as
   fallback. Returns child row counts in the job result and ledger extra.

Purge is gated by: `purge_enabled`, `last_archive_completed_at` set, and
`purge_after_interval_minutes` grace elapsed (rows must exist in archive ∩ flat
with lifecycle eligibility). A `Process Lifecycle Purges` scheduler (5 min)
dispatches due policies.

## Files touched (upload to server)
- `api/app/jobs/handlers/registry.py`
- `api/app/utils/data_lifecycle_sync.py`

## DB changes
- `reelase_1.0.6_db_updates/02_lifecycle_sync_purge_schedulers.sql`
  (schedulers `Process Lifecycle Purges`)

## Deploy
1. Upload the 2 files above to the server paths.
2. Restart noolva-api. Restart time: `____ (fill after deploy) ____`
3. Confirm scheduler `Process Lifecycle Purges` is enabled.

## Verify
- `data_lifecycle_batch_ledger` gains `purge_hot` rows with
  `extra.flat_deleted`, `extra.root_deleted`, `extra.child_deleted_est`.
- For purged PKs: rows gone from `flat_my_tasks`, `my_tasks`,
  `task_comments`, `task_attachments`; rows present in `archived_flat_my_tasks`.
- Jobs for the purge template no longer fail with "Unknown handler".
