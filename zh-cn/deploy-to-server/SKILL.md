---
name: deploy-to-server
description: 把**容器化的 Node 项目**（单端口、后端托管前端）打包并部署到 Linux 服务器。当用户对这类项目说"部署到服务器 / 上线 / 发到生产"时使用；Dockerfile / docker-compose.yml 缺失时探测项目结构并生成（经用户确认）。若项目形态不符（非 Node、非容器化），说明本技能不适用而非硬套。项目特定值从 `deploy.config.json` 读取；首次使用先询问用户并生成配置。实际打包/上传/构建由本技能附属脚本执行（`scripts/` 目录）。
---

# Deploy to Server

## 适用范围（先确认，不符合就说"本技能不适用"，不硬套）

本技能适配**容器化 Node 项目**（单容器单端口：后端托管前端构建产物；Linux + Docker Compose + SSH）。
前提：
- 项目是 **Node 系**（npm/workspaces，含 package-lock.json）
- 目标服务器可由 SSH/scp 访问，装了 Docker + docker compose

**Dockerfile / docker-compose.yml 不要求项目自带**——缺失时本技能探测项目结构并生成（见第 0 步）。

**不适用的场景**（明确告诉用户，不硬套流程）：非 Node 项目、非容器化（裸机 systemd）、
k8s/PaaS、多容器编排架构。形态不符时建议先 Docker 化改造，或换用匹配的部署方式。

执行方式：本技能的 `scripts/` 目录含可执行脚本（`deploy-local.sh` 打包、`deploy-server.sh`
服务器端部署）。它们从配置读值、可独立运行；agent 也按它们执行并核对其输出。

## 配置（单一来源）

所有项目特定值都从项目根的 `deploy.config.json` 读取。**本技能内不写死任何项目值。**

```json
{
  "appName": "项目名（tar 包名 / 服务器目录名）",
  "server": {
    "user": "SSH 用户名",
    "host": "服务器 IP 或域名",
    "targetDir": "服务器上的部署目录",
    "port": "对外映射端口",
    "containerName": "compose 服务/容器名（可选，默认取 appName）"
  },
  "excludes": ["打包时排除的路径（相对项目根）"],
  "healthCheckPath": "健康检查路径（默认 /api/meta，按项目实际 API 配置）",
  "envExample": "服务器端 .env 模板路径（可选）；无则跳过",
  "envRequired": ["首次启动必填的 .env 键"],
  "backup": { "dir": "备份目录（可选，如 /root/backups）", "keep": "保留份数（可选，如 14）" }
}
```

## 部署硬知识（所有项目通用）

- **SQLite 容器必须 `seccomp:unconfined`**：Docker 默认 seccomp profile 会拦截 SQLite 写库所需的
  系统调用——症状是 `disk I/O error`（容器在 `PRAGMA journal_mode = WAL` 处崩溃）。在
  `docker-compose.yml` 加：
  ```yaml
  security_opt:
    - seccomp:unconfined
  ```
  不加则应用持续重启（`Restarting (1)`）。Node + SQLite 在 Docker 里的既定坑。
- 多阶段 Dockerfile 必须把**后端源码 COPY 进任一构建阶段**（`COPY backend backend`），否则
  运行时阶段 `COPY --from=...` 拷到空目录 → `Cannot find module '/app/backend/src/index.js'`。
- 容器监听 `localhost`/自身端口，**宿主机验证要走映射端口**（`host:container` 的 host 侧）。
- 云服务器（腾讯云/阿里云等）公网访问还受**控制台安全组**限制——只开系统防火墙不够，
  需用户在云控制台放行端口。

## 流程

### 0. 检查并生成 Dockerfile / docker-compose.yml

- **已存在** → 核对形态符合（Node 单/多阶段、`seccomp:unconfined`、单端口、`COPY` 后端源码）；
  缺关键项（如 SQLite 却无 seccomp）→ 提示并按需重新生成。
- **缺失** → 探测项目结构后生成：运行
  `node <skill目录>/scripts/gen-dockerfiles.js <项目根> <host端口>`。
  脚本自动探测：单仓 vs 单包（workspaces、frontend+backend 目录）、Node 版本（engines → 回退
  node:24）、后端入口（main → src/index.js）、前端目录；产物内置硬知识（seccomp、多阶段
  COPY 后端、单端口）。
