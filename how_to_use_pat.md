# How to Connect Using a Personal Access Token (PAT) from External Clients

## 1. Get a PAT (from the admin app)

- Log in to the **admin app** (React) with a user that has one of: `saas_admin`, `saas_employee`, `tenant_admin`, `tenant_user`.
- Go to **Organization → Personal Access Tokens**.
- Create a token: set **name**, **expiry** (e.g. 90 days), optionally **company** and **scopes**.
- **Copy the token immediately** — it is only shown once (format: `nvpat_` + 64 hex characters, e.g. `nvpat_a1b2c3d4e5f6...`).

You can also create a PAT via API (with a valid JWT):

- **Endpoint:** `POST /personal-access-tokens/create`
- **Body:** `{ "name": "My token", "expires_days": 90, "company_id": null, "scopes": [] }`
- **Response:** includes `"token": "nvpat_..."` — store it securely; it is not returned again.

---

## 2. Use the PAT from an external client

Use the **same API origin** as your admin (e.g. `https://api.yourdomain.com` or `http://localhost:9001`). All JSON endpoints are under the **`/api`** prefix (e.g. `http://localhost:9001/api/...`).

Send the PAT as a **Bearer** token on every request:

- **Header:** `Authorization: Bearer <your_pat_plaintext>`

**cURL example:**

```bash
curl -H "Authorization: Bearer nvpat_YOUR_TOKEN_HERE" \
  "http://localhost:9001/api/data-models/auto/users/records"
```

**JavaScript (fetch):**

```javascript
const response = await fetch('http://localhost:9001/api/data-models/auto/users/records', {
  headers: {
    'Authorization': `Bearer ${yourPAT}`,
    'Content-Type': 'application/json',
  },
});
```

**Python (requests):**

```python
import requests
headers = {"Authorization": f"Bearer {your_pat}"}
r = requests.get("http://localhost:9001/api/data-models/auto/users/records", headers=headers)
```

---

## 2a. External integration – exact requirements (share with external teams)

Use this section when sharing PAT usage with external developers or scripts.

### Required: Authorization header

Every authenticated request **must** send exactly:

- **Header name:** `Authorization` (case-insensitive per HTTP; typical is `Authorization`)
- **Header value:** `Bearer ` (capital B, one space) followed by the **full token** with no extra spaces

**Correct:**

```http
Authorization: Bearer nvpat_abc123def456...
```

**Wrong (will cause 401):**

- Missing header
- `Bearer` with no space before the token
- `bearer` (lowercase) — some servers accept it, but always use `Bearer `
- Token in query string or body instead of header
- Truncated or modified token (e.g. copy-paste error)
- Sending a **JWT** (session token from login) instead of the **PAT** — use the PAT string that starts with `nvpat_`

### PUT /settings (e.g. Current User Mode) – minimal examples

**cURL:**

```bash
curl -X PUT "https://YOUR_API_BASE/settings" \
  -H "Authorization: Bearer nvpat_YOUR_FULL_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scope":"user","settings":{"current_user_mode":2}}'
```

**Python (requests):**

```python
import requests
url = "https://YOUR_API_BASE/settings"
headers = {
    "Authorization": f"Bearer {pat}",   # pat = full string, e.g. nvpat_...
    "Content-Type": "application/json",
}
payload = {"scope": "user", "settings": {"current_user_mode": 2}}
r = requests.put(url, headers=headers, json=payload)
# 200 = success; 401 = check header and token
```

**JavaScript (fetch):**

