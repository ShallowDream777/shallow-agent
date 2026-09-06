---
name: deploy-to-server
description: Package and deploy a **containerized Node project** (single port, backend hosts frontend) to a Linux server. Use when the user says "deploy to server / go live / ship it / put it in production" about such a project. When Dockerfile / docker-compose.yml are missing, probe the project structure and generate them (user-confirmed). If the project shape doesn't fit (non-Node, non-containerized), say this skill doesn't apply rather than force it. Project-specific values come from `deploy.config.json`; on first use ask the user and generate the config. Actual package/upload/build is done by this skill's bundled scripts (`scripts/`).
---

# Deploy to Server

## Scope (confirm first — if it doesn't fit, say "this skill doesn't apply", don't force it)

This skill fits **containerized Node projects** (single container, single port: backend serves the
frontend build; Linux + Docker Compose + SSH). Prerequisites:
- Project is **Node-based** (npm/workspaces, has package-lock.json)
- Target is a Linux server reachable by SSH/scp, with Docker + docker compose installed

**Dockerfile / docker-compose.yml are not required** — when missing, this skill probes the project
structure and generates them (step 0).

**Does not apply to** (tell the user plainly, don't force the flow): non-Node projects,
non-containerized (bare-metal systemd), k8s/PaaS, multi-container architectures. If the shape
doesn't fit, recommend containerizing first or use the matching deployment route.

Execution: this skill's `scripts/` directory holds runnable scripts (`deploy-local.sh` packages,
`deploy-server.sh` deploys server-side). They read values from config and run standalone; the agent
also executes them and checks their output.

## Config (single source)

All project-specific values come from `deploy.config.json` in the project root. **No project value
is hardcoded in this skill.**

```json
{
  "appName": "project name (tar name / server dir name)",
  "server": {
    "user": "SSH username",
    "host": "server IP or domain",
    "targetDir": "deploy dir on the server",
    "port": "public mapped port",
    "containerName": "compose service/container name (optional, defaults to appName)"
  },
  "excludes": ["paths to exclude when packaging (relative to project root)"],
  "healthCheckPath": "health check path (default /api/meta, set per project API)",
  "envExample": "path to server-side .env template (optional); skip if none",
  "envRequired": ["required .env keys on first boot"],
  "backup": { "dir": "backup dir (optional, e.g. /root/backups)", "keep": "keep count (optional, e.g. 14)" }
}
```

## Deployment gotchas (apply to every project)

- **SQLite containers need `seccomp:unconfined`**: Docker's default seccomp profile blocks the
  syscalls SQLite needs to write its DB — symptom is `disk I/O error` (container crashes at
  `PRAGMA journal_mode = WAL`). Add to `docker-compose.yml`:
  ```yaml
  security_opt:
    - seccomp:unconfined
  ```
  Without it the app keeps restarting (`Restarting (1)`). Known Node + SQLite-on-Docker trap.
