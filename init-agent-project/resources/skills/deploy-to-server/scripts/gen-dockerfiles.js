#!/usr/bin/env node
/**
 * 生成 Dockerfile + docker-compose.yml（适配项目实际结构）
 * 用法: node gen-dockerfiles.js [项目根目录]
 *
 * 探测：
 *  - 单仓（workspaces / frontend+backend 目录）vs 单包
 *  - Node 版本（package.json engines.node，回退 node:24）
 *  - 后端入口（backend/package.json main，回退 src/index.js）
 *  - 前端目录（frontend/ 存在则构建它）
 *  - SQLite/持久化目录（默认 backend/data，可被 deploy.config.json 的 excludes 暗示）
 *
 * 生成内容内置本项目已验证的硬知识：
 *  - 多阶段 Dockerfile 必须 COPY 后端源码到任一阶段
 *  - compose 必须 seccomp:unconfined（SQLite 写库）
 *  - 单端口（后端托管前端产物）
 * 生成后不自动采用——由调用方展示给用户确认。
 */
import fs from "node:fs";
import path from "node:path";

const root = path.resolve(process.argv[2] || ".");
const readJson = (p) => {
  try {
    return JSON.parse(fs.readFileSync(path.join(root, p), "utf8"));
  } catch {
    return null;
  }
};

// ---- 探测 ----
const rootPkg = readJson("package.json") || {};
const backendPkg = readJson("backend/package.json");
const hasFrontendDir = fs.existsSync(path.join(root, "frontend"));
const hasBackendDir = fs.existsSync(path.join(root, "backend"));
const workspaces = Array.isArray(rootPkg.workspaces) || (rootPkg.workspaces && !Array.isArray(rootPkg.workspaces) && rootPkg.workspaces.packages)
  ? (Array.isArray(rootPkg.workspaces) ? rootPkg.workspaces : rootPkg.workspaces.packages)
  : [];
const isMonorepo = hasBackendDir || workspaces.length > 0;

// Node 版本：engines.node 的 >=x.y 取 x，回退 24
const nodeEngines = (rootPkg.engines?.node || backendPkg?.engines?.node || "");
const nodeMajor = (nodeEngines.match(/(\d+)\./) || [])[1] || "24";
const nodeImage = `node:${nodeMajor}-alpine`;

// 后端入口：backend/package.json main 或 src/index.js（单包则根 package main）
const backendMain = backendPkg?.main || "src/index.js";
const singlePkgMain = rootPkg.main || "src/index.js";

// ---- 拼装 Dockerfile ----
// 双仓（frontend/ + backend/）用 npm workspaces 多阶段；
// 单包含 frontend 目录用 frontend 子目录构建；纯单包则没有前端构建阶段。
function dockerfile() {
  const lines = [
    "# syntax=docker/dockerfile:1",
    "# 由 deploy-to-server 技能生成——按项目结构探测，请审阅后使用。"
  ];
  if (hasFrontendDir) {
    lines.push(
      "",
      "# ---------- Stage 1: build the frontend ----------",
      `FROM ${nodeImage} AS frontend-build`,
      "WORKDIR /app",
      "COPY package.json package-lock.json ./",
      isMonorepo ? "COPY frontend/package.json frontend/package.json" : "",
      isMonorepo ? "COPY backend/package.json backend/package.json" : "",
      "RUN npm ci --workspaces --include-workspace-root=false --no-audit --no-fund",
      "COPY frontend frontend",
      "RUN npm run build -w frontend",
      // 关键硬知识：后端源码必须带过 stage（否则 runtime COPY 空目录）
      isMonorepo ? "COPY backend backend" : "",
      "RUN npm prune --omit=dev --no-audit --no-fund",
      "",
      "# ---------- Stage 2: production runtime ----------",
      `FROM ${nodeImage} AS runtime`,
      "ENV NODE_ENV=production",
      "WORKDIR /app",
      isMonorepo ? "COPY --from=frontend-build /app/backend ./backend" : "COPY . .",
      "COPY --from=frontend-build /app/frontend/dist ./frontend/dist",
      isMonorepo ? "COPY --from=frontend-build /app/node_modules ./node_modules" : "",
      `ENV DB_PATH=/data/app.db`,
      `ENV PORT=3000`,
      "EXPOSE 3000",
      `CMD ["node", "${isMonorepo ? "backend/" : ""}${backendMain}"]`
    );
  } else {
    // 纯后端单包：无前端构建
    lines.push(
      "",
      `FROM ${nodeImage}`,
      "WORKDIR /app",
      "COPY package.json package-lock.json ./",
      "RUN npm ci --omit=dev --no-audit --no-fund",
      "COPY . .",
      "ENV DB_PATH=/data/app.db",
      "ENV PORT=3000",
      "EXPOSE 3000",
      `CMD ["node", "${singlePkgMain}"]`
    );
  }
  return lines.filter((l) => l !== "").join("\n") + "\n";
}

// ---- 拼装 compose ----
function compose(hostPort) {
  return `# 由 deploy-to-server 技能生成——按项目结构探测，请审阅后使用。
services:
  app:
    build:
      context: .
      dockerfile: Dockerfile
    image: ${rootPkg.name || "app"}:latest
    container_name: ${rootPkg.name || "app"}
    restart: unless-stopped
    # Required: default seccomp blocks SQLite write syscalls (disk I/O error).
    security_opt:
      - seccomp:unconfined
    ports:
      # host:container — host side is ${hostPort}
      - "${hostPort}:3000"
    environment:
      - DB_PATH=/data/app.db
      - PORT=3000
    volumes:
      # SQLite lives on the host; survives rebuilds, backup via host cron+tar.
      - ./data:/data
`;
}

const hostPort = process.argv[3] || "8080";
fs.writeFileSync(path.join(root, "Dockerfile"), dockerfile());
fs.writeFileSync(path.join(root, "docker-compose.yml"), compose(hostPort));
console.log(`Generated for: ${isMonorepo ? "monorepo (frontend+backend)" : "single-package"} | node:${nodeImage} | host port:${hostPort}`);
console.log("  Dockerfile, docker-compose.yml written. Review before use.");
