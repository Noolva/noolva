# 06 — pkmanager Completed Tasks: read-only archive view (flattened model)

Date: 2026-10-11
Type: pkmanager react-admin change (2 files) + 1 DB migration

## What changed (pkmanager)
- `react-admin/src/pages/tasks/CompletedTasksPage.jsx` passes
  `tasksModel="flattened_my_tasks"`, `fallbackTasksModel="my_tasks"`,
  `readOnly` — the list is served from the flattened archive model.
- `react-admin/src/pages/tasks/TasksPageCore.jsx`:
  - New `readOnly` prop (archive mode). When set:
    - No write/update operations anywhere: New Task, Edit, Complete/Cancel,
      priority edit, external-id edit, comment add, attachment
      upload/edit/delete, dependency add/edit/delete, work-log add/edit,
      alarm create/edit/acknowledge — all hidden (My Tasks page unchanged,
      full read-write).
    - Zero hot-table child calls, strictly: comments, attachments,
      dependencies and work logs are read ONLY from the flat row's inline
      JSON (`task_comments_items`, `task_attachments_items`,
      `task_person_dependencies_items`, `work_logs_items`) — when a field is
      missing the section renders empty; the page never falls back to
      task_comments/task_attachments/task_person_dependencies/work_logs
      API requests. Display names come from flattened denormalized columns
      (`business_id__name`, `priority__name`, `project_id__project_name`,
      `task_category_id__name`, `person_id__name`).
    - Only 2 API calls on load: the flat records list + `persons`
      (small dimension table, needed for assignee/dependency person names —
      embedded dependency rows carry ids only).
    - File preview, download, copy URL/markdown remain available (CDN/signed
      URLs — not hot-table reads).
    - Sorted newest-completed first; count line shows "· archive view
      (refreshed periodically)".
    - No live-model fallback in readOnly: if `flattened_my_tasks` is not
      reachable the page shows "Completed tasks archive is unavailable"
      (strict archive — live task rows are never shown here).
  - Last-comment column reads embedded `task_comments_items` (removes a
    500-request N+1; never fetches when embedded data is absent).

## DB changes
`reelase_1.0.6_db_updates/06_flattening_archive_children.sql` (in run-all):
- Adds o2m JSON relations `task_person_dependencies.task_id` and
  `work_logs.task_id` to `flattening_relation_policy` (flat rows now embed
  `task_person_dependencies_items`, `work_logs_items`).
- Forces one full rebuild (watermark + last_refreshed nulled).
- No noolva-api code change (engine already generic).

## Deploy
1. **Redeploy the noolva API first** — the running karandev build predates
   the whole 1.0.6 tree (uncommitted working copy): websocket route,
   `flattened_my_tasks` records endpoint with embedded children, and the
   new `instance_menus` snapshot export all live only in the new build.
2. After the API is up, regenerate the `instance_menus` S3 snapshot so
   mac/other clients re-sync the sidebar (Completed Tasks row 11 is in the
   DB but missing from the stale S3 object; watermark unchanged means
   clients keep their cache). Easiest: **Flattened Datas → instance_menus
   row → Regenerate** (new execute-now button; force re-exports the JSON and
   bumps the watermark). Equivalent curl:
   ```
   curl -X POST "https://<api-host>/dev-console/flattening-policies/table-policies/15/execute-now" \
        -H "Authorization: Bearer <admin-jwt>"
   ```
3. Rebuild pkmanager react-admin bundle and deploy.
4. Rebuild the pkmanager mac app (it now includes a static fallback entry
   for Completed Tasks + `tasks` icon mapping).
5. Run `06_flattening_archive_children.sql` on the target DB (or full
   run-all); wait for the next flatten scheduler tick (≤5 min) for the
   full rebuild.

## Verify
- /completed-tasks: read-only — no New/Edit/Complete/Cancel/upload/delete
  buttons; comment/attachment/dependency/work-log data visible; attachment
  Download + preview work.
- Network tab on load: only `/data-models/auto/flattened_my_tasks/records`
  (+ persons list) — no task_comments/task_attachments/
  task_person_dependencies/work_logs requests.
- /tasks (My Tasks): unchanged, full read-write.
- flat_my_tasks: `task_person_dependencies_items` and `work_logs_items`
  populated (dev check: 5 / 39 rows with data).
