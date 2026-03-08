# Data Privacy & Protection in Noolva

This document describes how **row data**, **file contents**, and **credentials** are protected in Noolva. When encryption is applied, **hosting owners and storage providers (e.g. S3)** cannot read the actual content—only the application with the correct key can decrypt it.

---

## 1. Overview of Protection Layers

| What is protected        | Where it’s set                    | Who can see plain data                          | Who cannot see plain data                         |
|--------------------------|-----------------------------------|--------------------------------------------------|---------------------------------------------------|
| **Field values (DB)**    | Per-field encryption method       | App (with key); users with read permission       | DB admins, hosting; users without read permission |
| **File content (S3)**    | Per-field encryption method       | App (with key); users via API with decrypt       | S3/storage provider; direct S3 access             |
| **Which rows are visible** | Row exposure mode + user setting | Depends on `current_user_mode` and row’s mode     | Rows filtered out by exposure logic               |
| **Which fields are visible** | Field permissions (roles)       | Users whose role has READ on that field          | Others get `"AuthFailed"` for that field         |
| **Integration credentials** | Stored encrypted in DB          | App only (decrypts at runtime)                   | DB admins, hosting                                |

---

## 2. Row Data Protection

### 2.1 Field-level encryption (database columns)

- **What:** Individual fields on data models can be stored **encrypted** in the database.
- **Where to set:** **Admin → Data Models → [Model] → Fields → Encryption** (per field).
- **Options:**
  - **`none`** – stored in plain text.
  - **`xor_cipher`** – reversible obfuscation (fixed key `"noolva"`). See `api/app/utils/ENCRYPTION_SPEC.md`.
  - **`aes`** – AES-256-GCM; key from **`ENCRYPTION_KEY`** (same as credentials).
- **Behaviour:**
  - On **create/update**: API encrypts the value before writing to the DB.
  - On **read**: API decrypts only for users who have **read permission** on that field; others see `"AuthFailed"`.
  - **Hosting/DB admins** see only ciphertext in the DB; they cannot recover plain text without the key (for `aes`) or the algorithm (for `xor_cipher`).

**Technical ref:** `api/app/utils/field_encryption.py`, `api/app/routes/data_models.py` (encrypt on write, decrypt in `_apply_field_masking`).

---

### 2.2 Field-level permissions (who can read/write which fields)

- **What:** Per role and per model, each field has an **action mask** (READ=1, WRITE=2, UPDATE=4, DELETE=8).
- **Where to set:** **Roles & permissions** → field permissions for each model/field.
- **Behaviour:**
  - If the user’s role does **not** have READ on a field, the API returns **`"AuthFailed"`** for that field instead of the value (even if the row is visible).
  - **Admins** (`saas_admin`, `tenant_admin`) bypass field and row policies and see all allowed data.

**Technical ref:** `field_permissions` table; `_get_field_permission_masks`, `_apply_field_masking` in `api/app/routes/data_models.py`.

---

### 2.3 Row-level access (which rows a user can see)

- **What:** **Model row access policies** restrict which rows are returned (e.g. by `company_id`, or other scope columns).
- **Where to set:** **Admin → Data Models** (or equivalent) → row access policies for the model (scope field, source: AUTH_CONTEXT or USER).
- **Behaviour:**
  - Only rows matching the user’s context (e.g. their company) are returned; others are never sent.
  - **Admins** bypass these policies.

**Technical ref:** `model_row_access_policies` table; `_build_row_policy_where` in `api/app/routes/data_models.py`.

---

### 2.4 Row exposure mode (per-row visibility / “private” rows)

- **What:** Each row can have a **row exposure mode** (`row_exposure_mode_id`). The user can set a **Current User Mode** (e.g. “normal” or “private”). List/get only return rows that match the user’s mode (and `expose_data` in that mode).
- **Where to set:**
  - **Modes:** Table `row_exposure_modes` (e.g. name `normal`, `private`; `expose_data` true/false). Can be seeded or managed via SQL/admin.
  - **Per user:** **Settings → General → Current User Mode** (user-scoped). Options come from `row_exposure_modes`.
  - **Per model:** Models get a system field `row_exposure_mode_id` (integer FK to `row_exposure_modes`). When creating/editing records, set this to the desired mode.
- **Behaviour:**
  - If **Current User Mode** is **not** set (null): user sees **all** rows (subject to row-level access above).
  - If **Current User Mode** is set (e.g. “private”): user sees only rows where `row_exposure_mode_id` is NULL, 0, or equals their current mode, and that mode has `expose_data = true` where applicable.
  - So “private” rows can be hidden from users who are not in the matching mode; even hosting/DB admins see data only as the app serves it (and admins can bypass and see all rows via the app).

**Technical ref:** `row_exposure_modes` table; `current_user_mode` in `settings` (user-scoped); `_get_current_user_mode_id`, list/get filters in `api/app/routes/data_models.py`. API: `GET/PUT /settings` with `scope=user`, key `current_user_mode`.