```javascript
const response = await fetch('https://YOUR_API_BASE/settings', {
  method: 'PUT',
  headers: {
    'Authorization': `Bearer ${pat}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ scope: 'user', settings: { current_user_mode: 2 } }),
});
```

**Common mistakes:**

| Mistake | Result | Fix |
|--------|--------|-----|
| No `Authorization` header | 401 | Add header: `Authorization: Bearer <token>` |
| Token in body or query | 401 | Send token only in the `Authorization` header |
| Using JWT (login token) instead of PAT | 401 or wrong user | Use the PAT value that starts with `nvpat_` |
| Wrong or expired PAT | 401 | Create a new PAT in admin and use the new value |
| PAT has scopes but not `settings`/`*` | 403 | Create PAT with no scopes, or add scope `settings` or `*` |

### If you get 401 – what the server logs show

The API logs a **detailed line** for each failed auth so you can debug:

- **`PUT /settings 401: Authorization header missing or empty`** → The request did not include an `Authorization` header or it was empty. Add the header.
- **`PUT /settings 401: token rejected (invalid/expired/wrong). Token prefix=...`** → The token was sent but not accepted (wrong token, expired PAT, or not a valid JWT). Check you are sending the full PAT (starts with `nvpat_`) and that it has not been revoked or expired.
- **`Auth: no Authorization header or empty value`** → Same as above; no header.
- **`Auth: Authorization header present but does not start with 'Bearer '`** → Header value must be exactly `Bearer ` + token.
- **`PAT lookup: no row for token hash (token may be wrong or expired)`** → The PAT string does not match any active token in the database (typo, wrong token, or expired). Create a new PAT if needed.

**If you see "JWT decode failed" and "PAT lookup: no row" together** → You are sending a **JWT** (session token), not a PAT. JWTs start with `eyJ...` (base64). Use the **PAT** string that starts with `nvpat_` (from Organization → Personal Access Tokens). Do not use the token returned at login for PAT-only endpoints; create and use a PAT. See §2 and "JWT vs PAT" below.

### JWT vs PAT – do not mix them up

| Token type | Looks like | Where you get it | Use for |
|------------|------------|-------------------|--------|
| **PAT** | `nvpat_` + 64 hex chars | Admin: Organization → Personal Access Tokens → Create (copy once) | External scripts, PUT /settings, POST /upload, auto CRUD from other apps |
| **JWT** | `eyJ...` (long base64 string) | Returned at login (e.g. `POST /api/auth/login`) | Browser/admin app session only; many API routes accept **only JWT**, not PAT |

For **PUT /settings**, **POST /upload**, and **data-models auto CRUD**, you must send the **PAT** in the header:

```http
Authorization: Bearer nvpat_abc123def456...
```

If you send a JWT (`eyJ...`) instead, the server will try to verify it (and may fail with `InvalidSignatureError` if it’s from another env or expired), then try PAT lookup and find no row. You will get **401** and logs like:

- `Auth: JWT decode failed for eyJhbGciOi...(121 chars): InvalidSignatureError`
- `PAT lookup: no row for token hash (token may be wrong or expired); token prefix: eyJhbGciOi...(121 chars)`
- `Auth: token eyJhbGciOi...(121 chars) -> not valid JWT and PAT lookup failed`

**Fix:** Use the PAT value (starts with `nvpat_`), not the login/session JWT.

Share the **exact request** (headers only; never log the full token) and the **log line** with your API admin to confirm the server received the right header and why it rejected the token.

---

## 3. Which endpoints accept PAT?

**PAT is accepted only on routes that use Bearer resolution (JWT or PAT):**

- **Data-models CRUD (auto):** e.g. `GET/POST/PUT/DELETE /data-models/auto/<model_name>/records` — these accept PAT.
- **File upload (S3):** `POST /upload` — upload files to the default S3 bucket; accepts PAT (see §5a below).
- **Private file access:** `GET /private-file` — get a signed URL or stream decrypted file content; accepts PAT (see §5c below).

**Settings (user-scoped) and row exposure modes accept PAT:**

- **GET** `/settings/row-exposure-modes` — returns the list of available modes (no auth required).
- **PUT** `/settings` with `scope: "user"` and `current_user_mode` — update the current user’s “Current User Mode” (JWT or PAT). See §3a below.

**These endpoints accept only JWT (login session token), not PAT:**

- `/app-menus/list` — returns `{"detail":"Invalid token"}` if you send a PAT.
- Other org/auth routes (e.g. `/api/auth/menus`, `/api/auth/accounts`, etc.) — same: JWT only.

So use your PAT with **data-models** endpoints to verify it works. For example:

```bash
curl -s -H "Authorization: Bearer nvpat_YOUR_FULL_TOKEN" \
  "http://localhost:9001/api/data-models/auto/users/records"