- A multi-stage Dockerfile must **COPY the backend sources into a build stage** (`COPY backend
  backend`), or the runtime stage's `COPY --from=...` copies an empty dir → `Cannot find module
  '/app/backend/src/index.js'`.
- The container listens on `localhost`/its own port; **verify from the host via the mapped port**
  (the `host` side of `host:container`).
- Cloud servers (Tencent/Aliyun/…) also gate public access by a **console security group** —
  opening the system firewall is not enough; the user must open the port in the cloud console.

## Flow

### 0. Check and generate Dockerfile / docker-compose.yml

- **Already present** → verify they fit (Node single/multi-stage, `seccomp:unconfined`, single
  port, `COPY` of backend sources); if missing key bits (e.g. SQLite without seccomp), flag and
  regenerate as needed.
- **Missing** → probe the project structure and generate: run
  `node <skill dir>/scripts/gen-dockerfiles.js <project root> <host port>`.
  The script auto-detects: monorepo vs single package (workspaces, frontend+backend dirs), Node
  version (engines → fallback node:24), backend entry (main → src/index.js), frontend dir; output
  embeds the gotchas (seccomp, multi-stage COPY backend, single port).
- **After generating/changing**: show the user the Dockerfile + docker-compose.yml for **confirmation**
  (container name, port, data mount) before continuing. Ask before generating when a probe point is
  unreliable (e.g. non-standard layout).

**Completion**: Dockerfile and docker-compose.yml in place and user-confirmed; do not deploy before
confirmation.

### 1. Read or create config

- `deploy.config.json` exists → read it; all later steps use its values.
- **Missing → stop and ask the user** (don't guess): appName, server user/host/port/targetDir,
  package excludes (defaults you can suggest: node_modules, .git, *.log, .env, dist, data).
  Write the values into `deploy.config.json` (single source; every later deploy reuses it).
  Also create/keep `.env.example` (server-side env template, see step 4).

**Completion**: `deploy.config.json` in place with all needed values; missing required values asked
of the user.

### 2. Package

Run `scripts/deploy-local.sh` (produces `${appName}-deploy.tar.gz` per appName/excludes). On Windows
run the same excludes with Git Bash or PowerShell tar.

**Completion**: tar created; `tar -tzf` lists content without any excludes path.

### 3. Upload and extract

```powershell
scp "${appName}-deploy.tar.gz" "${user}@${host}:/opt/"
ssh "${user}@${host}" "sudo mkdir -p ${targetDir} && sudo tar -xzf /opt/${appName}-deploy.tar.gz -C ${targetDir}"
```

> Under Git Bash, prefix `MSYS_NO_PATHCONV=1` when an ssh command contains `/opt/...` absolute paths,
> to avoid path rewriting.

**Completion**: `ls ${targetDir}` over ssh shows the sources (Dockerfile, package.json, etc.).

### 4. Configure env vars (first time)

If there's no `.env` on the server:
- Have `envExample` → `cp ${envExample} .env`
- Handle each `envRequired` key: **randomly generated keys use `openssl rand -hex 32`**; password
  keys ask the user (or generate and tell them); refuse to keep production placeholders.
- `.env` already exists → keep it, don't overwrite.

**Completion**: `.env` exists and every `envRequired` key holds a non-placeholder value.

### 5. Build and start

```powershell
ssh "${user}@${host}" "cd ${targetDir} && docker compose up -d --build"
```

**Completion**: `docker compose ps` shows the service running (healthy/runs), **not `Restarting`**;
if Restarting, check `docker logs <container>` and debug against "Deployment gotchas" (common:
seccomp, missing module).

### 6. Verify and wrap up

```powershell
# Health check via the mapped port (host side), not container-localhost
ssh "${user}@${host}" "curl -sf http://127.0.0.1:${port}/api/meta && echo OK"
# Open the system firewall (cloud servers also need the console security group — remind the user)
ssh "${user}@${host}" "sudo ufw allow ${port}/tcp || sudo firewall-cmd --permanent --add-port=${port}/tcp && sudo firewall-cmd --reload"
```

- Report the URL: `http://${host}:${port}`; if public access fails but local works, **remind the
  user to open the cloud security group**.
- Any security wrap-up (delete demo accounts, front with HTTPS) — list it for the user.

**Completion**: health check passes via the mapped port, the port is open, the URL is reported to
the user (including the security-group reminder).
**Cleanup (required)**: after a successful deploy **delete the local `${appName}-deploy.tar.gz`**
(no packaging residue in the project root); keep it only when the deploy failed, for debugging.

## Principles

- **Values come from config, not from guessing**: any project-specific value (path/port/IP) comes
  only from `deploy.config.json`; when missing, ask — never infer.
- Server-side secrets/passwords **never appear in plaintext in the conversation** (show `<REDACTED>`
  once set).
- Redeploy (code update): skip step 4 (keep `.env`), just package → upload → `up -d --build`.
- **Backup/restore is a project-specific convention**: the skill only guarantees repeatable
  deploy/upgrade. When the user asks for backup, ask the backup dir and retention count (or use the
  `backup` optional field `{dir, keep}` in `deploy.config.json`), set up a cron that tars the data
  dir; restore = stop container → extract back into the data dir → start container. Backup dir and
  cron params are not hardcoded in the skill.
- This skill is the **reusable deployment knowledge authority**: one flow across projects; project
  differences all live in `deploy.config.json`.
