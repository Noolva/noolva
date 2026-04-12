# Noolva API — Offline flattened S3 snapshots in the browser (PKManager)

Use this form so Noolva can confirm behavior for **any** read dataset exposed as **`flattened_s3`** in the offline manifest—not only **`instance_menus`** (menus are one example). PKManager’s **react-admin** (and similar SPAs) may **`fetch`** snapshot bytes for **multiple** `dataset_key` values configured under **Client instances → offline data**.

**Filled for distribution:** technical answers reflect Noolva API behavior as of repository state when this file was updated. **Operator** completes instance-specific rows (§3, §6 production origin, §10).

---

## 0. Two kinds of offline “read” data (scope of this form)

| Kind | Typical manifest hint | Browser fetch pattern | This form |
|------|------------------------|----------------------|-----------|
| **WARM** — flattened S3 JSON | `source_kind = flattened_s3`, `s3_snapshot.watermark` | `GET snapshot-url?dataset_key=…` then `GET` blob URL (S3 presigned, `public_url`, CloudFront, or future API proxy) | **Yes — main focus** |
| **HOT** — Auto CRUD / flattened API GET | `datasets[].read.get_routes`, etc. | Authenticated **`GET`** to your API routes (not S3 snapshot-url) | **Out of scope** for S3/CORS; same **auth** and **company/instance** rules apply |

This document is about **flattened S3** snapshots so browser clients can load JSON **without** broken CORS or missing **`s3_key`**.

---

## 1. Why the browser may still call `*.s3.amazonaws.com`

For **each** `flattened_s3` dataset, our SPA may:

1. **CloudFront / CDN first (required for public WARM objects)** — use **`public_url`** from **`GET …/offline/snapshot-url`** when non-null (Noolva builds this from the default S3 integration **`cdn_url`**, e.g. CloudFront, plus the full **`s3_key`**). Alternatively, with a reliable **`s3_key`** from **manifest** or **snapshot-url**, PKManager may compose **`{cdn_url}/{s3_key}`** if its env matches the integration (e.g. **`VITE_CDN_URL`** aligned with that **`cdn_url`**).
2. **Fallback** — **`presigned_url`** from **`snapshot-url`** when the export is **private** (`is_public_on_s3 = false`), or when a CDN `GET` fails and the client retries via presigned URL if applicable.

If **`s3_key` is missing**, or the **CDN** returns non-200 / CORS fails, the client **falls back** to the **presigned S3** URL. DevTools will then show **`https://<bucket>.s3.amazonaws.com/...?…`** for **`instance_menus.json`**, **`settings.json`**, **job_templates**, or **any other** flattened export—not only menus.

**Noolva to confirm:** Is fallback to presigned S3 always expected when CDN is unavailable? Noolva: **Yes / No** — **Yes** for **private** exports (only presigned is returned) and as a **runtime fallback** when **`public_url`/CDN** errors; **public** exports should use **CloudFront/CDN** via **`public_url`** / **`cdn_url` + `s3_key`**.

---

## 2. Endpoints (all `flattened_s3` datasets)

| Call | Purpose |
|------|---------|
| `GET /api/instances/{instance_ref}/offline/manifest` | Lists **`datasets[]`**. For each **`flattened_s3`** row: read **`dataset_key`**, **`s3_snapshot.watermark`**, **`s3_snapshot.s3_key`** (full key, aligned with snapshot-url; see §4c). |
| `GET /api/instances/{instance_ref}/offline/snapshot-url?dataset_key=<dataset_key>` | Returns **`public_url`**, **`presigned_url`**, **`meta`** (incl. **`s3_key`**, watermarks per [`client_offline_sync.md`](./docs/client_offline_sync.md)). |

Auth: **`Authorization: Bearer <JWT>`** or **`Bearer <PAT>`** (see [`client_offline_sync.md`](./docs/client_offline_sync.md)).

---

## 3. Datasets to support for PKManager (Noolva: fill table)

Paste the **manifest `datasets[]` slice** for instance **`_________________________________`** (id/uuid), or copy from Noolva console **Client instances → Preview manifest**:

**Noolva: list every `dataset_key` with `source_kind = flattened_s3` that PKManager web should cache:**

| `dataset_key` | Example `s3_key` (or object path) | Notes |
|---------------|-----------------------------------|--------|
| *(operator: from Preview manifest)* | `{bucket_prefix}public/flattened/<table_name>.json` or `…/private/…` | Full key includes integration **`bucket_prefix`** when set |
| | | |

Add rows until complete.

---

## 4. Snapshot-url contract (must be **identical** for every `dataset_key`)

### 4a. Sample response (one real row, redacted)

**Noolva:** paste JSON from `GET …/snapshot-url?dataset_key=________________` :

**Shape (redacted)** — public export:

```json
{
  "dataset_key": "<dataset_key>",
  "public_url": "https://<cloudfront-domain>/<full_s3_key>",
  "presigned_url": null,
  "meta": {
    "s3_key": "<full_s3_key>",
    "is_public_on_s3": true,
    "watermark": {
      "last_refreshed": "<iso8601 or null>",
      "last_processed_value": "<iso8601 or null>"
    }
  }
}
```

**Shape (redacted)** — private export:

```json
{
  "dataset_key": "<dataset_key>",
  "public_url": null,
  "presigned_url": "https://<bucket>.s3.<region>.amazonaws.com/<full_s3_key>?<signature-params>",
  "meta": {
    "s3_key": "<full_s3_key>",
    "is_public_on_s3": false,
    "watermark": { "last_refreshed": "...", "last_processed_value": "..." }
  }
}
```