```

(Replace `users` with an actual auto model name if different.)

---

## 3a. Current User Mode (settings) and list of modes — with PAT

The **Current User Mode** setting controls which rows are returned by auto CRUD list/get when the model has a `row_exposure_mode_id` column: if set, only rows with that mode (and `expose_data = true`) or with `row_exposure_mode_id` NULL/0 are returned; if not set (null), all rows are returned.

You can **get the list of available modes** and **set the current user’s mode** using a PAT.

### Get list of modes (no auth)

**Endpoint:** `GET /settings/row-exposure-modes`

Returns all row exposure modes. No `Authorization` header required.

**Response:**

```json
{
  "options": [
    { "label": "normal", "value": 1 },
    { "label": "private", "value": 2 },
    { "label": "travel", "value": 3 }
  ],
  "modes": [
    { "exposure_mode_id": 1, "name": "normal", "description": "Default / normal visibility", "expose_data": true },
    { "exposure_mode_id": 2, "name": "private", "description": "Private mode", "expose_data": false }
  ]
}
```

- **`options`** — for dropdowns: `label` (name), `value` (exposure_mode_id).
- **`modes`** — full rows: `exposure_mode_id`, `name`, `description`, `expose_data`.

**cURL:**

```bash
curl -s "http://localhost:9001/api/settings/row-exposure-modes"
```

### Get current user mode (JWT or PAT)

To **read** the current user’s settings (including `current_user_mode`), use **GET /settings** with `scope=user`. Auth is required (JWT or PAT).

**Endpoint:** `GET /settings`

**Query params:**

- `scope=user` — required to get per-user settings.
- `keys=current_user_mode` — optional; comma-separated keys. Omit to get all user-scoped settings.

**Auth:** `Authorization: Bearer <JWT or PAT>`

**Example response:**

```json
{
  "settings": {
    "current_user_mode": 2
  },
  "scope": "user",
  "tenant_id": null
}
```

If the mode is not set, `current_user_mode` may be `null`.

**cURL (with PAT):**

```bash
# Get only current_user_mode
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/settings?scope=user&keys=current_user_mode"

# Get all user-scoped settings
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/settings?scope=user"
```

**Python (requests):**

```python
import requests
pat = "nvpat_YOUR_FULL_TOKEN"
base = "http://localhost:9001/api"
headers = {"Authorization": f"Bearer {pat}"}

# Get current_user_mode
r = requests.get(f"{base}/settings", params={"scope": "user", "keys": "current_user_mode"}, headers=headers)
data = r.json()  # {"settings": {"current_user_mode": 2}, "scope": "user", "tenant_id": null}
mode_id = data.get("settings", {}).get("current_user_mode")  # 2 or None
```

**JavaScript (fetch):**

```javascript
const pat = "nvpat_YOUR_FULL_TOKEN";
const base = "http://localhost:9001/api";

const r = await fetch(`${base}/settings?scope=user&keys=current_user_mode`, {
  headers: { Authorization: `Bearer ${pat}` },
});
const data = await r.json();
const currentUserMode = data.settings?.current_user_mode ?? null;
```

### Set Current User Mode (JWT or PAT)

**Endpoint:** `PUT /settings`

**Auth:** `Authorization: Bearer <JWT or PAT>` — the header is required. Use the full token (JWT or PAT starting with `nvpat_`). If the PAT has scopes set, it must include one of: `settings`, `user_settings`, or `*` (PATs with no scopes or empty scopes can always call this endpoint).

Set the **current user’s** mode (stored per user). Use `scope: "user"` and only the key `current_user_mode`. Value is the **exposure_mode_id** (integer) from the list of modes, or `null` to clear (show all rows).

**Request body:**

```json
{
  "scope": "user",
  "settings": {
    "current_user_mode": 2
  }
}
```

- Use an **integer** (e.g. `2`) to set the mode; use `null` to unset and show all rows.
- Only `current_user_mode` is allowed when `scope` is `"user"`.

**cURL (with PAT):**

```bash
curl -X PUT -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scope":"user","settings":{"current_user_mode":2}}' \
  "http://localhost:9001/api/settings"
```

**Clear the mode (show all rows):**

```bash
curl -X PUT -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"scope":"user","settings":{"current_user_mode":null}}' \
  "http://localhost:9001/api/settings"
```

**Python (requests):**

```python
import requests

pat = "nvpat_YOUR_FULL_TOKEN"
base = "http://localhost:9001/api"

# 1) Get available modes (optional; no auth)
r = requests.get(f"{base}/settings/row-exposure-modes")
modes = r.json()  # {"options": [...], "modes": [...]}

# 2) Get current user mode
r = requests.get(f"{base}/settings", params={"scope": "user", "keys": "current_user_mode"}, headers={"Authorization": f"Bearer {pat}"})
current_mode = r.json().get("settings", {}).get("current_user_mode")  # int or None

# 3) Set current user mode (e.g. "private" = 2)
requests.put(
    f"{base}/settings",
    headers={"Authorization": f"Bearer {pat}", "Content-Type": "application/json"},
    json={"scope": "user", "settings": {"current_user_mode": 2}},
)

