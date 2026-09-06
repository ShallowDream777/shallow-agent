#!/usr/bin/env bash
# ===== One-command deploy from the local machine: package -> upload -> build on server =====
# Usage: bash deploy.sh [project root]
# Default: current dir as project root
# Reads server.user/host from deploy.config.json as the SSH target
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

# ---- Read config ----
if command -v node >/dev/null 2>&1; then
  USER="$(node -e "console.log(require('./deploy.config.json').server.user)")"
  HOST="$(node -e "console.log(require('./deploy.config.json').server.host)")"
  APP_NAME="$(node -e "console.log(require('./deploy.config.json').appName)")"
  TARGET="$(node -e "console.log(require('./deploy.config.json').server.targetDir)")"
else
  echo "node or jq is required to read deploy.config.json" >&2; exit 1
fi

if [ -z "${USER}" ] || [ -z "${HOST}" ]; then
  echo "server.user / server.host are not set in deploy.config.json; fill them in first" >&2
  exit 1
fi

OUT="${APP_NAME}-deploy.tar.gz"
SSH_TARGET="${USER}@${HOST}"

echo "==> [1/3] Packaging ..."
bash "$(dirname "${BASH_SOURCE[0]}")/deploy-local.sh" "${ROOT}"

echo "==> [2/3] Uploading ${OUT} -> ${SSH_TARGET}:/opt/ ..."
scp -q -o ConnectTimeout=10 "${OUT}" "${SSH_TARGET}:/opt/"

echo "==> [3/3] Server-side deploy ..."
# Upload the server script too (it is not in the project tar, .agents is excluded)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scp -q -o ConnectTimeout=10 "${SCRIPT_DIR}/deploy-server.sh" "${SSH_TARGET}:/tmp/deploy-server.sh"
# Read config locally (has node), pass values to the remote script via env (remote needs no node/jq)
ENV_EXAMPLE="$(node -e "const c=require('./deploy.config.json'); console.log(c.envExample||'')")"
ENV_REQUIRED="$(node -e "const c=require('./deploy.config.json'); console.log((c.envRequired||[]).join(' '))")"
PORT="$(node -e "console.log(require('./deploy.config.json').server.port)")"
HEALTH_PATH="$(node -e "const c=require('./deploy.config.json'); console.log(c.healthCheckPath||'/api/meta')")"
# Under Git Bash disable path conversion so remote absolute paths are not rewritten
# Temporarily disable set -e: we need ssh's exit code to decide local cleanup
set +e
MSYS_NO_PATHCONV=1 ssh -o BatchMode=yes -o ConnectTimeout=10 "${SSH_TARGET}" \
  "sudo mkdir -p ${TARGET} && sudo tar -xzf /opt/${OUT} -C ${TARGET} && sudo DEPLOY_APP_NAME=${APP_NAME} DEPLOY_ENV_EXAMPLE='${ENV_EXAMPLE}' DEPLOY_ENV_REQUIRED='${ENV_REQUIRED}' DEPLOY_PORT=${PORT} DEPLOY_HEALTH_PATH='${HEALTH_PATH}' bash /tmp/deploy-server.sh ${TARGET} /opt/${OUT}"
SSH_OK=$?
set -e

if [ ${SSH_OK} -eq 0 ]; then
  echo "==> Deploy done; cleaning up local package ..."
  rm -f "${ROOT}/${OUT}"
  echo "  deleted ${ROOT}/${OUT}"
else
  echo "==> Deploy failed (exit ${SSH_OK}); keeping local ${OUT} for debugging"
fi
exit ${SSH_OK}
