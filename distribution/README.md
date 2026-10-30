# Noolva Distribution

Build and ship the Noolva API and React admin as deployable artifacts.

This folder contains the build scripts; the resulting artifacts land in
[`output/`](./output) (gitignored).

---

## Layout

```
distribution/
  build_react.sh              # builds admin/dist via Docker, zips to noolva_react_dist.zip
  build_api.sh                # Nuitka --module compiles api into cli.so + thin noolva.bin launcher
  build_all.sh                # convenience wrapper: runs build_react.sh then build_api.sh
  .env.example                # sample env for the target host
  config.yaml.example         # sample config.yaml for user-script wiring
  README.md                   # this file
  .gitignore                  # ignores output/

  output/                     # (gitignored) build artifacts land here
    noolva.bin                # tiny Python launcher (run via venv python)
    cli.cpython-39-x86_64-linux-gnu.so   # Nuitka-compiled core (all routes/models/etc baked in)
    requirements.txt          # copy of api/app/requirements.txt for venv setup
    assets/                   # copy of api/assets (icons, manifest)
    custom_python_scripts/    # placeholder for user job scripts
    noolva_react_dist.zip     # produced by build_react.sh
```

---

## Prerequisites

On the **build host** (your laptop / CI runner):

- Docker (Linux containers; Docker Desktop on macOS is fine)
- `bash`, `zip`, `tar`
- ~2 GB free disk for the Nuitka build cache

The build is fully containerized (`node:24-alpine` for React, `python:3.9-slim`
for the API), so you do not need Node, Python, or any system libs installed
locally beyond Docker.

---

## Build

### Everything

```bash
bash distribution/build_all.sh
```

### Just the React admin

```bash
bash distribution/build_react.sh
# -> distribution/output/noolva_react_dist.zip
```

### Just the API binary

```bash
bash distribution/build_api.sh
# -> distribution/output/noolva.bin
# -> distribution/output/cli.cpython-39-x86_64-linux-gnu.so
# -> distribution/output/requirements.txt
# -> distribution/output/assets/
```

> **Architecture note**: the API binary is built inside `python:3.9-slim`
> which produces a Linux x86_64 / Python 3.9 `.so`. The runtime venv on the
> target host **must** match (same OS, same arch, same Python version).
> Otherwise Python will refuse to import the compiled module.

---

## Deploy layout (target host)

Copy the artifacts from `distribution/output/` plus `.env.example` and
`config.yaml.example` to a directory on the target host. Recommended layout:

```
/opt/noolva/
  noolva.bin                           # Python launcher (chmod +x)
  cli.cpython-39-x86_64-linux-gnu.so   # Nuitka-compiled core
  requirements.txt
  venv/                                # created on the host (see below)
  custom_python_scripts/               # operator-supplied job scripts
  assets/
  .env                                 # copy of .env.example, filled in
  config.yaml                          # optional, copy of config.yaml.example
  logs/                                # auto-created if LOG_PATH is unset
```

### One-time setup

```bash
cd /opt/noolva

# Create the venv that will both load cli.so and run user scripts.
python3.9 -m venv venv
venv/bin/pip install --upgrade pip
venv/bin/pip install -r requirements.txt

# Make the launcher executable.
chmod +x noolva.bin

# Configure environment.
cp .env.example .env
$EDITOR .env
```

---

## Run

The launcher is a tiny Python script; you must invoke it through the venv's
Python. **Do not** try to execute `./noolva.bin` directly.

```bash
# Start the FastAPI server (replaces the dev command
#   api/app/noolva-venv/bin/python3 api/app/cli.py runserver
# ).
venv/bin/python3 noolva.bin runserver

# All other Typer subcommands work too:
venv/bin/python3 noolva.bin login
venv/bin/python3 noolva.bin validate_env
venv/bin/python3 noolva.bin --help
```

`.env` is auto-loaded via `python-dotenv` exactly as it is in development.

### Run as a systemd service (optional)