# 4) Clear mode (show all rows)
requests.put(
    f"{base}/settings",
    headers={"Authorization": f"Bearer {pat}", "Content-Type": "application/json"},
    json={"scope": "user", "settings": {"current_user_mode": None}},
)
```

**Summary:**

| Action              | Endpoint                        | Auth   | Body / params |
|---------------------|----------------------------------|--------|----------------|
| List modes          | `GET /settings/row-exposure-modes` | None   | —              |
| Get current user mode | `GET /settings?scope=user&keys=current_user_mode` | JWT or PAT | —              |
| Set current user mode | `PUT /settings`                 | JWT or PAT | `{"scope":"user","settings":{"current_user_mode": <id or null>}}` |

---

## 4. Request body format (POST and PUT)

For **creating** and **updating** records, the body must wrap the field values in a **`data`** object. Field names must match the model’s fields (as in Studio).  
**Note:** POST to the same path with a body containing **`filter`** (and no `data`) is treated as **list-with-filter**, not create — see §5.

**POST** (create): `POST /data-models/auto/<model_name>/records`

```json
{
  "data": {
    "name": "Vijayakaran",
    "alias_names": "karan,vijay",
    "dob": "1985-10-27",
    "marital_status": "Married",
    "anniversary_date": "2017-11-27",
    "notes": null
  }
}
```

**PUT** (update): `PUT /data-models/auto/<model_name>/records/<record_id>`

```json
{
  "data": {
    "name": "Updated Name",
    "notes": "Updated notes"
  }
}
```

- **Wrong:** Sending fields at the top level (e.g. `{ "name": "John", "dob": "1990-01-15" }`) will be rejected or misinterpreted. Always use `"data": { ... }`.
- **Dates:** Send as ISO date strings (e.g. `"1985-10-27"`). The API converts them to the correct type for the database.
- **Null:** Omit a field or set it to `null` to leave it unchanged (PUT) or use default/null (POST).

---

## 5. List (GET) and pagination — with optional filtering

**GET** `GET /data-models/auto/<model_name>/records`

- **Query params (optional):**
  - `limit` — max records per page (default 100, max 1000).
  - `offset` — skip N records for pagination.
  - `fields` — comma-separated field names to return (default: all model fields).
  - **Filter by field:** any **other** query param whose name is a **model field name** is treated as an **equality filter**. Only rows where that column equals the given value are returned. Multiple filter params are combined with AND. Use this to list records for a single “parent” (e.g. only comments for one task) without loading the full table.

**Reserved param names:** `limit`, `offset`, `fields`. All other param names that match a model field become filters.

**Examples:**

List all persons (paginated):

```bash
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/data-models/auto/persons/records?limit=20&offset=0&fields=name,dob,notes"
```

List only records for a given parent (e.g. task_comments for task 40):

```bash
# If the model has a field named "task" or "task_id", pass it as query param:
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/data-models/auto/task_comments/records?task=40&limit=100"
# or
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/data-models/auto/task_comments/records?task_id=40&fields=id,body,created_at"
```

Filter values are coerced to the field type (integer, UUID, date, etc.). Filter params work together with `limit`, `offset`, and `fields`.

---

### POST: create vs list-with-filter

**POST** to the same path can do two different things depending on the body:

| Body shape | Behaviour |
|------------|-----------|
| `{ "data": { ... } }` (non-empty `data` object) | **Create** one record (INSERT). Same as before. |
| `{ "filter": { "<field>": <value>, ... } }` and **no** `data` (or empty `data`) | **List with filter** (SELECT). Returns the same list shape as GET with filter params; not a create. |

- **Create** remains the only way to insert: body must be `{ "data": { ... } }`. Field names in `data` must match the model.
- **List-with-filter:** send a body with **`filter`** (object of field name → value). You can also send optional `limit`, `offset`, and `fields` in the same body. The API performs a **filtered list** (read), not a create. Use this when you prefer to send filter criteria in the request body (e.g. complex or many filters) or when the client uses POST for all list operations.

**Example – list task_comments for task 40 via POST:**

```bash
curl -s -X POST -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"filter":{"task":40},"limit":100,"fields":"id,body,created_at"}' \
  "http://localhost:9001/api/data-models/auto/task_comments/records"
```

Response shape is the same as GET list: `{ "model_name": "...", "records": [ ... ], "limit": 100, "offset": 0 }`.

**Summary of auto CRUD endpoints:**

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/data-models/auto/<model_name>/records` | List records (supports `limit`, `offset`, `fields`, and **filter by field** via query params) |
| POST | `/data-models/auto/<model_name>/records` | Create one record (body: `{ "data": { ... } }`) **or** list with filter (body: `{ "filter": { ... }, optional "limit", "offset", "fields" }` — no `data`) |
| PUT | `/data-models/auto/<model_name>/records/<record_id>` | Update one record (body: `{ "data": { ... } }`) |
| DELETE | `/data-models/auto/<model_name>/records/<record_id>` | Delete one record |

