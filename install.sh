#!/usr/bin/env bash
# ===== shallow-agent installer =====
# Copies the three skills (auto-mattpocock, deploy-to-server, init-agent-project)
# into an agent skills directory, so an agent can load them.
#
# Usage:
#   bash install.sh                 # user-level: ~/.agents/skills/  (available in every project)
#   bash install.sh -p <project>    # project-level: <project>/.agents/skills/
#   bash install.sh -d <dir>        # custom skills dir
#
# After install, tell an agent in the target context: "initialize this project".
set -euo pipefail

# Resolve repo root (dir of this script)
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

SKILLS=("auto-mattpocock" "deploy-to-server" "init-agent-project")

DEST=""
FORCE=0
while [ $# -gt 0 ]; do
  case "$1" in
    -p|--project) DEST="${2:-}/.agents/skills"; shift 2 ;;
    -d|--dir)     DEST="${2:-}"; shift 2 ;;
    -f|--force)   FORCE=1; shift ;;
    -h|--help)    sed -n '2,12p' "${BASH_SOURCE[0]}"; exit 0 ;;
    *) echo "unknown arg: $1 (see head of this script)" >&2; exit 1 ;;
  esac
done

if [ -z "${DEST}" ]; then
  DEST="${HOME}/.agents/skills"
fi

echo "==> Installing shallow-agent skills to ${DEST}"
mkdir -p "${DEST}"
for s in "${SKILLS[@]}"; do
  if [ ! -d "${REPO_ROOT}/${s}" ]; then
    echo "  SKIP ${s}: source dir missing at ${REPO_ROOT}/${s}" >&2
    continue
  fi
  if [ -d "${DEST}/${s}" ]; then
    if [ "${FORCE}" = "1" ]; then
      rm -rf "${DEST}/${s}"
      cp -r "${REPO_ROOT}/${s}" "${DEST}/${s}"
      echo "  replaced ${s}"
    else
      echo "  WARN ${s}: already exists at ${DEST}/${s} — leaving it (re-run with -f to replace)"
    fi
    continue
  fi
  cp -r "${REPO_ROOT}/${s}" "${DEST}/${s}"
  echo "  installed ${s}"
done

echo "==> Done. In your agent, tell it: \"initialize this project\" (or open a new session so the skills are discovered)."
