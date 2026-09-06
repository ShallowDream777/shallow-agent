# AGENTS.md

## How to change this repo (read before editing any skill)

This repo ships skills that get copied into other projects. A half-synced change ships broken.
Full detail: [CONTRIBUTING.md](CONTRIBUTING.md). The short version:

- **English master is authoritative** (top-level `auto-mattpocock/`, `deploy-to-server/`,
  `init-agent-project/`). Design and write in English.
- **Three copies stay in sync per content change to a skill's SKILL.md**:
  1. English master
  2. `init-agent-project/resources/skills/<skill>/` — copy the changed skill over it when you
     changed `auto-mattpocock/` or `deploy-to-server/`
  3. `zh-cn/<skill>/SKILL.md` — the Chinese mirror follows the English change (and
     `zh-cn/README.md` for repo-level docs)
- **`zh-cn/` is read-only mirror documentation**; never treat it as a source of truth or add
  Chinese-only content.
- Code (scripts/, yaml display names) is English-only; templates keep `.md`/`.zh.md` pairs in sync.
- No hardcoded project values in skills — project specifics live in `deploy.config.json` per
  project.

Commit all three copies together; never commit an English-only change that leaves `zh-cn/` or the
bundled copies stale.
