# Client instances and offline sync

This document is for teams building **instance apps** (native shells with optional WebView UI, or standalone clients) that talk to the Noolva API. Operators configure each **instance** in the Developer Console (**Client instances** menu).

Canonical database definitions: [`db-structure/noolvandb_schema.sql`](../db-structure/noolvandb_schema.sql) (section **4b**). Apply to existing DBs with [`db-structure/update_old_db_client_instances_offline.sql`](../db-structure/update_old_db_client_instances_offline.sql).

---

## Concepts

| Term | Meaning |
|------|---------|
| **Instance** | One logical client product (e.g. “Contacts” vs “Password vault”). All platforms for that product (iOS, Android, web, Windows, Linux) use the **same** `instance_id` / `instance_uuid` and therefore the **same** sync configuration. |
| **Read dataset** | Something the app may cache locally: HOT Auto CRUD GETs, flattened GET routes, or a **flattened S3 JSON** snapshot. |
| **Offline write allowlist** | Specific **POST/PUT/PATCH/DELETE** `auto_crud` endpoints that may be replayed from a local outbox. **Not** whole modules. **Never** flattened or S3 read models. |
| **`instance_offline_settings`** | Relational settings (not a JSON blob): `enable_offline_data`, `schema_pack_version`, `operator_notes`. |
| **Instance menus** | Per-instance navigation for **client apps** (`instance_menus` + per-stack `instance_menu_client_config`). Not Noolva console `menus`. |

**Navigation for client shells** (routes, icons, native vs webview) is documented in [`client_instance_menus.md`](client_instance_menus.md) (`GET /api/instances/{instance_ref}/menus?client_type=...`).

---

## Authentication

Use **`Authorization: Bearer <JWT>`** or **`Bearer <PAT>`** (same as [`POST /api/upload`](../api/app/routes/upload.py)). PATs should be scoped minimally for production.

---

## Access control

- If `instances.company_id` **is set**, only principals whose `company_id` matches (or super-admins) may call the client offline endpoints.
- If `company_id` **is null**, any authenticated user can read the manifest for that instance — use only when you understand the risk (e.g. internal dev).

---

## Client API (under `/api`)

Base path: **`/api/instances/{instance_ref}/offline/...`**

`instance_ref` may be numeric **`instance_id`** or **`instance_uuid`** string.

### 1) Manifest

`GET /api/instances/{instance_ref}/offline/manifest`

Returns:

- `instance` — id, uuid, name, `company_id`
- `offline` — `enable_offline_data`, `schema_pack_version`
- `datasets[]` — expanded read hints (GET routes, S3 keys + watermarks for `flattened_s3`). For **`flattened_s3`**, `datasets[].s3_snapshot.s3_key` is the **same full object key** as **`GET .../offline/snapshot-url`** `meta.s3_key` for the same caller (default S3 integration for that principal’s `company_id`, including **`bucket_prefix`** when configured), so browser clients can build **CloudFront/CDN URLs** as `{cdn_url}/{s3_key}` in line with **`public_url`**.
- `offline_write_endpoints[]` — allowlisted write routes (`path`, `method`, `endpoint_id`, model info)
- `_warnings` — non-fatal assembly warnings (e.g. missing model)

Requires: instance **active**, user allowed per company rule above.

### 2) Schema pack (SQLite / local DDL hints)

`GET /api/instances/{instance_ref}/offline/schema-pack`

Requires: **`enable_offline_data = true`**.

Returns a JSON document with `schema_pack_version`, `instance_uuid`, and `models[]` (fields + physical table + primary key column) for models referenced by this instance’s datasets and write allowlist.

### 3) Snapshot URL (WARM S3 JSON)

`GET /api/instances/{instance_ref}/offline/snapshot-url?dataset_key=...`

Requires: **`enable_offline_data = true`** and a dataset with `source_kind = flattened_s3` and the given `dataset_key`.

Response:

- `public_url` — when the flattening export is public
- `presigned_url` — when private (short-lived; download server-side or immediately from the client)
- `meta` — `s3_key`, watermarks

---

## Keeping the cache up to date (sync when the source changes)

A local cache is only useful if it **tracks the server**. Instance apps should **not** assume data is fresh forever. Use a **compare-then-fetch** pattern: pull a small **manifest** often; pull **large payloads** (S3 JSON, full table scans) only when server signals say the source changed—or on a safe **fallback interval**.

### What the server already tells you

| Signal | Where | How clients use it |
|--------|--------|---------------------|
| **Schema pack version** | `offline.schema_pack_version` in the manifest | If it differs from the value stored locally, treat as a **schema / shape change**: re-run `GET .../offline/schema-pack`, migrate SQLite (or rebuild), then plan a **full** re-import of affected datasets (HOT + WARM) as your product requires. |
| **WARM S3 watermarks** | `datasets[].s3_snapshot.watermark` for `flattened_s3` (`last_refreshed`, `last_processed_value`) | Noolva updates these when the flattening job writes a **new** JSON export to S3 (see [`docs/flattening_and_data_lifecycle.md`](flattening_and_data_lifecycle.md)). Compare **as strings/ISO timestamps** to what you last applied. If either value changed (or you have no local copy), fetch a new **`snapshot-url`** and re-import. |
| **HOT / flattened GET** | `datasets[].read.get_routes` (list + detail paths) | There is **no** global ETag in the manifest today. Developer Console stores **`incremental_field`** as **`last_updated`** (Noolva’s standard HOT row-change column). For **incremental** list sync, use list APIs that support time/PK filters on that column if your deployment exposes them on Auto CRUD (custom params or future API). If not, use **full refresh** for that dataset on a schedule or when manifest/schema version changes. |

### Recommended local metadata (per device)

