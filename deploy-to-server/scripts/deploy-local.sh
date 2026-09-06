#!/usr/bin/env bash
# ===== 打包项目为部署 tar（读 deploy.config.json）=====
# 用法:  bash deploy-local.sh [项目根目录]
# 默认:  当前目录为项目根
# 产出:  <appName>-deploy.tar.gz（在项目根目录）
# 依赖:  node 仅用于解析 JSON 配置（jq 或 node 二选一）
set -euo pipefail

ROOT="${1:-$(pwd)}"
cd "${ROOT}"

# ---- 读配置（优先 node，其次 jq）----
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
  echo "需要 node 或 jq 读取 deploy.config.json" >&2; exit 1
fi

OUT="${APP_NAME}-deploy.tar.gz"

echo "==> [1/2] 打包 -> ${OUT} (appName=${APP_NAME}) ..."
# 先写临时目录，避免 tar 扫到输出文件自身
TMP_OUT="$(mktemp)"
TAR_ARGS=(-czf "${TMP_OUT}")
while IFS= read -r e; do
  [ -n "$e" ] && TAR_ARGS+=(--exclude="$e")
done <<< "${EXCLUDES}"
TAR_ARGS+=(--exclude="${OUT}")   # 防自包含
TAR_ARGS+=(.)
tar "${TAR_ARGS[@]}"
mv "${TMP_OUT}" "${OUT}"
echo "      包大小: $(du -h "${OUT}" | cut -f1)"

echo "==> [2/2] 完成。上传命令:"
echo "      scp ${OUT} root@<服务器IP>:/opt/"
echo "      服务器端: 解压 + bash deploy-server.sh（见 deploy-to-server 技能）"
