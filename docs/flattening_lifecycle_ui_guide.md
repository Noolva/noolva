# Flattening & Data Life Cycles — User Guide (Admin Console)

This guide covers the two pages that work together to keep old data out of your
hot tables without losing anything:

```
HOT data                 WARM copy                 COLD archive
(my_tasks, comments,  →  (flat_my_tasks,        →  (archived_flat_my_tasks)
 attachments)            denormalized + JSON)
        Flattened Datas page        Data Life Cycles page
```

---

## 1. Flattened Datas (WARM tier)

**What it does:** builds a wide, read-only copy of a table — `flat_<table>` —
and keeps it fresh on a schedule. Nothing here modifies the source table.

### Table policy fields

| Field | Plain English |
| --- | --- |
| Table name | Which table to copy (pick a Data Model, or enable **Db Tables** for any physical table). |
| Destination | `postgres` = build `flat_<table>` in the same database (recommended). `s3` / `iceberg` are not built by the 1.0.6 flattening engine. |
| Refresh strategy | `FULL` = rebuild all rows each run. `INCREMENTAL` = only rows changed since the last run (uses `last_updated`). |
| Interval (minutes) | How stale the flat copy may get (60 = refresh at least hourly). |
| Batch size | Rows processed per chunk (default 1000). |
| Active | Off = stop refreshing (flat copy stays as-is). |

### Plain-English preview

The green box at the bottom of the drawer repeats the policy as a sentence,
e.g.:

> Every 60 minutes (INCREMENTAL), rebuild flat_my_tasks from my_tasks: copy all
> columns, add denormalized related fields (e.g. business_id__name), and embed
> child rows as JSON arrays (e.g. task_comments_items).

### Table columns to watch

- **Flat rows** — how many rows the flat copy currently has (`not built yet`
  means the refresh job has not run since the policy was created).
- **Last refresh** — timestamp of the last successful refresh.

### Run now / Regenerate (Actions column)

Every policy row has an execute-now button — no waiting for the scheduler:

- **Run now** (postgres destination) — rebuilds the flat copy immediately
  (same engine the background job uses). Shows rows upserted when done.
- **Regenerate** (s3 destination) — force re-exports the flattened JSON to
  S3 and bumps the watermark, so offline clients (mac/iOS/Android/web
  menus, offline datasets) re-download on their next launch. Use this after
  editing `instance_menus`/`instance_menu_client_config` so sidebars pick
  up new entries.

### Relation policies (the "N policies" button)

Two kinds:

- **m2o → denormalize** — pull a few display fields from a related table into
  the flat row as extra TEXT columns, named `<relation>__<field>`
  (e.g. `priority` → `priority__name` = "critical").
- **o2m → json** — embed all child rows as a JSON array column named
  `<child_table>_items` (e.g. `task_comments_items` = every comment + activity
  entry for that task, each with its `activity_type`; `task_attachments_items`
  = every attachment). This is what preserves history after hot rows are purged.

For **my_tasks** the standard set is already defined:
`business_id, person_id, priority, project_id, sprint_id, task_category_id`
(denormalize) + `task_comments.task`, `task_attachments.task` (json).

---

## 2. Data Life Cycles (COLD tier)

**What it does:** moves old rows from a flat (WARM) table into an `archived_*`
table, and — only if you explicitly enable it — deletes the hot copies after a
grace period.

### The two modes

| Mode | What happens |
| --- | --- |
| **Archive only** (default, safe) | Copies eligible rows to `archived_<source>`. Hot rows stay. Nothing is deleted. |
| **Archive + auto-purge (danger zone)** | Same archive step, then after the grace period DELETES those rows from the flat table, the hot root table (e.g. `my_tasks`) and its child tables (comments, attachments). Enabling this mode on a policy shows a red warning and a confirmation step before saving. |

### Retention presets

- **1 year / 2 years / 3 years** — writes the filter automatically, e.g.
  `completed_at < now() - interval '1 year'`.
- **Custom SQL condition** — write your own safe fragment (no semicolons),
  e.g. `status = 'completed' AND completed_at < now() - interval '6 months'`.

"Time column" is the column that decides age — use `completed_at` for finished
tasks, `idate` as a fallback.

### Sync strategy & batch size (how work is split)