- **生成/改动后**：把 Dockerfile + docker-compose.yml 展示给用户**确认**（容器名、端口、
  数据挂载）再继续。探测点不可靠时（如非标准布局）生成前先问用户。

**完成判据**：Dockerfile 与 docker-compose.yml 就位且用户已确认；未确认不进入部署。

### 1. 读取或建立配置

- `deploy.config.json` 存在 → 读取，所有后续步骤用其值。
- **缺失 → 停下来问用户**（不猜）：appName、服务器 user/host/端口/目标目录、打包排除项
  （可给默认建议：node_modules、.git、*.log、.env、dist、data）。把值写进 `deploy.config.json`
  （单一来源，之后每次部署复用）。同时生成/保留 `.env.example`（服务器端 env 模板，见步骤 4）。

**完成判据**：`deploy.config.json` 就位且含全部所需值；缺失必填项已问用户补齐。

### 2. 打包

运行 `scripts/deploy-local.sh`（按 appName/excludes 生成 `${appName}-deploy.tar.gz`）。
Windows 下用 Git Bash 或 PowerShell 的 tar 执行同一套排除参数。

**完成判据**：tar 包生成；`tar -tzf` 能列出内容且不含任何 excludes 路径。

### 3. 上传并解压

```powershell
scp "${appName}-deploy.tar.gz" "${user}@${host}:/opt/"
ssh "${user}@${host}" "sudo mkdir -p ${targetDir} && sudo tar -xzf /opt/${appName}-deploy.tar.gz -C ${targetDir}"
```

> Git Bash 下 ssh 命令含 `/opt/...` 绝对路径时，加 `MSYS_NO_PATHCONV=1` 前缀避免路径转换。

**完成判据**：ssh 到服务器 `ls ${targetDir}` 能看到源码（Dockerfile、package.json 等）。

### 4. 配置环境变量（首次）

服务器上若无 `.env`：
- 有 `envExample` → `cp ${envExample} .env`
- 逐个处理 `envRequired` 键：**随机生成的键用 `openssl rand -hex 32`**；密码类问用户
  （或生成后告知）；生产占位值拒绝保留。
- `.env` 已存在 → 保留，不覆盖。

**完成判据**：`.env` 存在且每个 `envRequired` 键都是非占位值。

### 5. 构建并启动

```powershell
ssh "${user}@${host}" "cd ${targetDir} && docker compose up -d --build"
```

**完成判据**：`docker compose ps` 显示服务运行（healthy/runs），**不是 `Restarting`**；
若 Restarting，查 `docker logs <container>` 并按"部署硬知识"排查（常见：seccomp、模块缺失）。

### 6. 验证与收尾

```powershell
# 健康检查走映射端口（host 侧），不走容器内 localhost
ssh "${user}@${host}" "curl -sf http://127.0.0.1:${port}/api/meta && echo OK"
# 开系统防火墙（云服务器还需控制台安全组放行——提醒用户）
ssh "${user}@${host}" "sudo ufw allow ${port}/tcp || sudo firewall-cmd --permanent --add-port=${port}/tcp && sudo firewall-cmd --reload"
```

- 报告访问地址：`http://${host}:${port}`；公网不通但本机通时，**提醒用户放行云安全组**。
- 任何安全收尾（删 demo 账号、前置 HTTPS）——逐条列给用户。

**完成判据**：健康检查经映射端口通过、端口已放行、访问地址已报告（含安全组提醒）。
**收尾（必须）**：部署成功后**删除本地 `${appName}-deploy.tar.gz`**（打包残留不留在项目根）；
仅部署失败时保留该包便于排查。

## 原则

- **值来自配置，不来自猜测**：任何项目特定值（路径/端口/IP）只用 `deploy.config.json` 里的，
  缺失就问，不推断。
- 服务器端密钥/密码**永不出现在对话明文**（设置后显示 `<REDACTED>`）。
- 二次部署（代码更新）：跳过步骤 4（保留 .env），直接打包 → 上传 → `up -d --build`。
- **备份/恢复是项目特有约定**：技能只保证部署/升级可重复。用户要备份时，问备份目录与保留份数
  （或用 `deploy.config.json` 可选字段 `backup`：`{dir, keep}`），在服务器配 cron 定时打包数据
  目录；恢复 = 停容器 → 解包回数据目录 → 起容器。备份目录与 cron 参数不写死在技能里。
- 本技能是**可复用的部署知识权威**：跨项目同一套流程，项目差异全在 `deploy.config.json`。