**Settings (Current User Mode) and modes:**

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/settings/row-exposure-modes` | List available row exposure modes (no auth) |
| GET | `/settings?scope=user&keys=current_user_mode` | Get current user mode (JWT or PAT) |
| PUT | `/settings` | Set current user mode: body `{"scope":"user","settings":{"current_user_mode":<id\|null>}}` (JWT or PAT) |

---

## 5a. File upload (default S3)

Upload one or more files to the **default S3 bucket** (from integrations: `url`, `bucket_name`, `bucket_prefix`, etc.). Use for form uploads or when an external app connects with a PAT. **Public** files: CDN open access. **Private** (`is_public=false`): stored under `private/`; access requires a signed URL (per CDN rules).

**Endpoint:** `POST /upload`

**Auth:** `Authorization: Bearer <JWT or PAT>`

**Request:** `multipart/form-data` (not JSON)

| Field         | Required | Description |
|--------------|----------|-------------|
| `file`       | No**     | Single file (use `file` or `files`; at least one required). |
| `files`      | No**     | Multiple files (alternative to `file`). |
| `key`        | No*      | S3 key/path. Omit when using **model-attachments** (use `model_name`). With multiple files, only the first uses `key`. |
| `is_public`  | No       | `true` or `false` (default: `true`). Public = CDN open; private = signed URL required. |
| `model_name` | No*      | Data model name (e.g. `persons`). Use for **model-attachments**: file is stored under `public/model-attachments/<model_name>/<unique_id>` or `private/...`. |
| `field_name` | No       | Field name (e.g. `profile_photo`). Required when updating a record so the previous file for this field can be deleted. |
| `record_id`  | No       | Record id. With `field_name`, previous file(s) for that field are deleted from S3 before upload. |

\* Provide **either** `key` **or** `model_name`, not both.  
\** At least one of `file` or `files` is required.

**Field config:** When `model_name` and `field_name` are provided, the API validates against the field’s config (file/image type): **filters** (e.g. `[".jpg", ".png"]`) — allowed extensions; **max_size_mb** — max file size in MB. **multiple** (single path vs JSON array) is respected when saving the field in auto CRUD. For **image** fields, **generate_thumbnail** and **crop_ratio** control automatic thumbnail generation (see Thumbnails below).

**Success response (200) – single file:**

```json
{
  "success": true,
  "s3_key": "public/model-attachments/persons/53d5217f6e5b46cfa3be87061ca5dae0.jpg",
  "path": "public/model-attachments/persons/53d5217f6e5b46cfa3be87061ca5dae0.jpg",
  "bucket": "your-bucket-name",
  "public_url": "https://cdn.avkaran.com/websites/noolva/public/model-attachments/persons/53d5217f6e5b46cfa3be87061ca5dae0.jpg",
  "is_public": true
}
```

For **model-attachments**, `s3_key` and `path` are returned **without** the bucket prefix (e.g. no `websites/noolva/`); store this value in the record. For uploads with `key`, the returned path may include your custom path only (no prefix). **Display URL** = integration `url` + `"/"` + `bucket_prefix` + `"/"` + stored path.

**Success response (200) – multiple files:**

```json
{
  "success": true,
  "uploads": [
    { "s3_key": "...", "path": "...", "public_url": "...", "bucket": "...", "is_public": true, "filename": "a.jpg" },
    { "s3_key": "...", "path": "...", "public_url": "...", "bucket": "...", "is_public": true, "filename": "b.jpg" }
  ],
  "count": 2
}
```

**cURL example (single file):**

```bash
curl -X POST -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  -F "file=@/path/to/document.pdf" \
  -F "key=uploads/my-doc.pdf" \
  -F "is_public=false" \
  "http://localhost:9001/api/upload"
```

**Python (requests):**

```python
import requests
with open("photo.jpg", "rb") as f:
    r = requests.post(
        "http://localhost:9001/api/upload",
        headers={"Authorization": f"Bearer {your_pat}"},
        files={"file": ("photo.jpg", f, "image/jpeg")},
        data={"key": "uploads/photo.jpg", "is_public": "true"},
    )