- **INCREMENTAL (recommended at scale)** — each run only considers rows newer
  than the last run's watermark (`last_processed_value` on the time column).
  Millions of rows stay cheap because the scan is bounded.
- **Late-row safety window** — with INCREMENTAL, rows whose timestamp arrives
  late (or was edited) could be skipped forever by a strict watermark. The
  window re-checks rows newer than `(watermark − window)`. Overlap is safe:
  already-archived rows are skipped by PK dedupe. **7 days** is the
  recommended default.
- **FULL** — re-check every eligible row each run. Still never re-copies
  archived rows (PK dedupe); useful for small tables or after changing the
  filter.
- **Batch size (rows per run)** — the archive job copies at most this many
  rows per operation, advances the watermark, and continues on the next
  scheduler tick. Each run also loops up to **10 batches** internally, so a
  large backlog catches up quickly instead of waiting one tick per batch.
- **Purge and INCREMENTAL** — purge does **not** use the archive watermark;
  it deletes only rows verified present in the archive (flat ∩ archive join).
  INCREMENTAL + auto-purge is therefore safe.

### Plain-English preview

The green box in the drawer always shows what the policy will do, e.g.:

> Every 1 day, copy rows from flat_my_tasks where completed_at is older than
> 1 year into archived_flat_my_tasks. Then, 7 days after the last archive,
> DELETE those rows from the hot tables: flat_my_tasks, my_tasks and its child
> tables (e.g. comments, attachments).

### Pipeline status strip

Expand any policy row in the table to see:

- **Last archive run** — when the archive job last copied rows.
- **Rows archived (total)** — cumulative rows copied (from the batch ledger).
- **Last purge run** — when hot rows were last deleted (only in purge mode).
- **Rows purged (total)** — cumulative hot rows deleted.

If "Last archive run" is always empty: check the **Process Lifecycle Syncs**
scheduler is enabled (Schedulers page) and the policy interval has elapsed.

### Purge rules (safety)

A purge batch only deletes rows that:

1. exist in **both** the flat table and the archive table (same PK), and
2. still match the policy condition, and
3. were archived at least `purge_after_interval_minutes` ago (grace period),
   and
4. the policy has `purge_enabled = true` and a **hot root table** set.

Child tables are found automatically from the flattening relation policies
(`task_comments`, `task_attachments` for my_tasks) — no Postgres FK required.

---

## 3. End-to-end recipe: keep My Tasks fast, archive finished work

1. **Flattened Datas** → Add table policy: `my_tasks`, destination postgres,
   INCREMENTAL, 60 min. (Already done in 1.0.6 migration.)
2. Wait for the refresh job → **Flat rows** shows 132+ and the Completed page
   can read `flat_my_tasks`.
3. **Data Life Cycles** → Add policy:
   - Mode: Archive only first (safe)
   - Source: `flat_my_tasks`
   - Time column: `completed_at`, Retention: 1 year
   - Destination: postgres_archive (table auto = `archived_flat_my_tasks`)
   - Interval: 1440 (daily)
4. Confirm the preview sentence reads correctly, save, and watch the pipeline
   strip fill in after the next scheduler run.
5. When comfortable, Edit the policy → Mode: **Archive + auto-purge** → set hot
   root = `my_tasks`, grace = 7 days → Save (confirmation required).

---

## 4. Troubleshooting

| Symptom | Check |
| --- | --- |
| Flat rows = "not built yet" | Jobs page: a `refresh_flattening_table` job ran? Scheduler **Process Flattenings** enabled? |
| Flat rows < source rows | INCREMENTAL only picks changed rows; force a FULL refresh by editing the policy strategy to FULL once. |
| Archive never runs | Scheduler **Process Lifecycle Syncs**; policy `sync_interval_minutes` elapsed; source table is a valid flat target. |
| Purge never runs | Scheduler **Process Lifecycle Purges**; `purge_enabled`; `last_archive_completed_at` is set; grace period elapsed. |
| Purge job error "Unknown handler" | Server is running pre-1.0.6 API — upload `registry.py` + `purge_lifecycle_after_archive.py` and restart. |
| s3 policy does nothing | Expected in 1.0.6 — use postgres_archive. |

All SQL changes for these pages ship in `reelase_1.0.6_db_updates/`
(run `00_run_all_release_1_0_6.sql` on the target DB).
