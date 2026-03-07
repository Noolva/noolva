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

Use the **same API base URL** as your admin (e.g. `https://api.yourdomain.com` or `http://localhost:9001`).

Send the PAT as a **Bearer** token on every request:

- **Header:** `Authorization: Bearer <your_pat_plaintext>`

**cURL example:**

```bash
curl -H "Authorization: Bearer nvpat_YOUR_TOKEN_HERE" \
  "http://localhost:9001/data-models/auto/users/records"
```

**JavaScript (fetch):**

```javascript
const response = await fetch('http://localhost:9001/data-models/auto/users/records', {
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
r = requests.get("http://localhost:9001/data-models/auto/users/records", headers=headers)
```

---

## 3. Which endpoints accept PAT?

**PAT is accepted only on routes that use Bearer resolution (JWT or PAT):**

- **Data-models CRUD (auto):** e.g. `GET/POST/PUT/DELETE /data-models/auto/<model_name>/records` — these accept PAT.
- **File upload (S3):** `POST /upload` — upload files to the default S3 bucket; accepts PAT (see §5a below).

**These endpoints accept only JWT (login session token), not PAT:**

- `/app-menus/list` — returns `{"detail":"Invalid token"}` if you send a PAT.
- Other org/auth routes (e.g. `/auth/get-user-menus`, `/auth/accounts`, etc.) — same: JWT only.

So use your PAT with **data-models** endpoints to verify it works. For example:

```bash
curl -s -H "Authorization: Bearer nvpat_YOUR_FULL_TOKEN" \
  "http://localhost:9001/data-models/auto/users/records"
```

(Replace `users` with an actual auto model name if different.)

---

## 4. Request body format (POST and PUT)

For **creating** and **updating** records, the body must wrap the field values in a **`data`** object. Field names must match the model’s fields (as in Studio).

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

## 5. List (GET) and pagination

**GET** `GET /data-models/auto/<model_name>/records`

- **Query params (optional):**
  - `limit` — max records per page (default 100, max 1000).
  - `offset` — skip N records for pagination.
  - `fields` — comma-separated field names to return (default: all model fields).

Example:

```bash
curl -s -H "Authorization: Bearer nvpat_YOUR_TOKEN" \
  "http://localhost:9001/data-models/auto/persons/records?limit=20&offset=0&fields=name,dob,notes"
```

**Summary of auto CRUD endpoints:**

| Method | Path | Purpose |
|--------|------|---------|
| GET | `/data-models/auto/<model_name>/records` | List records (supports `limit`, `offset`, `fields`) |
| POST | `/data-models/auto/<model_name>/records` | Create one record (body: `{ "data": { ... } }`) |
| PUT | `/data-models/auto/<model_name>/records/<record_id>` | Update one record (body: `{ "data": { ... } }`) |
| DELETE | `/data-models/auto/<model_name>/records/<record_id>` | Delete one record |

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
  "http://localhost:9001/upload"
```

**Python (requests):**

```python
import requests
with open("photo.jpg", "rb") as f:
    r = requests.post(
        "http://localhost:9001/upload",
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
const response = await fetch('http://localhost:9001/upload', {
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
  "http://localhost:9001/upload"
```

**Example (Python with PAT):**

```python
import requests

pat = "nvpat_YOUR_FULL_TOKEN"
base = "http://localhost:9001"

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

Use the **same base URL** as your admin API (e.g. `http://localhost:9001`). If you get "Route not found: /upload", ensure the request goes to the API server and that the upload router is registered (API restart may be required after deployment).

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
| **Endpoints**| Use **data-models** auto CRUD and **POST /upload** (S3); avoid app-menus/auth for PAT. |
| **HTTPS**    | Use HTTPS in production; do not send PAT over plain HTTP.                  |
| **Expiry**   | Create a new PAT when it expires; list/revoke via admin or `/personal-access-tokens` with a JWT. |

---

## 8. Optional: tenant (company) context

When you **create** the PAT you can set `company_id`. The API then associates that PAT with that company. For external calls you **do not** send company in the header — the backend uses the PAT's `company_id`. To "connect as" a specific tenant, create a PAT with that tenant's `company_id` and use that PAT from outside.