```ini
# /etc/systemd/system/noolva-api.service
[Unit]
Description=Noolva API
After=network-online.target
Wants=network-online.target

[Service]
WorkingDirectory=/opt/noolva
EnvironmentFile=/opt/noolva/.env
ExecStart=/opt/noolva/venv/bin/python3 /opt/noolva/noolva.bin runserver
Restart=on-failure
RestartSec=3
User=noolva
Group=noolva

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl daemon-reload
sudo systemctl enable --now noolva-api
sudo journalctl -u noolva-api -f
```

---

## Custom Python scripts

`custom_python_scripts/` is the slot for operator-provided job scripts. The
running API invokes them via `subprocess`, e.g.:

```python
subprocess.run([
    "venv/bin/python",
    "custom_python_scripts/nightly_report.py",
])
```

The same venv that loads `cli.so` is used to execute these scripts — so any
package they depend on must be in the venv (or in `requirements.txt` /
installed manually).

These scripts are **not** baked into the binary; you can drop in / update
them on the host at any time without rebuilding.

---

## React admin deploy

```bash
unzip noolva_react_dist.zip -d /var/www/noolva-admin
```

Then point your web server (nginx) at `/var/www/noolva-admin`. The bundle
loads `runtime-config.json` at startup; edit it on the host to set:

```json
{ "apiOrigin": "https://api.your-domain.com", "scope": "saas" }
```

If `apiOrigin` is empty, the SPA uses same-host `/api` (works when nginx
proxies `/api` to the API).

---

## Logs

Logging is centralized in [`api/app/utils/log_path.py`](../api/app/utils/log_path.py).
It writes to **one** file, rotating once per day at a configurable UTC time.

| Env var                    | Default          | Meaning                                                        |
|----------------------------|------------------|----------------------------------------------------------------|
| `LOG_PATH`                 | _(unset)_        | Full path to the active log file. Wins over `LOG_DIR`.         |
| `LOG_DIR`                  | `logs`           | Directory for `noolva.log` when `LOG_PATH` is unset.           |
| `LOG_ROTATE_TIME_UTC`      | `18:30`          | Daily rollover clock time, **UTC**, format `HH:MM` (24h).      |
| `LOG_ROTATE_BACKUP_COUNT`  | `14`             | Number of historical files to keep.                            |

Rotated files use a date suffix:

```
noolva.log              # active
noolva.log.2026-05-06   # rolled at 18:30 UTC on 2026-05-06
noolva.log.2026-05-05
...
```

Default `18:30` UTC equals `00:00` Asia/Kolkata, so daily rollovers happen at
local midnight in IST.

---

## Troubleshooting

### `cli.so` fails to import on the target host

```
ImportError: dynamic module does not define module export function
```
or
```
... cli.cpython-39-x86_64-linux-gnu.so: invalid ELF header
```

The runtime Python or OS/arch does not match the build environment. The
build container is `python:3.9-slim` (Linux x86_64). On the target host:

```bash
python3.9 --version           # must be 3.9.x
uname -m                      # must match the build container (x86_64)
```

If you need a different target (arm64, Python 3.10, etc.), rerun
`build_api.sh` after editing the Docker image / Nuitka command.

### Nuitka can't find an import at runtime

Add another `--include-package=<name>` (or `--include-module=<name>`) line in
`build_api.sh` and rebuild. Common offenders are libraries that use dynamic
imports under the hood (e.g. `firebase_admin`, `passlib` backends,
`pydantic`'s validators).

### The build is slow

First build downloads apt packages, the Python wheel cache, and Nuitka's C
compiler invocations. Subsequent builds reuse Docker layers. To speed up
local iteration, share the ccache dir via a mount (advanced).

### Build output shows a long `pip install` list each run

Expected behavior. `build_api.sh` compiles inside a clean `python:3.9-slim`
Docker container and installs `requirements.txt` there before running Nuitka.
Your local dev venv (for example `api/app/noolva-venv`) is not used by this
containerized build.

---

## What is **not** in this distribution (yet)

- The full auth/license / runtime-key flow described in
  [`api-distribution-approach`](../api-distribution-approach). The current
  build ships the binary skeleton; the licensing layer is a separate
  workstream.
- macOS / Windows / arm64 binaries. The default build is Linux x86_64. To
  produce a macOS binary, run the same Nuitka command natively on macOS
  (no Docker).
- A CI workflow. The scripts are CI-friendly but no GitHub Actions /
  Jenkins pipeline is included here.
