# How to handle global icons at client instances

**Instance apps** (iOS, Android, web, Windows, Linux shells) do **not** receive image bytes inside instance payloads. Menus and other server data typically carry an **`icon_key`** only. You resolve that key to files using the **global icons** catalog, your **CDN**, optional **Noolva API** helpers, or **bundled** assets.

Canonical schema: [`db-structure/noolvandb_schema.sql`](../db-structure/noolvandb_schema.sql) (`public.global_icons`). Server implementation: [`api/app/routes/global_icons.py`](../api/app/routes/global_icons.py). Platform stacks overview: [`platforms-client-instances`](../platforms-client-instances).

---

## Where `icon_key` appears

- **Instance menus**: `GET /api/instances/{instance_ref}/menus?client_type=...` returns `icon_key` per row (see [`docs/client_instance_menus.md`](client_instance_menus.md)). The Noolva API does **not** embed icon URLs in that response.

`icon_key` must match `^[a-z0-9_]+$` (lowercase snake-case style).

---

## File format per platform

| Platform  | Typical file | Notes |
|-----------|----------------|-------|
| `web`     | SVG | Default logical path if `icon_path_web` is empty: `public/global_icons/web/{icon_key}.svg` |
| `android` | Vector drawable XML | Often shipped under `res/drawable` or downloaded |
| `ios`     | SVG | Often used with template / tint (e.g. `currentColor`) |
| `macos`   | SVG | Same family as iOS for many apps |
| `windows` | PNG (e.g. 32×32) | Raster tiles for WinUI |
| `linux`   | SVG | e.g. Qt `QIcon` / `QSvgWidget` |

Operators may set **`icon_path_*`** columns in `public.global_icons` to **override** the default layout. Those values are logical keys under the default bucket (same pattern as other public assets): strip a leading `/`, then prefix with your **CDN base** URL.

---

## Ways client apps can resolve icons

### 1) CDN-first (recommended for production)

After operators run **sync to S3** from the Noolva console (App Studio → Global icons), objects are public at the logical paths stored in `global_icons`.

1. Obtain **`cdn_base_url`** and each row’s **`icon_path_*`** (and/or default `public/global_icons/{platform}/...` convention).
2. Build **`{cdn_base_url}/{logical_path}`** (no duplicate `//` if you concatenate carefully).

The authenticated catalog list (below) returns **`cdn_base_url`** (when S3 is configured for the caller’s company context) and **`icon_path_web_resolved`** / **`public_url_web`** for the web asset. For **non-web** platforms, use the row’s **`icon_path_android`**, **`icon_path_ios`**, etc., with the same CDN base.

**Offline / poor connectivity:** cache files locally keyed by `(icon_key, platform)`, or ship a **bundled** subset that matches the keys your menus use—see [Offline and caching](#offline-and-caching).

### 2) `GET /api/global-icons/list` (metadata + web URL)

- **Path:** `GET /api/global-icons/list`
- **Auth:** `Authorization: Bearer <JWT or PAT>` — same style as [`docs/client_offline_sync.md`](client_offline_sync.md); principal must satisfy the roles required for App Studio global icons routes (see server code).
- **Query:** optional `check_s3=true` (slow: HEAD per icon; default **false**).

**Response** (conceptually): `icons[]` with DB fields plus `icon_path_web_resolved`, optional `public_url_web`, optional `cdn_base_url` at the top level.

Use this to **discover** keys, **custom** `icon_path_*` values, and the **CDN base** once per session or app version, then resolve icons locally without repeated list calls.

### 3) Fallback file from the Noolva API host

If CDN misses or you are in a dev environment without public objects:

- **`GET /api/global-icons/file/{icon_key}?platform=web|android|ios|macos|windows|linux`**
- **Auth:** same as list.
- Returns the **bundled** file from [`api/assets/global_icons/`](../api/assets/global_icons/) on the API host (not from S3).

The Noolva console listing suggests **CDN first**, then this endpoint if the image fails to load—mirror that in your client if you support both.

---

## Operators: publishing assets

1. Icons live in the repo under **`api/assets/global_icons/{platform}/`** and are registered in **`public.global_icons`** (and feeds / migrations as applicable).
2. **`POST /api/global-icons/sync`** uploads logical paths to the **default integration S3 bucket** (public objects). Use **`icon_key`** for one icon or **`sync_all`** with **`cursor_after`** / **`icons_per_batch`** for batched full sync (see request body in [`global_icons.py`](../api/app/routes/global_icons.py)).

Until sync has run, clients that rely only on CDN URLs may see 404s; use the **file** fallback or bundle locally during development.

---

## Offline and caching

The **instance offline manifest** (`GET .../offline/manifest`) does **not** currently enumerate global icons. Treat icons like any other static asset:

- When you cache **menus** (see [`client_instance_menus.md`](client_instance_menus.md)), collect the set of **`icon_key`** values you need.
- **Prefetch** those files over HTTPS (CDN or `.../global-icons/file/...`) into local storage, or **embed** the corresponding files in the app for a fixed key set.
- On **schema / catalog** changes (new keys or path overrides), refresh your local icon cache when you refresh menus or bump an app-defined “icons version.”

---

## Related

- Instance menus and `icon_key`: [`docs/client_instance_menus.md`](client_instance_menus.md)
- Auth and access patterns for instance APIs: [`docs/client_offline_sync.md`](client_offline_sync.md)
- Platform notes (Compose, SwiftUI, WinUI, Qt): [`platforms-client-instances`](../platforms-client-instances)

---

## After API or schema changes

Deploy updated Noolva API code and SQL per your release process, then **restart the Noolva API**. Client teams do not need a server restart to use CDN URLs once objects exist in S3.
