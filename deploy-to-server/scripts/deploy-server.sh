#!/usr/bin/env bash
# ===== 服务器端部署（Linux + Docker）=====
# 用法:  bash deploy-server.sh [项目根目录] [tar包路径]
# 依赖:  服务器只需 docker compose；不需要 node/jq（配置值由本机经环境变量传入）
# 环境变量（由本机 deploy.sh 读取 deploy.config.json 后设置）:
#   DEPLOY_APP_NAME    项目名（默认取目录名）
#   DEPLOY_ENV_EXAMPLE .env 模板的相对路径（如 deploy/.env.example；空 = 无）
#   DEPLOY_ENV_REQUIRED 空格分隔的必填键列表（空 = 无必填）
#   DEPLOY_PORT        对外映射端口（默认 3000）
#   DEPLOY_HEALTH_PATH 健康检查路径（默认 /api/meta）
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

APP_NAME="${DEPLOY_APP_NAME:-$(basename "${ROOT}")}"
ENV_EXAMPLE="${DEPLOY_ENV_EXAMPLE:-}"
ENV_REQUIRED="${DEPLOY_ENV_REQUIRED:-}"
PORT="${DEPLOY_PORT:-3000}"
HEALTH_PATH="${DEPLOY_HEALTH_PATH:-/api/meta}"
TAR="${2:-${ROOT}/${APP_NAME}-deploy.tar.gz}"

echo "==> [1/5] 解压到 ${ROOT} ..."
sudo mkdir -p "${ROOT}"
sudo tar -xzf "${TAR}" -C "${ROOT}"

echo "==> [2/5] 处理 .env ..."
if [ ! -f .env ] && [ -n "${ENV_EXAMPLE}" ]; then
  cp "${ENV_EXAMPLE}" .env
  for KEY in ${ENV_REQUIRED}; do
    case "${KEY}" in
      *SECRET*|*TOKEN*|*KEY*)
        VAL="$(openssl rand -hex 32)"
        sed -i "s|^${KEY}=.*|${KEY}=${VAL}|" .env
        echo "  ${KEY}=<REDACTED> (随机生成)"
        ;;
      *PASSWORD*)
        if [ -z "${!KEY:-}" ]; then
          read -r -s -p "  设置 ${KEY} (留空自动生成): " PW; echo
          [ -z "$PW" ] && PW="$(openssl rand -hex 6)"
        else
          PW="${!KEY}"
        fi
        sed -i "s|^${KEY}=.*|${KEY}=${PW}|" .env
        echo "  ${KEY}=<REDACTED> (已设置)"
        ;;
    esac
  done
elif [ ! -f .env ]; then
  echo "  无 envExample，跳过 .env（项目无必填密钥）"
else
  echo "  .env 已存在，保留现有配置"
fi

echo "==> [3/5] docker compose build & up ..."
if docker info >/dev/null 2>&1; then DOCKER="docker"; else DOCKER="sudo docker"; fi
${DOCKER} compose up -d --build

echo "==> [4/5] 等待启动并检查状态 ..."
sleep 5
${DOCKER} compose ps

echo "==> [5/5] 健康检查（经映射端口）..."
if curl -sf -o /dev/null "http://127.0.0.1:${PORT}${HEALTH_PATH}"; then
  IP="$(hostname -I 2>/dev/null | awk '{print $1}')"
  echo "  ✅ 部署成功:  http://${IP:-<公网IP>}:${PORT}"
  echo "     注意: 云服务器需在控制台安全组放行 TCP ${PORT}"
else
  echo "  ❌ 健康检查失败，查看日志: ${DOCKER} compose logs"
  echo "     常见原因: 缺少 seccomp:unconfined（SQLite disk I/O error）、多阶段 Dockerfile 未 COPY 后端源码"
fi