print(r.json())  # e.g. {"success": true, "s3_key": "...", "public_url": "..."}
```

**JavaScript (FormData):**

```javascript
const form = new FormData();
form.append('file', fileInput.files[0]);
form.append('key', 'uploads/myfile.pdf');
form.append('is_public', 'false');
const response = await fetch('http://localhost:9001/api/upload', {
  method: 'POST',
  headers: { 'Authorization': `Bearer ${yourPAT}` },
  body: form,
});
const result = await response.json();
```

**Notes:**

- The default S3 integration must be configured (provider `aws_s3`, marked default) for the PAT’s company (or first company if unset). Otherwise you get `503 Default S3 integration not configured`. Config uses `url` (CDN base), `bucket_name`, `bucket_prefix`, `region` from the integration.
- **Stored path (no prefix):** The API returns `s3_key` and `path` **without** the bucket prefix (e.g. `public/model-attachments/persons/53d5217f6e5b46cfa3be87061ca5dae0.jpg`). The prefix (e.g. `websites/noolva`) is in the S3 integration config, so store the returned path as-is in the data model field.
- **Display URL:** To build the URL for viewing the file, use: **config.url** + **"/"** + **bucket_prefix** + **stored path**. Example: if `url` is `https://cdn.avkaran.com`, `bucket_prefix` is `websites/noolva`, and stored path is `public/model-attachments/persons/xxx.jpg`, then display URL = `https://cdn.avkaran.com/websites/noolva/public/model-attachments/persons/xxx.jpg`. The response also includes `public_url` when the file is public (that is the full URL).
- **Private uploads:** Set `is_public=false`. Files are stored under `private/`; access requires a **signed URL** (per your CDN rules, e.g. `/private/*` requires signing).
- **Multi-file:** Send multiple files as `files` (or multiple `file` parts). Response is `{ "success", "uploads": [...], "count" }`. For a field with `multiple: true`, store a JSON array of the returned `s3_key` values (paths without prefix) in the record.

**Thumbnails (image fields):** When the field type is **image** (not file) and the field’s `field_config_json` has **`"generate_thumbnail": true`**, the upload API automatically generates a thumbnail and uploads it to the same S3 path with the naming **`<actual_filename>_thumb.<extension>`**. Example: main file `public/model-attachments/persons/abc123.jpg` → thumbnail `public/model-attachments/persons/abc123_thumb.jpg`. If **crop_ratio** is set in the field config (e.g. `"1:1"`), it is applied when generating the thumbnail (center crop before resize). Thumbnails are always JPEG. When you replace an attachment (same `model_name` + `field_name` + `record_id`), the previous thumbnail for that path is also deleted from S3. The API does not return the thumbnail path in the upload response; you can derive it from the main path by replacing the filename with `<basename>_thumb.<ext>`.

### 5b. Data-model file/image fields (model attachments) with PAT

Data models can have **file** or **image** field types (see `field_types`: `type_code` `file` or `image`). Values are stored as S3 paths (or full URLs). To set such a field via the API with a PAT:

1. **Upload** the file with `POST /upload` using **model-attachments** form fields, then  
2. **Update** (or create) the record with the returned path in the field.

**Step 1 – Upload (model-attachments):**

Send `multipart/form-data` with:

- `file` — the file (required)
- `model_name` — e.g. `persons` (required for this flow; do not send `key`)
- `field_name` — e.g. `profile_photo` (optional but recommended so old file can be deleted on replace)
- `record_id` — e.g. `3a734566-e01c-4bb2-9a48-45739a473a02` (optional; if provided with `field_name`, previous file for that field is deleted from S3)
- `is_public` — `true` or `false` (default `true`)

**Example (cURL):**

```bash
curl -X POST -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  -F "file=@/path/to/photo.jpg" \
  -F "is_public=true" \
  -F "model_name=persons" \
  -F "field_name=profile_photo" \
  -F "record_id=3a734566-e01c-4bb2-9a48-45739a473a02" \
  "http://localhost:9001/api/upload"
```

**Example (Python with PAT):**

```python
import requests

pat = "nvpat_YOUR_FULL_TOKEN"
base = "http://localhost:9001/api"

# 1) Upload for model-attachments
with open("photo.jpg", "rb") as f:
    r = requests.post(
        f"{base}/upload",
        headers={"Authorization": f"Bearer {pat}"},
        files={"file": ("photo.jpg", f, "image/jpeg")},
        data={
            "is_public": "true",
            "model_name": "persons",
            "field_name": "profile_photo",
            "record_id": "3a734566-e01c-4bb2-9a48-45739a473a02",
        },
    )
r.raise_for_status()
upload_res = r.json()
# e.g. {"success": true, "s3_key": "public/model-attachments/persons/abc123.jpg", "path": "...", "public_url": "..."}
s3_key = upload_res["s3_key"]   # or use "public_url" if you store full URL

# 2) Update the record with the new path
update_r = requests.put(
    f"{base}/data-models/auto/persons/records/3a734566-e01c-4bb2-9a48-45739a473a02",
    headers={"Authorization": f"Bearer {pat}", "Content-Type": "application/json"},
    json={"data": {"profile_photo": s3_key}},
)
update_r.raise_for_status()
```

**Step 2 – Save path on the record:**

