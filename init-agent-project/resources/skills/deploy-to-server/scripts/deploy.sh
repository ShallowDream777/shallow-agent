#!/usr/bin/env bash
# ===== 本机一键部署：打包 → 上传 → 服务器构建启动 =====
# 用法:  bash deploy.sh [项目根目录]
# 默认:  当前目录为项目根
# 读取 deploy.config.json 的 server.user/host 作为 SSH 目标
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

# ---- 读配置 ----
if command -v node >/dev/null 2>&1; then
  USER="$(node -e "console.log(require('./deploy.config.json').server.user)")"
  HOST="$(node -e "console.log(require('./deploy.config.json').server.host)")"
  APP_NAME="$(node -e "console.log(require('./deploy.config.json').appName)")"
  TARGET="$(node -e "console.log(require('./deploy.config.json').server.targetDir)")"
else
  echo "需要 node 或 jq 读取 deploy.config.json" >&2; exit 1
fi

if [ -z "${USER}" ] || [ -z "${HOST}" ]; then
  echo "deploy.config.json 的 server.user / server.host 未配置，请先填写" >&2
  exit 1
fi

OUT="${APP_NAME}-deploy.tar.gz"
SSH_TARGET="${USER}@${HOST}"

echo "==> [1/3] 打包 ..."
bash "$(dirname "${BASH_SOURCE[0]}")/deploy-local.sh" "${ROOT}"

echo "==> [2/3] 上传 ${OUT} -> ${SSH_TARGET}:/opt/ ..."
scp -q -o ConnectTimeout=10 "${OUT}" "${SSH_TARGET}:/opt/"

echo "==> [3/3] 服务器端部署 ..."
# 把服务器端脚本一并上传（它不在项目 tar 里，因为 .agents 被排除）
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
scp -q -o ConnectTimeout=10 "${SCRIPT_DIR}/deploy-server.sh" "${SSH_TARGET}:/tmp/deploy-server.sh"
# 本机读配置（有 node），经环境变量传给远端脚本（远端无需 node/jq）
ENV_EXAMPLE="$(node -e "const c=require('./deploy.config.json'); console.log(c.envExample||'')")"
ENV_REQUIRED="$(node -e "const c=require('./deploy.config.json'); console.log((c.envRequired||[]).join(' '))")"
PORT="$(node -e "console.log(require('./deploy.config.json').server.port)")"
HEALTH_PATH="$(node -e "const c=require('./deploy.config.json'); console.log(c.healthCheckPath||'/api/meta')")"
# Git Bash 下禁用路径转换，避免远端绝对路径被改写
# 临时关闭 set -e：需捕获 ssh 退出码决定是否清理本地包
set +e
MSYS_NO_PATHCONV=1 ssh -o BatchMode=yes -o ConnectTimeout=10 "${SSH_TARGET}" \
  "sudo mkdir -p ${TARGET} && sudo tar -xzf /opt/${OUT} -C ${TARGET} && sudo DEPLOY_APP_NAME=${APP_NAME} DEPLOY_ENV_EXAMPLE='${ENV_EXAMPLE}' DEPLOY_ENV_REQUIRED='${ENV_REQUIRED}' DEPLOY_PORT=${PORT} DEPLOY_HEALTH_PATH='${HEALTH_PATH}' bash /tmp/deploy-server.sh ${TARGET} /opt/${OUT}"
SSH_OK=$?
set -e

if [ ${SSH_OK} -eq 0 ]; then
  echo "==> 部署完成，清理本地打包残留 ..."
  rm -f "${ROOT}/${OUT}"
  echo "  已删除 ${ROOT}/${OUT}"
else
  echo "==> 部署失败（exit ${SSH_OK}），保留本地 ${OUT} 便于排查"
fi
exit ${SSH_OK}
