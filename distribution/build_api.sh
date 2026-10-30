#!/usr/bin/env bash
# Build the Noolva API as a Nuitka-compiled Python module (.so) plus a
# tiny Python launcher named noolva.bin.
#
# Strategy: Nuitka --module compiles api/app/cli.py into a single
# cli.cpython-39-*.so with all local packages baked in (routes, models,
# middlewares, classes, errors, utils, jobs, tables, main, ws_connections).
# Third-party deps stay in the runtime venv (per requirements.txt).
#
# Runtime invocation on the target host:
#   venv/bin/python3 noolva.bin runserver
#   venv/bin/python3 noolva.bin login
#   venv/bin/python3 noolva.bin validate_env
#
# Usage:
#   bash distribution/build_api.sh
#
# Requirements: docker on host. Output is Linux x86_64 / Python 3.9 specific;
# the runtime venv must match (python3.9, same OS/arch).
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
APP_DIR="$REPO_ROOT/api/app"
ASSETS_DIR="$REPO_ROOT/api/assets"
OUT_DIR="$SCRIPT_DIR/output"

if [ ! -d "$APP_DIR" ]; then
  echo "❌ api/app folder not found at $APP_DIR" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker is required but not installed/on PATH" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"

# Clean previous artifacts (but keep custom_python_scripts/ and any zip
# produced by build_react.sh).
rm -f  "$OUT_DIR"/cli.cpython-*.so "$OUT_DIR"/cli.so "$OUT_DIR"/noolva.bin
rm -f  "$OUT_DIR/requirements.txt"
rm -rf "$OUT_DIR/assets"

echo "🔨 Compiling api/app/cli.py with Nuitka --module inside python:3.9-slim ..."
docker run --rm \
  -v "$APP_DIR":/src:ro \
  -v "$ASSETS_DIR":/assets:ro \
  -v "$OUT_DIR":/out \
  -w /work \
  python:3.9-slim bash -lc '
    set -e
    cp -r /src/. /work/
    # Avoid bundling the dev venv into the build context.
    rm -rf /work/noolva-venv /work/__pycache__ || true
    apt-get update
    apt-get install -y --no-install-recommends \
      build-essential patchelf ccache zip libpq-dev
    rm -rf /var/lib/apt/lists/*
    pip install --no-cache-dir --upgrade pip
    pip install --no-cache-dir nuitka
    pip install --no-cache-dir -r requirements.txt
    # In module mode, avoid broad import following. Keep includes explicit
    # (or use targeted --follow-import-to=... entries if needed).
    python -m nuitka --module cli.py \
      --include-package=routes \
      --include-package=models \
      --include-package=middlewares \
      --include-package=classes \
      --include-package=errors \
      --include-package=utils \
      --include-package=jobs \
      --include-package=tables \
      --include-module=main \
      --include-module=ws_connections \
      --lto=yes \
      --remove-output \
      --plugin-enable=anti-bloat \
      --output-dir=/out
    cp /src/requirements.txt /out/requirements.txt
    cp -r /assets /out/assets
  '

# Write the launcher script. Using a quoted heredoc so the body is not
# interpolated by the outer shell.
cat > "$OUT_DIR/noolva.bin" <<'PY_EOF'
#!/usr/bin/env python3
"""Noolva API launcher.

Run via the bundled venv (do NOT execute directly):

    venv/bin/python3 noolva.bin runserver
    venv/bin/python3 noolva.bin login
    venv/bin/python3 noolva.bin validate_env

This file is a thin Python script; the real implementation lives in the
Nuitka-compiled ``cli.cpython-*.so`` next to it.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
os.chdir(HERE)

from cli import cli  # noqa: E402  (imports compiled cli.so)

if __name__ == "__main__":
    cli()
PY_EOF
chmod +x "$OUT_DIR/noolva.bin"

echo "✅ API binary built:"
echo "   $OUT_DIR/noolva.bin"
ls -1 "$OUT_DIR"/cli.cpython-*.so 2>/dev/null | sed 's/^/   /'
echo ""
echo "Run on target host with:"
echo "   venv/bin/python3 noolva.bin runserver"
