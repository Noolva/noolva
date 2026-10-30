#!/usr/bin/env bash
# Convenience wrapper: builds the React admin bundle and the API binary in
# sequence. Use this when you want a full distribution drop.
#
# Usage:
#   bash distribution/build_all.sh
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/2] Building React admin bundle"
bash "$SCRIPT_DIR/build_react.sh"

echo ""
echo "==> [2/2] Building API binary"
bash "$SCRIPT_DIR/build_api.sh"

echo ""
echo "✅ All builds complete. Artifacts:"
ls -1 "$SCRIPT_DIR/output" | sed 's/^/   /'