### 4b. Field names (confirm for **all** datasets)

| Field | Present? (Y/N) | **Exact** JSON key | Same for every `dataset_key`? |
|--------|----------------|-------------------|--------------------------------|
| Presigned S3 URL | **Y** when private | `presigned_url` | **Y** |
| Public / CDN URL | **Y** when public | `public_url` | **Y** |
| Object key | **Y** | `meta.s3_key` | **Y** — **required for CloudFront-first clients** |
| Other `meta` | **Y** | `meta.is_public_on_s3`, `meta.watermark` | **Y** |

### 4c. Manifest `s3_key`

Does **`GET …/offline/manifest`** include **`s3_key`** under **`datasets[].s3_snapshot`** for **every** `flattened_s3` dataset?

- [x] **Yes** — key name: **`s3_key`** (under **`datasets[].s3_snapshot`**)  
- [ ] No — if `snapshot-url` omits `meta.s3_key`, clients cannot build a CDN URL from manifest.

**Note:** Manifest **`s3_key`** matches **`snapshot-url` `meta.s3_key`** for the **same** authenticated caller (full key including **`bucket_prefix`**, from **`_get_default_s3_service`** using the principal’s `company_id`, same as snapshot-url).

---

## 5. CloudFront / `public_url`

**Noolva:** Should browser clients treat **`public_url`** as the preferred **CloudFront** (or CDN) URL when the object is readable there?

- [x] **Yes** — for **public** S3 exports, **`public_url`** is the canonical CDN URL when **`cdn_url`** on the default AWS S3 integration is set (e.g. CloudFront). **Client instances should use this URL (or equivalent `cdn_url` + `s3_key`) for browser reads.**
- [ ] No — only `presigned_url` for private exports  

**Example pattern(s) for PKManager bucket/prefix:**  
`https://<CloudFront domain>/<full_s3_key>` where **`full_s3_key`** matches **`meta.s3_key`** / manifest **`s3_snapshot.s3_key`**, and **`CloudFront`** maps to the same bucket (and prefix) as the Noolva default S3 integration.

---

## 6. CORS (applies to **every** snapshot file the SPA may download)

**Noolva / DevOps:** For origins that will run PKManager react-admin:

| SPA origin | S3 bucket `GET` + CORS | CloudFront `GET` + CORS |
|------------|------------------------|-------------------------|
| e.g. `http://localhost:3001` | **Operator:** OK / Not OK | **Operator:** OK / Not OK |
| Production: `___________` | **Operator:** OK / Not OK | **Operator:** OK / Not OK |

**If presigned S3 remains the fallback, must the bucket allow browser `GET` from these origins?** **Yes** — if the SPA may follow **`presigned_url`** to S3, the bucket (origin) CORS must allow the PKManager origins, or use a CDN layer that returns appropriate **CORS** headers for **`GET`**.

---

## 7. Optional: same-origin snapshot body (any `dataset_key`)

To avoid **all** browser traffic to S3/CloudFront for WARM JSON:

**Noolva:** Is there (or will there be) an authenticated route such as  
`GET /api/instances/{instance_ref}/offline/snapshot-body?dataset_key=…`  
that **streams** the same bytes as the object behind `snapshot-url`?

- [ ] Exists: **`___________`**  
- [ ] Planned: ETA _________  
- [x] **Not planned** (as of last update; **use `snapshot-url` + `public_url` / `presigned_url`**).

If yes: same **`meta` / content-type** as raw S3 object? **N/A**

---

## 8. Watermark / flattening SLA (all `flattened_s3` datasets)

After upstream data changes that feed a flattening policy:

1. Typical time until a **new object** is written to S3: **deployment-specific** — driven by flattening job schedule and **`refresh_interval_minutes`** (see [`flattening_and_data_lifecycle.md`](./docs/flattening_and_data_lifecycle.md)).  
2. Typical time until **`manifest.datasets[].s3_snapshot.watermark`** updates: **same as (1)** (watermarks reflect policy row after successful export).  
3. Are intervals **policy-specific** (per `dataset_key`)? **Yes** — each flattening policy has its own refresh cadence.

---

## 9. Security / runbooks

- Typical **`presigned_url` lifetime`: **3600 seconds (1 hour)** — Noolva API default when generating presigned GET URLs for private snapshots.  
- Client should refresh snapshot when blob `GET` returns **403** (expired): **Yes** — call **`snapshot-url`** again and retry.  
- Any rate limits on **`snapshot-url`** or blob `GET`: **No Noolva API–specific limit** on these routes; respect gateway / infra limits.

---

## 10. Contact

- Environment / API base URL: **`_________________________________`**  
- Filled by (name, date): **`_________________________________`**  

---

## Related docs in this repo

- Offline sync: [`client_offline_sync.md`](./docs/client_offline_sync.md)  
- Instance menus (example consumer): [`client_instance_menus.md`](./docs/client_instance_menus.md)  
- **Implementation note:** Noolva API aligns **manifest `s3_snapshot.s3_key`** with **`snapshot-url` `meta.s3_key`** for CloudFront/CDN clients. External apps (e.g. PKManager react-admin) should apply the **same fetch pattern** for **every** `flattened_s3` **`dataset_key`** they sync—not only **`instance_menus`**.
