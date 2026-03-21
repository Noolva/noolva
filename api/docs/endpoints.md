# Noolva SaaS API — HTTP surface

**API origin:** `http://<host>:<port>` (default port `9001` from `APPLICATION_PORT`).

**JSON REST and WebSocket routes** are mounted under a single prefix: **`/api`**.  
Full URLs look like: `http://localhost:9001/api/auth/login`.

**Not under `/api`:**

| Path | Purpose |
|------|---------|
| `GET /` | Health / process up |
| `GET /docs`, `GET /redoc`, `GET /openapi.json` | FastAPI interactive docs and OpenAPI schema |
| `GET /assets/*` | Static files from `api/assets` (images referenced by URL in DB, etc.) |

**Admin (Vite):** set `VITE_API_URL` to the **origin only** (e.g. `http://localhost:9001`). The React app calls `origin + /api + …` (see `admin/src/utils/api.js`).

**Auth header (typical):** `Authorization: Bearer <JWT | PAT>`  
PATs start with `nvpat_` — see `how_to_use_pat.md`.

**Google OAuth:** Register the redirect URI as  
`https://<your-api-host>/api/auth/google-callback` (e.g. `http://localhost:9001/api/auth/google-callback`).

---

## Canonical auto-CRUD (data models)

For external apps, the **canonical** record API is:

| Method | Path |
|--------|------|
| `GET` | `/api/data-models/auto/{model_name}/records` |
| `GET` | `/api/data-models/auto/{model_name}/records/{record_id}` |
| `POST` | `/api/data-models/auto/{model_name}/records` |
| `PUT` | `/api/data-models/auto/{model_name}/records/{record_id}` |
| `DELETE` | `/api/data-models/auto/{model_name}/records/{record_id}` |

`{model_name}` is the data model’s **name** (slug), not the numeric id.

**Custom / configured endpoints** (from the API Endpoints registry) may also be invoked as:

- `GET /api/data-models/custom-endpoint/{endpoint_id}` (see admin API Endpoints UI for behavior).

---

## Full route list (`/api/...`)

Below, `{id}` and similar denote path parameters. Methods are as registered in FastAPI.

### Root & display

| Method | Path |
|--------|------|
| `GET` | `/api/` |
| `GET` | `/api/config/display` |

### Authentication — `/api/auth`

| Method | Path |
|--------|------|
| `GET` | `/api/auth/users` |
| `POST` | `/api/auth/create-user` |
| `POST` | `/api/auth/users/{user_id}/reset-password` |
| `POST` | `/api/auth/login` |
| `POST` | `/api/auth/login/verify-totp` |
| `GET` | `/api/auth/google` |
| `GET` | `/api/auth/google-callback` |
| `GET` | `/api/auth/me` |
| `GET` | `/api/auth/menus` |
| `GET` | `/api/auth/apps` |
| `GET` | `/api/auth/apps/{app_id}/menus` |
| `GET` | `/api/auth/accounts` |
| `POST` | `/api/auth/switch-account` |
| `GET` | `/api/auth/sessions` |
| `DELETE` | `/api/auth/sessions/{session_id}` |
| `DELETE` | `/api/auth/accounts/{profile_id}` |
| `GET` | `/api/auth/2fa/setup` |
| `POST` | `/api/auth/2fa/verify` |
| `POST` | `/api/auth/2fa/disable` |
| `PUT` | `/api/auth/me/idle-timeout` |
| `POST` | `/api/auth/reauth` |
| `POST` | `/api/auth/logout` |

### Settings — `/api/settings`

| Method | Path |
|--------|------|
| `GET` | `/api/settings/row-exposure-modes` |
| `GET` | `/api/settings/definitions` |
| `GET` | `/api/settings` |
| `PUT` | `/api/settings` |

### Themes — `/api/themes`

| Method | Path |
|--------|------|
| `GET` | `/api/themes` |
| `GET` | `/api/themes/active` |
| `GET` | `/api/themes/{theme_id}` |
| `POST` | `/api/themes` |
| `PUT` | `/api/themes/mine` |
| `PUT` | `/api/themes/{theme_id}` |
| `DELETE` | `/api/themes/{theme_id}` |

### Developer console — database — `/api/dev-console/database`

| Method | Path |
|--------|------|
| `GET` | `/api/dev-console/database/tables` |
| `GET` | `/api/dev-console/database/tables/{table_name}/structure` |
| `GET` | `/api/dev-console/database/tables/{table_name}/records` |
| `PUT` | `/api/dev-console/database/tables/{table_name}/schema` |
| `POST` | `/api/dev-console/database/execute-query` |
| `GET` | `/api/dev-console/database/suggestions` |
| `POST` | `/api/dev-console/database/records` |
| `PUT` | `/api/dev-console/database/records` |
| `DELETE` | `/api/dev-console/database/records` |

### App menus — `/api/app-menus`

| Method | Path |
|--------|------|
| `GET` | `/api/app-menus/` |
| `GET` | `/api/app-menus/{menu_id}` |