Maintain a small table (e.g. `instance_sync_state`) keyed by `dataset_key` (and optionally `instance_uuid`):

- `last_schema_pack_version` — copy of manifest `offline.schema_pack_version` after successful apply
- `last_s3_watermark_json` — JSON string or two columns mirroring `last_refreshed` / `last_processed_value` for `flattened_s3` datasets
- `last_incremental_cursor` — max value seen for `incremental_field` (HOT/flattened API), when doing incremental GETs
- `last_successful_sync_at` — client clock (for UX and backoff)

### Full vs incremental (by dataset kind)

- **`flattened_s3` (incremental at the file level):**  
  - **Cheap check:** `GET manifest` → compare watermarks only.  
  - **Expensive step:** `GET snapshot-url` + download + parse JSON → **replace** the local materialized table or blob **only when watermarks changed** (or first run). This is naturally **“full snapshot per refresh”** but you avoid downloading when the server export is unchanged.

- **`hot_auto_crud_get` / `flattened_api_get`:**  
  - **Full:** paginate through `GET` list routes until done; upsert or replace local rows. Use after schema bumps, first install, or when incremental is not available.  
  - **Incremental:** if `incremental_field` is set and your API supports filtering (e.g. “rows changed since cursor”), request only the delta and advance `last_incremental_cursor`. If the API returns 400/unsupported, **fall back to full** for that dataset.

### Scheduling (when to run sync)

Use **layered** triggers so the cache stays reasonably fresh without hammering the API or S3.

1. **App open / resume (foreground)**  
   - Always safe to call **`GET .../offline/manifest`** (small).  
   - For each active dataset: if watermarks or `schema_pack_version` changed → enqueue the corresponding **snapshot** or **GET** work.

2. **Periodic background**  
   - Align interval with product SLA (e.g. WARM snapshot check every **15–60 minutes**; HOT lists more often for “live” screens).  
   - Use platform schedulers: Android **WorkManager**, iOS **BGAppRefresh** / **URLSession** background, Windows **background tasks**, Linux **timer/systemd user timer**.

3. **After connectivity returns**  
   - Drain **outbox** first (writes), then run **manifest + delta/snapshot** pass so reads are not stale behind the user’s own edits.

4. **Backoff on errors**  
   - On 429/5xx, exponential backoff and cap retries; still allow user-triggered “Pull to refresh”.

5. **Optional push notification**  
   - A data message (“invalidate instance X”) can **prompt an early manifest check**; Noolva does not require this for correctness—**watermarks already detect** S3 export changes once the client polls the manifest.

### Operator alignment

- Ensure **flattening refresh jobs** run on a sensible cadence so S3 JSON and watermarks actually move when HOT data changes ([`docs/flattening_and_data_lifecycle.md`](flattening_and_data_lifecycle.md)).  
- Read datasets use **`last_updated`** as the manifest **`incremental_field`** (Noolva default); incremental list queries still require API support for filters on that column.  
- Bump **`schema_pack_version`** when clients must rebuild local schema—clients should treat that as a **full re-sync** signal for affected models.

### Before SQL migration `12` is applied

The tables and HTTP routes described here exist only after you run [`db-structure/update_old_db_client_instances_offline.sql`](../db-structure/update_old_db_client_instances_offline.sql) (or release **`12_client_instances_offline.sql`**). Until then, clients cannot use these endpoints; the **sync policy above still applies** to any future integration once the API is live.

---

## Online vs offline behavior

| Mode | Behavior |
|------|----------|
| **Online (normal)** | Use existing Auto CRUD and custom endpoints as today. Refresh manifest/schema when appropriate. |
| **Online (after offline)** | Drain the local **outbox** by issuing the **same** HTTP requests (path + method + body) that were allowlisted. Use idempotency keys where your API supports them. |
| **Offline** | **No calls to Noolva.** Read from local SQLite / cached blobs. **Writes**: only queue for later if the user/app **explicitly** opts in **and** the target route is in `offline_write_endpoints`. |

**Default:** when the device has connectivity, prefer **direct API** calls. The outbox is **not** automatic for every save.

---

## Platforms (same contract, different storage)

| Platform | Typical local store | Notes |
|----------|---------------------|--------|
| Android | Room (SQLite) | WorkManager for background sync; WebView talks via bridge to native DB. |
| iOS / macOS | GRDB / SQLite | WKWebView bridge; optional App Group if sharing. |
| Windows | SQLite (WinUI) | Background task for sync. |
| Linux | Qt + SQLite | Store DB under user config dir. |
| WebView-in-native | **No** business IndexedDB | Native owns SQLite; React is UI-only. |
| Standalone browser | IndexedDB (e.g. Dexie) | Same HTTP API when online; different trust/storage model. |

---

## Operator checklist (Developer Console)

1. Create an **instance** (name + optional company).
2. Turn on **Enable offline data** when clients should use schema-pack and snapshot URLs.
3. Add **read datasets** with correct `source_kind` and FKs (model id, flattening policy for S3, etc.).
4. Add **offline write allowlist** rows only for required **Auto CRUD** POST/PUT/PATCH/DELETE routes.
5. Bump **`schema_pack_version`** when clients must rebuild local schema.
6. Expect **`incremental_field`** in the manifest to be **`last_updated`** for standard read datasets; clients should use **full** list refresh when list APIs do not support delta filters on that column.
7. Use **Preview manifest** in the admin UI to verify output before shipping client builds.

---

## Related

- Flattening / WARM tier: [`docs/flattening_and_data_lifecycle.md`](flattening_and_data_lifecycle.md)
- File / presigned access patterns: [`api/app/routes/upload.py`](../api/app/routes/upload.py)

---

## Restart

After deploying API routes or SQL, **restart the API** (and apply SQL migrations on each environment).
