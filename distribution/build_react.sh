#!/usr/bin/env bash
# Build the admin (Vite/React) app inside a clean Docker container and
# package the resulting dist/ as distribution/output/noolva_react_dist.zip.
#
# Usage:
#   bash distribution/build_react.sh
#
# Requirements: docker, zip on host.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ADMIN_DIR="$REPO_ROOT/admin"
OUT_DIR="$SCRIPT_DIR/output"
ZIP_NAME="noolva_react_dist.zip"

if [ ! -d "$ADMIN_DIR" ]; then
  echo "❌ admin/ folder not found at $ADMIN_DIR" >&2
  exit 1
fi

if ! command -v docker >/dev/null 2>&1; then
  echo "❌ docker is required but not installed/on PATH" >&2
  exit 1
fi

if ! command -v zip >/dev/null 2>&1; then
  echo "❌ zip is required but not installed/on PATH" >&2
  exit 1
fi

mkdir -p "$OUT_DIR"
rm -rf "$ADMIN_DIR/dist"
rm -f  "$OUT_DIR/$ZIP_NAME"

echo "🔨 Building admin (vite) inside node:24-alpine ..."
docker run --rm \
  -v "$ADMIN_DIR":/app \
  -w /app \
  node:24-alpine sh -lc "npm ci && npm run build"

if [ ! -d "$ADMIN_DIR/dist" ]; then
  echo "❌ Build did not produce $ADMIN_DIR/dist" >&2
  exit 1
fi

echo "📦 Zipping dist/ -> $OUT_DIR/$ZIP_NAME ..."
( cd "$ADMIN_DIR/dist" && zip -rq "$OUT_DIR/$ZIP_NAME" . )

echo "✅ React bundle: $OUT_DIR/$ZIP_NAME"