- **Update:** `PUT /data-models/auto/<model_name>/records/<record_id>` with body `{ "data": { "<field_name>": "<s3_key or public_url>" } }`.
- **Create:** When creating a record, you can upload first (omit `record_id`), then `POST /data-models/auto/<model_name>/records` with `{ "data": { ..., "<field_name>": "<s3_key>" } }`.

The API treats fields whose type is **file** or **image** as attachment fields: when you **update** a record and change such a field, the previous S3 object (if stored as a path, not an external URL) is deleted. So uploading with `model_name` + `field_name` + `record_id` allows the upload endpoint to delete the old file when replacing; the same cleanup also runs when you PUT the record with a new value.

**Summary for file/image fields with PAT:**

| Step | Action | Endpoint |
|------|--------|----------|
| 1 | Upload file (model-attachments) | `POST /upload` with `file` (or `files`), `model_name`, optional `field_name`, `record_id`, `is_public` |
| 2 | Set field on record | `PUT /data-models/auto/<model_name>/records/<record_id>` with `{"data": {"<field_name>": "<s3_key or public_url>"}}` (or JSON array of paths for `multiple: true` fields) |

**Rules for file/image fields:**

- **Default S3:** Upload uses the default S3 integration (config: `url`, `bucket_prefix`, `bucket_name`, `region`).
- **Stored value (no prefix):** Store the **path without** the bucket prefix. The API returns `s3_key`/`path` already without prefix (e.g. `public/model-attachments/persons/53d5217f6e5b46cfa3be87061ca5dae0.jpg`). The prefix (e.g. `websites/noolva`) lives in the S3 integration config only. **Display URL** = `config.url` + `"/"` + `bucket_prefix` + `"/"` + stored path (e.g. `https://cdn.avkaran.com/websites/noolva/public/model-attachments/persons/xxx.jpg`).
- **Public vs private:** `is_public=true` → `public/` (CDN open). `is_public=false` → `private/` (signed URL required).
- **Field config:** When defining the model field, set `field_config_json` (e.g. `{"filters": [".jpg", ".png", ".jpeg"], "multiple": false}` or `true`, `max_size_mb`: 2). The upload API validates filters and max_size_mb when `model_name` and `field_name` are sent. For **image** fields, add **`"generate_thumbnail": true`** to auto-generate a thumbnail (path: `<filename>_thumb.<ext>`); optional **`"crop_ratio": "1:1"`** (or e.g. `"16:9"`) is applied when generating the thumbnail.
- **Auto CRUD:** On **update**, old S3 objects for replaced file/image values are deleted (single path or JSON array). On **delete** record, all file/image field values (paths) for that record are deleted from S3. The API accepts stored paths with or without prefix when resolving the full S3 key for delete.

Use the **same API origin** as your admin (e.g. `http://localhost:9001`) and call **`/api/upload`**. If you get "Route not found", ensure the path includes the `/api` prefix and the upload router is registered (API restart may be required after deployment).

### 5c. Private file access (GET /private-file) and encrypted file/image fields

**Endpoint:** `GET /private-file`  
**Auth:** `Authorization: Bearer <JWT or PAT>`

Use this endpoint to access **private** files (stored under `private/` in S3). You can either get a **signed URL** (redirect or JSON) or, for **encrypted** file/image fields, stream the **decrypted** content directly from the API.

**Query parameters:**

| Parameter      | Required | Description |
|----------------|----------|-------------|
| `path`         | Yes      | S3 storage path (e.g. `private/model-attachments/task_attachments/36d7dcb368a147f686074e9b25a7491e.png`). Same value stored in the record’s file/image field. |
| `redirect`     | No       | `true` (default): redirect to the presigned URL. `false`: return JSON `{ "url": "<presigned_url>" }`. Ignored when `decrypt=true`. |
| `decrypt`      | No       | `false` (default): return signed URL (redirect or JSON). `true`: stream decrypted file content (see below). |
| `model_name`   | If decrypt | Data model name (e.g. `task_attachments`). **Required when `decrypt=true`.** |
| `field_name`   | If decrypt | Field name (e.g. `attachment`). **Required when `decrypt=true`.** |

**When to use `decrypt=true`:**  
When the file/image field has **encryption** (`encryption_method` = `xor_cipher` or `aes`), the **file content** in S3 is encrypted; the **path** in the DB is stored plain. To download the actual file content, call with `decrypt=true` and pass `model_name` and `field_name` so the API can look up the encryption method, fetch the object from S3, decrypt it, and stream it back. Without `decrypt=true`, you only get a signed URL to the **encrypted** object (which is not useful for viewing the file).

