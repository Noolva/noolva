# Client instance menus

Operators define **navigation for client apps** (your iOS, Android, web, macOS, or Linux shells) in the **Noolva console** under **Developer Console → Instance menus**. That data is **not** the same as Noolva console sidebar entries in `public.menus`.

Canonical schema: [`db-structure/noolvandb_schema.sql`](../db-structure/noolvandb_schema.sql) (`instance_menus`, `instance_menu_client_config`). Apply migrations with [`db-structure/update_old_db_instance_menus.sql`](../db-structure/update_old_db_instance_menus.sql) if needed.

---

## What each app receives

For one **instance** and one **client stack** (`web`, `android`, `ios`, `macos`, `linux`), the Noolva API returns menu rows with:

| Field | Meaning |
|------|---------|
| `menu_title` | Label shown in your UI |
| `route_path` | Your app’s route, deep link, or screen id (opaque to the server) |
| `icon_key` | Optional key into your **global icons** bundle / CDN (see App Studio → Global icons) |
| `parent_id` | Parent menu row `id`, or `null` for a top-level item |
| `sort_order` | Sibling ordering (ascending) |
| `is_builtin` | Hint: shipped vs operator-defined (optional display rules) |
| `render_mode` | `web` \| `native` \| `webview` — how this stack should show the target (see below) |

**`render_mode`** comes from **Instance menus → Clients** in the console. If no row exists yet for `(menu, client_type)`, the API behaves as **enabled** with default **`web`** for `client_type=web` and **`native`** for all other stacks.

---

## Authentication and access

Same rules as offline sync: [`docs/client_offline_sync.md`](client_offline_sync.md) (**Authentication**, **Access control**).

- Header: **`Authorization: Bearer <JWT>`** or **`Bearer <PAT>`**
- If `instances.company_id` is set, the user must belong to that company (or be a super-admin). If `company_id` is null, any authenticated user who can resolve the instance may read menus (use only when you understand exposure).

---

## Noolva API endpoint

**`GET /api/instances/{instance_ref}/menus`**

- **`instance_ref`**: numeric `instance_id` or `instance_uuid` (same as manifest URLs).

**Query parameters**

| Param | Required | Description |
|--------|----------|-------------|
| `client_type` | **Yes** | `web` \| `android` \| `ios` \| `macos` \| `linux` — must match the app you are building |
| `tree` | No | `true` = response `menus` is nested (`children[]` per node). `false` (default) = flat list; you build the tree from `parent_id` |

**Example**

```http
GET /api/instances/550e8400-e29b-41d4-a716-446655440000/menus?client_type=ios
Authorization: Bearer <token>
```

**Response (shape)**

```json
{
  "instance": {
    "instance_id": 1,
    "instance_uuid": "550e8400-e29b-41d4-a716-446655440000",
    "name": "My product"
  },
  "client_type": "ios",
  "menus": [
    {
      "id": 10,
      "menu_title": "Home",
      "route_path": "/home",
      "icon_key": "home",
      "parent_id": null,
      "sort_order": 0,
      "is_builtin": true,
      "render_mode": "native",
      "client_type": "ios"
    }
  ]
}
```

With `tree=true`, each element in `menus` may include `"children": [ ... ]` (same fields except nesting). Empty `children` is `[]` for leaves.

---

## How client apps should use this

1. **After sign-in**, call the endpoint once (or refresh on a sensible interval / when the app resumes) with the **`client_type`** for that binary.
2. **Build navigation** from either:
   - **Flat** `menus`: group by `parent_id`, sort siblings by `sort_order`, or  
   - **Tree** `menus`: walk `children` in order.
3. **Interpret `render_mode`** in your shell:
   - **`native`**: push a native screen / route host in your stack (SwiftUI, Compose, Qt, etc.).
   - **`webview`**: open `route_path` (or a URL you derive from config) in an embedded web view.
   - **`web`**: for Electron/Tauri/web stacks, use your SPA router; for mobile, often still a WebView or in-app browser depending on product rules.
4. **Icons**: resolve `icon_key` using your asset pipeline (for example CDN paths under `public/global_icons/{platform}/` — see [`platforms-client-instances`](../platforms-client-instances) and global icons docs). The API does not return image bytes here.
5. **Caching**: you may cache the JSON locally; re-fetch when the user switches instance or when you implement a future “menu version” signal. Today, rely on **pull on launch** + **periodic refresh** like the offline manifest pattern in [`client_offline_sync.md`](client_offline_sync.md).

---

## Operator API (Noolva console only)

CRUD for definitions uses authenticated **Developer Console** routes under **`/api/dev-console/instances/...`** (JWT with dev roles). Client apps should **not** call those paths; use **`GET /api/instances/{ref}/menus`** above.

---

## Related

- Offline manifest and sync: [`docs/client_offline_sync.md`](client_offline_sync.md)
- Global icon keys and paths: App Studio → Global icons; repo [`platforms-client-instances`](../platforms-client-instances)
