# 04 — Admin UI: Data Life Cycles + Flattened Datas (friendly modes, presets, status)

Date: 2026-10-11
Type: noolva-api change (2 route files + 1 class) + admin UI change (2 pages)

## What changed (API — upload + restart)
1. `api/app/routes/data_lifecycle_policies.py`
   - Create/Update models + list/get/create/update now include:
     `archive_source_table`, `purge_enabled`, `purge_after_interval_minutes`,
     `last_archive_completed_at`, `last_purge_completed_at`, `lifecycle_root_table`
     (columns existed in DB since 1.0.5 but were never exposed — the UI could
     not read or write purge settings before).
   - List response adds pipeline status aggregates from the batch ledger:
     `archive_rows_total`, `last_archive_batch_at`, `purge_rows_total`,
     `last_purge_batch_at` (powers the status strip).
2. `api/app/routes/flattening_policies.py`
   - Table-policies list adds `target_row_count` (live count of the flat table;
     null until the table is built) for the "Flat rows" column.
3. `api/app/classes/postgres_db.py`
   - Added `fetchval()` (was already called by `data_lifecycle_sync.py` but
     never defined — would crash on ambiguous-FK fallback).

## What changed (UI — rebuild admin, no server restart needed beyond API)
- `admin/src/pages/DataLifecyclePolicies.jsx` — rewritten:
  - Mode selector: **Archive only** vs **Archive + auto-purge (danger zone)**
    (maps to purge_enabled + lifecycle_root_table; danger mode shows red alert
    and requires Popconfirm on save).
  - Retention presets 1y/2y/3y/Custom (writes the filter_condition + switches
    to time_and_condition), grace-period presets (1/7/14/30 days).
  - Plain-English preview sentence generated from the live form values.
  - Pipeline status strip (expandable row): last archive/purge runs + total
    rows from the ledger; table shows Mode tag, Last archive, Archived rows.
  - Source table is a searchable dropdown of flattening flat targets.
- `admin/src/pages/FlattenedDatas.jsx`
  - Plain-English preview in the table-policy drawer.
  - New columns: **Flat rows** (target_row_count), **Last refresh**.
  - Friendlier help texts for destination + overview alert.

## Deploy
1. Upload the 3 API files + 2 admin page files (or rebuild admin bundle).
2. Restart noolva-api. Restart time: `____ (fill after deploy) ____`
3. No new DB schema required for the UI — purge columns already exist
   (1.0.5 migrations 09/10). Still run
   `reelase_1.0.6_db_updates/00_run_all_release_1_0_6.sql` (includes
   `04_verify_ui_readiness.sql` checks).

## Verify
- Data Life Cycles page: existing policy id 1 shows Mode tag, preview sentence,
  expandable pipeline strip.
- Edit policy id 1 → purge fields load/save correctly.
- Flattened Datas: my_tasks row shows Flat rows = 132 and a Last refresh time
  after the first engine run.
- `docs/flattening_lifecycle_ui_guide.md` is the user-facing guide.