**Encrypted file/image fields – summary for external apps:**

- **Upload:** No change. Use `POST /upload` with `model_name`, `field_name`, and `record_id` as usual. If the field has encryption, the API encrypts the file content before storing in S3; the returned `path` is stored in the record as-is (plain).
- **Read record:** The API returns the **path** (plain) in the file/image field. It does not decrypt the path.
- **Download (no decryption):** For **non-encrypted** private files, use `GET /private-file?path=...&redirect=false` to get a signed URL, then fetch the file from that URL.
- **Download (decrypted):** For **encrypted** file/image fields, use `GET /private-file?path=...&decrypt=true&model_name=<model>&field_name=<field>`. The response is the decrypted file stream (same `Content-Type` as the original file). Do not use the signed-URL flow for encrypted content.

**Example – get signed URL (private, non-encrypted):**

```bash
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/private-file?path=private%2Fmodel-attachments%2Ftask_attachments%2F36d7dcb368a147f686074e9b25a7491e.png&redirect=false"
```

Response: `{ "url": "https://cdn.example.com/...?Expires=...&Signature=..." }`

**Example – stream decrypted file (encrypted file/image field):**

```bash
curl -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/api/private-file?path=private%2Fmodel-attachments%2Ftask_attachments%2F36d7dcb368a147f686074e9b25a7491e.png&decrypt=true&model_name=task_attachments&field_name=attachment" \
  -o downloaded.png
```

**Example – Python (decrypt and save):**

```python
import requests

pat = "nvpat_YOUR_FULL_TOKEN"
base = "http://localhost:9001/api"
path = "private/model-attachments/task_attachments/36d7dcb368a147f686074e9b25a7491e.png"

# Option A: Get signed URL (for non-encrypted private files)
r = requests.get(
    f"{base}/private-file",
    headers={"Authorization": f"Bearer {pat}"},
    params={"path": path, "redirect": "false"},
)
r.raise_for_status()
url = r.json()["url"]
# Then fetch file from url if needed

# Option B: Stream decrypted content (for encrypted file/image fields)
r = requests.get(
    f"{base}/private-file",
    headers={"Authorization": f"Bearer {pat}"},
    params={
        "path": path,
        "decrypt": "true",
        "model_name": "task_attachments",
        "field_name": "attachment",
    },
    stream=True,
)
r.raise_for_status()
with open("downloaded.png", "wb") as f:
    for chunk in r.iter_content(chunk_size=8192):
        f.write(chunk)
```

**Summary:**

| Use case                         | Query params                                      | Response / action |
|----------------------------------|---------------------------------------------------|-------------------|
| Get signed URL                   | `path=...`, `redirect=false`                      | JSON `{ "url": "..." }` |
| Redirect to signed URL           | `path=...` (default `redirect=true`)               | HTTP redirect to CDN |
| Download decrypted file content  | `path=...`, `decrypt=true`, `model_name=...`, `field_name=...` | Binary stream (decrypted file) |

---

## 6. How the API treats the token

- The API accepts **either** a **JWT** (session login) **or** a **PAT** only on routes that call `resolve_bearer_to_user` (e.g. data-models CRUD).
- On those routes it tries **JWT first**; if that fails, it hashes the Bearer value with **SHA-256** and looks it up in `personal_access_tokens`. You must send the **plaintext** PAT, not a hash.
- The PAT is tied to a **user** and optionally a **company**. The backend sets `user_id` and `company_id` from the PAT row; you do not send company in the header for PAT auth.

---

## 7. Checklist for external connection

| Item        | What to do                                                                 |
|------------|-----------------------------------------------------------------------------|
| **Base URL** | Same as admin API (e.g. `http://localhost:9001` or `http://localhost:8080` — port depends on your setup). |
| **Auth**     | `Authorization: Bearer nvpat_<rest_of_token>`.                             |
| **Token**    | Use the **full plaintext** token (starts with `nvpat_`).                    |
| **Endpoints**| Use **data-models** auto CRUD, **POST /upload** (S3), and **GET /private-file** (signed URL or decrypted stream); avoid app-menus/auth for PAT. |
| **HTTPS**    | Use HTTPS in production; do not send PAT over plain HTTP.                  |
| **Expiry**   | Create a new PAT when it expires; list/revoke via admin or `/personal-access-tokens` with a JWT. |

---

## 8. Optional: tenant (company) context

When you **create** the PAT you can set `company_id`. The API then associates that PAT with that company. For external calls you **do not** send company in the header — the backend uses the PAT's `company_id`. To "connect as" a specific tenant, create a PAT with that tenant's `company_id` and use that PAT from outside.
