# 08 — Vault Auto login (mac Swift/CDP + Android in-app WebView)

Date: 2026-10-12
Type: pkmanager change only (react-admin + mac + android); no noolva-api change

## Behavior
- Auto login button is shown **only when a native bridge exists**:
  `window.webkit.messageHandlers.pkm` (mac) or `window.PkManagerAndroid`
  (android). Plain web builds never show it.
- Payload: `{action, handler, url, username, password, secrets}` — password
  travels only in the JS payload, never logged anywhere (no shell args, no
  stdout, no persisted files).
- Result: native side invokes `window.pkmAutoLoginResult(msg, ok)` →
  toast in the Vault page.

## Handler mapping
`login_handler_function` on `password_vault` rows selects the flow. Named
handlers (values editable by admin in DB — user will set
`helix_webv2_v3_app` on the v2/v3 rows themselves):
- `general` — generic username/password/submit form flow. **Staged login
  added (2026-10-12):** when no password field is present yet, treats the
  first visible text/email input as step 1 (e.g. uTrade/ShareIndia UCC /
  registered mobile), fills username, waits up to 20s for a Cloudflare
  Turnstile token (`cf-turnstile-response`) if the widget exists, clicks
  submit, then waits for the password field to render (SPA step 2), fills
  password and submits. Only activates when a password field is absent, so
  existing single-form sites are unaffected.
- `helix_erpv3_api_app` — Helix ERP v3 API login.
- `helix_webv3_app` — Helix web v3 login (JS: ensure inputs, set values,
  click/submit, Enter fallback).
- `helix_webv2_v3_app` — separate file, same flow as web v3 initially
  (kept separate for later tweaks).

## Cloudflare Turnstile caveat (uTrade / ShareIndia)
`utrade.shareindia.com` is an Angular app behind Cloudflare Turnstile. The
login form renders ~6s after load; step 1 = UCC text field only (no
password yet); Turnstile sits between step 1 and step 2. In a **fresh**
Chrome profile (which the mac auto-login uses — temp `--user-data-dir` each
run) the Turnstile token frequently does **not** auto-solve, and repeated
automated visits from one IP eventually cause Cloudflare to stop rendering
the form at all (bot detection). The user's own browser shows "Success!"
because it already has Cloudflare clearance. Consequence: unattended
auto-login on Turnstile-protected sites is unreliable — it may stall at the
captcha. If it consistently fails, options are a persistent Chrome profile
(to retain clearance cookies) or solving the captcha manually once.

## react-admin (`src/pages/VaultPage.jsx`)
- `NATIVE_PLATFORM` detection, `handleAutoLogin`, bridge dispatch
  (`window.webkit.messageHandlers.pkm.postMessage` /
  `window.PkManagerAndroid.autoLogin(json)`), `pkmAutoLoginResult` toast.

## mac (`pkmanager/mac-app/MacAgent/LoginHandlers/`, 8 files, build OK)
- `AutoLoginBridge` (WKScriptMessageHandler, name `pkm`) wired into
  `WebView.swift` (+ `dismantleNSView` cleanup).
- `AutoLoginService` dispatches handler name → flow.
- `ChromeSession` — Chrome CDP (JSON-RPC over WebSocket, `Runtime.evaluate`
  with `awaitPromise`, free port, explicit temp `--user-data-dir` +
  `--incognito`, retry once without incognito).
- `LoginHandlerRegistry` (`LoginContext`, `AutoLoginError`, shared
  `LoginJS` ensure/set/click/submit helpers) + 4 handler files.

## android (`pkmanager/android-app/`, compile + assembleKarandevDebug OK)
- `AutoLoginBridge.kt` — `@JavascriptInterface autoLogin(json)`, marshal to
  main thread.
- `AutoLoginOverlay.kt` — in-app WebView session with a Kotlin step engine
  (`waitHas`/`setVal`/`click`/`submitFormOf`/`pressEnter`, 4 flows) +
  result eval.
- `ReactAdminWebView.kt` — bridge injected and `onWebView` capture wired
  into both webview factories before `loadUrl`.

## Deploy
1. Rebuild pkmanager react-admin bundle.
2. Rebuild mac app (`xcodebuild … -scheme MacAgent`), distribute.
3. Build android (`./gradlew :app:assembleKarandevDebug`), install.
4. Set `login_handler_function` values on vault rows as needed.

## Verify
- Plain web: no Auto login button (bridge absent).
- mac: click → incognito Chrome opens target URL and fills/logs in; toast
  reports success/failure; Chrome temp profile is deleted on exit.
- android: click → in-app WebView overlay runs the flow; toast on result.
- API logs and app logs contain no password material.