---

## 3. File and Content Protection (S3 / storage)

### 3.1 Encrypted file content (storage provider cannot read)

- **What:** For **file** and **image** fields, you can set an **encryption method** (`xor_cipher` or `aes`). The **file content** (bytes) is encrypted **before** upload to S3. Only the **path** is stored in the database (plain). The object in S3 is ciphertext.
- **Where to set:** **Admin → Data Models → [Model] → Fields** → for the file/image field, set **Encryption** to `xor_cipher` or `aes`.
- **Behaviour:**
  - **Upload (POST /upload):** When `model_name` and `field_name` are provided, the API looks up the field’s `encryption_method`. If it’s `xor_cipher` or `aes`, the API encrypts the file content and uploads the **encrypted bytes** to S3. The path returned is stored in the DB.
  - **Download (direct S3 / signed URL):** If someone gets a signed URL and downloads the object, they get **encrypted bytes**—not usable without the key.
  - **Download (decrypt on delivery):** **GET /upload/private-file?path=...&decrypt=true&model_name=...&field_name=...** (with auth). The API fetches the object from S3, decrypts it with the field’s method, and **streams the decrypted content** to the client. So only the app (with key) and the authenticated user see plain content.
- **Result:** **Hosting and storage providers** only see ciphertext in S3; they cannot view the actual files without the application’s encryption key.

**Technical ref:** `api/app/routes/upload.py` (upload: `encrypt_file_content`; private-file: `decrypt=true` and `decrypt_file_content`); `api/app/utils/field_encryption.py` (`encrypt_file_content`, `decrypt_file_content`).

---

### 3.2 Private vs public storage

- **Segment:** Uploads can be **public** or **private** (e.g. `is_public=true/false`). Private objects are under a non-public path and require a **signed URL** or the **decrypt** endpoint.
- **Behaviour:** For private files, direct bucket access or public URLs do not expose content; access goes through the API (signed URL or decrypt endpoint with auth).

---

## 4. Credentials and Secrets

- **Integrations (e.g. S3):** Stored in `integrations.encrypted_credentials` as **AES-256-GCM** ciphertext. Key: **`ENCRYPTION_KEY`** (env).
- **Behaviour:** Only the application decrypts credentials at runtime to talk to S3 etc. DB or hosting admins see only ciphertext.

**Technical ref:** `api/app/utils/encryption_service.py`; `get_encryption_service()`; usage in upload and integration code.

---

## 5. Where to Configure (summary)

| Feature                 | Where to set it |
|-------------------------|-----------------|
| **Field encryption**    | Admin → Data Models → [Model] → Fields → **Encryption** (`none` / `xor_cipher` / `aes`). |
| **Field permissions**   | Roles → field permissions per model/field (READ/WRITE/UPDATE/DELETE). |
| **Row access policies** | Data model configuration → row access policies (scope field, source). |
| **Row exposure modes**  | Table `row_exposure_modes` (name, description, `expose_data`). |
| **Current User Mode**   | **Settings → General → Current User Mode** (user-scoped; options from `row_exposure_modes`). |
| **Row exposure on records** | When creating/editing a record, set `row_exposure_mode_id` (if the model has this field). |
| **File encryption**     | Same as field encryption: for file/image fields set **Encryption** to `xor_cipher` or `aes`. |
| **ENCRYPTION_KEY**      | In **`api/.env`**: 32-byte key, Base64 or raw (see `ENCRYPTION_SPEC.md`). |

---

## 6. How It Behaves (quick reference)

- **Encrypted DB field:** Stored as ciphertext; API decrypts on read for authorized users; others get `"AuthFailed"`. Hosting/DB cannot read plain value without key.
- **Encrypted file in S3:** Stored as ciphertext; API can decrypt and stream via `GET /upload/private-file?decrypt=true&model_name=...&field_name=...`. Storage provider cannot read content without key.
- **Row exposure:** With **Current User Mode** set, list/get return only rows that match the user’s mode (and policy). “Private” rows are hidden from users not in that mode.
- **Field permissions:** Users without READ on a field get `"AuthFailed"` for that field.
- **Admins:** `saas_admin` and `tenant_admin` bypass row and field policies (they can see all rows and fields the app exposes).

---

## 7. References

- **Field encryption algorithms:** `api/app/utils/ENCRYPTION_SPEC.md`
- **Encryption service:** `api/app/utils/encryption_service.py`, `api/app/utils/field_encryption.py`
- **Auto CRUD (row/field/exposure):** `api/app/routes/data_models.py`
- **Upload and private file (including decrypt):** `api/app/routes/upload.py`
- **Settings (current_user_mode):** `api/app/routes/settings.py`; `how_to_use_pat.md` for PAT/user settings
- **Schema:** `db-structure/noolvandb_schema.sql` (`data_model_fields.encryption_method`, `row_exposure_modes`, `field_permissions`, `model_row_access_policies`, `integrations.encrypted_credentials`)
