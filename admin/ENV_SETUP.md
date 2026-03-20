# Environment Variables Setup

## VITE_API_URL Configuration

The `VITE_API_URL` environment variable controls how the frontend connects to the API.

### Where to Set It

Create a `.env` file in the `admin/` directory (same level as `package.json`):

```bash
cd admin
touch .env
```

Then add one of the following:

### Option 1: Direct Connection (Default)
```
VITE_API_URL=http://localhost:9001
```
- Connects directly to the API server on port 9001
- Requires CORS to be configured on the API server
- This is the default if VITE_API_URL is not set

### Option 2: Use Vite Proxy (Recommended for Development)
```
VITE_API_URL=
```
- Uses the Vite proxy configured in `vite.config.js`
- Proxies requests from `http://localhost:3000` to `http://localhost:9001`
- Avoids CORS issues
- Proxy routes: `/auth`, `/app`, `/integrations`, `/menus`

### Option 3: Production/Remote API
```
VITE_API_URL=https://api.yourdomain.com
```
- For production or remote API servers

## VITE_APP_SCOPE Configuration

Controls which scope (saas/tenant) the app operates in for theme and scope comparisons:

```
VITE_APP_SCOPE=saas
```
or
```
VITE_APP_SCOPE=tenant
```

- Default: `saas` if not set
- Used for themes and scope-aware features

## VITE_TIMEZONE and VITE_TIME_FORMAT (optional)

Display timezone and time format for timestamps in the admin UI (e.g. Schedulers page).
Defaults are read from the API `/config/display` endpoint (from `api/.env`).
To override in the admin, add to `admin/.env`:

```
VITE_TIMEZONE=Asia/Kolkata
VITE_TIME_FORMAT=h:mm A
```

- `VITE_TIMEZONE`: IANA timezone (e.g. `Asia/Kolkata` for IST)
- `VITE_TIME_FORMAT`: dayjs format for date+time (e.g. `DD/MM/YYYY h:mm A` for dd/mm/yyyy plus 12h am/pm)

## Notes

- Environment variables must start with `VITE_` to be exposed to the frontend
- The `.env` file should NOT be committed to git (add it to `.gitignore`)
- After changing `.env`, restart the dev server: `npm run dev`
- Default behavior: If `VITE_API_URL` is not set, it defaults to `http://localhost:9001`
