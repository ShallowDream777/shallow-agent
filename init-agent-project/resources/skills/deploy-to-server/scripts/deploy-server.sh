#!/usr/bin/env bash
# ===== Server-side deploy (Linux + Docker) =====
# Usage: bash deploy-server.sh [project root] [tar path]
# Requires: docker compose only; no node/jq (config values are passed via env from the local machine)
# Env vars (set by deploy.sh after reading deploy.config.json):
#   DEPLOY_APP_NAME    project name (defaults to dir basename)
#   DEPLOY_ENV_EXAMPLE relative path of .env template (e.g. deploy/.env.example; empty = none)
#   DEPLOY_ENV_REQUIRED space-separated required keys (empty = none required)
#   DEPLOY_PORT        public mapped port (default 3000)
#   DEPLOY_HEALTH_PATH health check path (default /api/meta)
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

APP_NAME="${DEPLOY_APP_NAME:-$(basename "${ROOT}")}"
ENV_EXAMPLE="${DEPLOY_ENV_EXAMPLE:-}"
ENV_REQUIRED="${DEPLOY_ENV_REQUIRED:-}"
PORT="${DEPLOY_PORT:-3000}"
HEALTH_PATH="${DEPLOY_HEALTH_PATH:-/api/meta}"
TAR="${2:-${ROOT}/${APP_NAME}-deploy.tar.gz}"

echo "==> [1/5] Extracting to ${ROOT} ..."
sudo mkdir -p "${ROOT}"
sudo tar -xzf "${TAR}" -C "${ROOT}"

echo "==> [2/5] Handling .env ..."
if [ ! -f .env ] && [ -n "${ENV_EXAMPLE}" ]; then
  cp "${ENV_EXAMPLE}" .env
  for KEY in ${ENV_REQUIRED}; do
    case "${KEY}" in
      *SECRET*|*TOKEN*|*KEY*)
        VAL="$(openssl rand -hex 32)"
        sed -i "s|^${KEY}=.*|${KEY}=${VAL}|" .env
        echo "  ${KEY}=<REDACTED> (randomly generated)"
        ;;
      *PASSWORD*)
        if [ -z "${!KEY:-}" ]; then
          read -r -s -p "  Set ${KEY} (empty to auto-generate): " PW; echo
          [ -z "$PW" ] && PW="$(openssl rand -hex 6)"
        else
          PW="${!KEY}"
        fi
        sed -i "s|^${KEY}=.*|${KEY}=${PW}|" .env
        echo "  ${KEY}=<REDACTED> (set)"
        ;;
    esac
  done
elif [ ! -f .env ]; then
  echo "  No envExample; skipping .env (project has no required secrets)"
else
  echo "  .env already exists; keeping existing config"
fi

echo "==> [3/5] docker compose build & up ..."
if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi
${DOCKER} compose up -d --build

echo "==> [4/5] Waiting for startup and checking status ..."
sleep 5
${DOCKER} compose ps

echo "==> [5/5] Health check (via mapped port)..."
if curl -sf -o /dev/null "http://127.0.0.1:${PORT}${HEALTH_PATH}"; then
  IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "  OK: deploy succeeded -> http://${IP:-<public-ip>}:${PORT}"
  echo "     Note: cloud servers need TCP ${PORT} opened in the console security group"
else
  echo "  FAILED health check; see logs: ${DOCKER} compose logs"
  echo "     Common causes: missing seccomp:unconfined (SQLite disk I/O error), multi-stage Dockerfile not COPYing backend sources"
fi
