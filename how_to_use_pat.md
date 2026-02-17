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

## 4. How the API treats the token

- The API accepts **either** a **JWT** (session login) **or** a **PAT** only on routes that call `resolve_bearer_to_user` (e.g. data-models CRUD).
- On those routes it tries **JWT first**; if that fails, it hashes the Bearer value with **SHA-256** and looks it up in `personal_access_tokens`. You must send the **plaintext** PAT, not a hash.
- The PAT is tied to a **user** and optionally a **company**. The backend sets `user_id` and `company_id` from the PAT row; you do not send company in the header for PAT auth.

---

## 5. Checklist for external connection

| Item        | What to do                                                                 |
|------------|-----------------------------------------------------------------------------|
| **Base URL** | Same as admin API (e.g. `http://localhost:9001`).                          |
| **Auth**     | `Authorization: Bearer nvpat_<rest_of_token>`.                             |
| **Token**    | Use the **full plaintext** token (starts with `nvpat_`).                    |
| **Endpoints**| Use **data-models** auto CRUD endpoints; avoid app-menus/auth for PAT.      |
| **HTTPS**    | Use HTTPS in production; do not send PAT over plain HTTP.                  |
| **Expiry**   | Create a new PAT when it expires; list/revoke via admin or `/personal-access-tokens` with a JWT. |

---

## 6. Optional: tenant (company) context

When you **create** the PAT you can set `company_id`. The API then associates that PAT with that company. For external calls you **do not** send company in the header — the backend uses the PAT's `company_id`. To "connect as" a specific tenant, create a PAT with that tenant's `company_id` and use that PAT from outside.
