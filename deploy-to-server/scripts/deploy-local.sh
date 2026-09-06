#!/usr/bin/env bash
# ===== Package the project into a deploy tar (reads deploy.config.json) =====
# Usage: bash deploy-local.sh [project root]
# Default: current dir as project root
# Output: <appName>-deploy.tar.gz (in the project root)
# Requires: node to parse the JSON config (or jq)
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

# ---- Read config (node preferred, jq fallback) ----
if command -v node >/dev/null 2>&1; then
  APP_NAME="$(node -e "console.log(require('./deploy.config.json').appName)")"
  EXCLUDES="$(node -e "
    const c = require('./deploy.config.json');
    console.log((c.excludes || []).join('\n'));
  ")"
elif command -v jq >/dev/null 2>&1; then
  APP_NAME="$(jq -r .appName deploy.config.json)"
  EXCLUDES="$(jq -r '.excludes[]' deploy.config.json)"
else
  echo "node or jq is required to read deploy.config.json" >&2; exit 1
fi

OUT="${APP_NAME}-deploy.tar.gz"

echo "==> [1/2] Packaging -> ${OUT} (appName=${APP_NAME}) ..."
# Write to a temp file first so tar never scans its own output
TMP_OUT="$(mktemp)"
TAR_ARGS=(-czf "${TMP_OUT}")
while IFS= read -r e; do
  [ -n "$e" ] && TAR_ARGS+=(--exclude="$e")
done <<< "${EXCLUDES}"
TAR_ARGS+=(--exclude="${OUT}")   # avoid self-inclusion
TAR_ARGS+=(.)
tar "${TAR_ARGS[@]}"
mv "${TMP_OUT}" "${OUT}"
echo "      size: $(du -h "${OUT}" | cut -f1)"

echo "==> [2/2] Done. Upload with:"
echo "      scp ${OUT} root@<server-ip>:/opt/"
echo "      Server side: extract, then run deploy-server.sh (see the deploy-to-server skill)"