*(List route is registered as `/` on the router → `/api/app-menus/` with a trailing slash; clients may also use `/api/app-menus` depending on redirect settings.)*

### Data models — `/api/data-models`

| Method | Path |
|--------|------|
| `GET` | `/api/data-models/field-types/list` |
| `GET` | `/api/data-models/list` |
| `GET` | `/api/data-models/model/{model_id}` |
| `POST` | `/api/data-models/create` |
| `PUT` | `/api/data-models/model/{model_id}` |
| `GET` | `/api/data-models/model/{model_id}/delete-check` |
| `DELETE` | `/api/data-models/model/{model_id}` |
| `POST` | `/api/data-models/model/{model_id}/fields` |
| `PUT` | `/api/data-models/model/{model_id}/fields/reorder` |
| `PUT` | `/api/data-models/model/{model_id}/fields/{field_id}` |
| `DELETE` | `/api/data-models/model/{model_id}/fields/{field_id}` |
| `GET` | `/api/data-models/auto/{model_name}/records` |
| `GET` | `/api/data-models/auto/{model_name}/records/{record_id}` |
| `POST` | `/api/data-models/auto/{model_name}/records` |
| `PUT` | `/api/data-models/auto/{model_name}/records/{record_id}` |
| `DELETE` | `/api/data-models/auto/{model_name}/records/{record_id}` |
| `GET` | `/api/data-models/custom-endpoint/{endpoint_id}` |

### Field options — `/api/field-options`

| Method | Path |
|--------|------|
| `POST` | `/api/field-options/fetch` |
| `GET` | `/api/field-options/collections` |

### Icons — `/api/icons`

| Method | Path |
|--------|------|
| `GET` | `/api/icons/list` |
| `GET` | `/api/icons/{icon_id}` |
| `GET` | `/api/icons/categories/list` |
| `GET` | `/api/icons/tags/list` |
| `GET` | `/api/icons/types/list` |

### Collections — `/api/collections`

| Method | Path |
|--------|------|
| `GET` | `/api/collections/list` |
| `GET` | `/api/collections/{collection_id}` |
| `POST` | `/api/collections/create` |
| `PUT` | `/api/collections/{collection_id}` |
| `DELETE` | `/api/collections/{collection_id}` |

### API Endpoints registry — `/api/api-endpoints`

| Method | Path |
|--------|------|
| `GET` | `/api/api-endpoints/list` |
| `GET` | `/api/api-endpoints/orphaned-auto-crud` |
| `GET` | `/api/api-endpoints/{endpoint_id}` |
| `POST` | `/api/api-endpoints/create` |
| `PUT` | `/api/api-endpoints/{endpoint_id}` |
| `DELETE` | `/api/api-endpoints/{endpoint_id}` |

### Personal access tokens — `/api/personal-access-tokens`

| Method | Path |
|--------|------|
| `POST` | `/api/personal-access-tokens/create` |
| `GET` | `/api/personal-access-tokens/list` |
| `DELETE` | `/api/personal-access-tokens/{pat_id}` |

### Upload (S3) — `/api`

| Method | Path |
|--------|------|
| `POST` | `/api/upload` |
| `GET` | `/api/private-file` |

### Jobs, workers, templates, schedulers — `/api`

| Method | Path |
|--------|------|
| `POST` | `/api/jobs` |
| `GET` | `/api/jobs/{job_id}` |
| `GET` | `/api/jobs` |
| `GET` | `/api/workers` |
| `GET` | `/api/job-templates` |
| `GET` | `/api/job-templates/{template_id}` |
| `POST` | `/api/job-templates` |
| `PUT` | `/api/job-templates/{template_id}` |
| `POST` | `/api/workers/register` |
| `GET` | `/api/jobs/claim` |
| `POST` | `/api/jobs/{job_id}/result` |
| `POST` | `/api/jobs/{job_id}/cancel` |
| `GET` | `/api/schedulers/next-runs` |
| `GET` | `/api/schedulers` |
| `GET` | `/api/schedulers/{scheduler_id}` |
| `POST` | `/api/schedulers` |
| `PUT` | `/api/schedulers/{scheduler_id}` |
| `DELETE` | `/api/schedulers/{scheduler_id}` |

### WebSocket — `/api` (and root aliases)

The same handler is registered twice so older clients keep working:

| Protocol | Path |
|----------|------|
| WebSocket | `/api/ws` |
| WebSocket | `/api/ws/{device_id}` |
| WebSocket | `/ws` |
| WebSocket | `/ws/{device_id}` |

See `how-to-connect-websocket` for auth (`?token=` or `?access_token=`, `Authorization: Bearer …`, or first-frame JSON).

---

## Cross-check

This list is derived from `api/app/main.py` (single `APIRouter(prefix="/api")`) and the `api/app/routes/*.py` route decorators. If you add a router in `main.py`, update this file.

**Older docs** may still show paths without `/api`; the implementation uses **`/api` only** for the routes above.
