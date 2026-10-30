# 05 — High-quality INCREMENTAL archive (watermark + lookback + purge fix)

Date: 2026-10-11
Type: noolva-api change (1 util + 1 handler + 1 route) + 1 DB migration

## What changed (why)
INCREMENTAL previously shared one watermark between archive AND purge, which
made INCREMENTAL + auto-purge delete nothing (purge matched only rows newer
than the watermark, but archived rows are older). Also, a strict watermark
could skip late/out-of-order timestamps forever. Fixed for scale:

1. `api/app/utils/data_lifecycle_sync.py`
   - `build_eligibility_sql(policy, include_incremental_watermark=...)`.
   - New `incremental_lookback_minutes`: INCREMENTAL archive eligibility is
     `time_column > watermark - window` (overlap is safe: archive dedupes by PK).
   - **Purge no longer applies the watermark** (`include_incremental_watermark=False`
     in `purge_tier1_flat_and_root`) — presence in the archive is the safety proof.
2. `api/app/jobs/handlers/sync_lifecycle_table.py`
   - Archive runs process up to **10 batches per job run** (each ≤ sync_batch_size),
     advancing the watermark per batch, so backlogs catch up quickly.
   - Ledger row records total + `batches_this_run`.
3. `api/app/routes/data_lifecycle_policies.py`
   - Exposes `incremental_lookback_minutes` on create/update/list/get.
4. `admin/src/pages/DataLifecyclePolicies.jsx`
   - "Late-row safety window" presets (none/1d/7d/30d) when strategy =
     INCREMENTAL; clearer Sync strategy + Batch size help; preview sentence
     explains incremental vs full; new policies default to INCREMENTAL + 7d.

## DB changes
`reelase_1.0.6_db_updates/05_lifecycle_incremental_quality.sql` (in run-all):
- `ALTER TABLE data_lifecycle_policy ADD COLUMN IF NOT EXISTS incremental_lookback_minutes integer`
- Switches the my_tasks completed policy to INCREMENTAL + 10080 (7-day window).

## Deploy
1. Upload the 4 API files + rebuild admin.
2. Restart noolva-api. Restart time: `____ (fill after deploy) ____`
3. Run `00_run_all_release_1_0_6.sql` (includes 05) on the target DB.

## Verify
- Policy list shows strategy INCREMENTAL + lookback 10080 for the my_tasks policy.
- First archive run: ledger `archive` row with `extra.batches_this_run`,
  `last_processed_value` set to MAX(completed_at) of copied rows.
- Second run with no new eligible rows: 0 rows, watermark unchanged, job OK.
- Purge after grace: deletes flat∩archived rows regardless of watermark.
