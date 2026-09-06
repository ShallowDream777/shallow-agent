# Contributing to shallow-agent

Rules for iterating on this repository — whether you are a human or an agent driving the change.
Read this before modifying any skill.

## Why these rules exist

`shallow-agent` ships skills that get copied into other projects and executed by agents. A change
left half-synced here ships a stale or broken skill downstream. Three copies must stay consistent:

| # | Copy | Role |
|---|---|---|
| 1 | **English master** (top-level skill dirs: `auto-mattpocock/`, `deploy-to-server/`, `init-agent-project/`) | **Authoritative.** This is what an agent loads and follows. |
| 2 | `init-agent-project/resources/skills/` bundled copies | Distribution vehicle — `init-agent-project` copies these into new projects. Must mirror the English master for `auto-mattpocock` and `deploy-to-server`. |
| 3 | `zh-cn/` Chinese mirror | **Read-only documentation.** Human-readable Chinese translations of each skill's SKILL.md and the repo README. Must follow the English master. |

## Hard rules

1. **English master is the single source of truth.** Write/design in English first. Code
   (`scripts/`, openai.yaml display names) is English-only — no mirror.
2. **Every content change to a skill's SKILL.md ships in all three copies** — English master,
   bundled copy (when the skill is bundled by `init-agent-project`), and the `zh-cn/` mirror.
   Never commit an English-only change and leave `zh-cn/` stale.
3. **`zh-cn/` is mirror-only.** Do not add Chinese-only content there that has no English master
   counterpart, and never treat it as an independent source of truth.
4. **`init-agent-project` does not bundle itself** — its own SKILL.md and `resources/templates/`
   live only in the master (no copy #2 for it). But its bundled copies of the other two skills
   (#2) must stay byte-identical to the master.
5. **Do not hardcode project values.** Project specifics belong in `deploy.config.json` (per
   project), never in a skill body.
6. **README stays a front door.** Do not duplicate skill mechanics in README — point to each
   skill's SKILL.md. Update README only for repo-level facts (install, structure, usage table).
7. **State skill boundaries by what a skill hands to whom, not by what it avoids.** Naming
   something a skill is supposed to be ignorant of (e.g. "this skill does not know about X" / "X
   is not this skill's responsibility") pulls X into that skill's context — it becomes more
   visible, not less — and breaks the seam. Express the same boundary positively: a skill that
   stops at a seam completes its own work, then says "run \<next-skill\>'s flow (read its SKILL.md
   and follow it)". It names the skill it calls next, and nothing beyond that. Quote a banned
   phrase only as a labelled counter-example alongside the positive form.

## Change checklist

After editing a skill, verify **before committing**:

```bash
# 1. English master has no stray Chinese (README's zh-cn link line is the allowed exception)
#    (edit-targeted check — grep the file you changed for CJK if it should be English)

# 2. Bundled copies match the English master (run from repo root)
diff -rq auto-mattpocock/       init-agent-project/resources/skills/auto-mattpocock/
diff -rq deploy-to-server/      init-agent-project/resources/skills/deploy-to-server/

# 3. zh-cn mirror files exist and cover the change
#    (auto-mattpocock, deploy-to-server, init-agent-project under zh-cn/)
```

If any check fails, sync the missing copy **in the same change** — do not commit a partial sync.
The intended edit sequence:

1. Edit the English master file.
2. If you changed `auto-mattpocock/` or `deploy-to-server/`: `cp -r` the changed skill over
   `init-agent-project/resources/skills/<skill>/`.
3. Update the matching `zh-cn/<skill>/SKILL.md` (or `zh-cn/README.md` for repo-level docs) to
   follow the English change. The mirror is a translation, not a paraphrase — keep sections and
   completion criteria aligned so a reader can diff them.
4. Run the checks above; commit everything together.

## Typical change kinds

- **Skill behavior** (SKILL.md flow/steps) → all three copies.
- **Scripts / templates / yaml** → English master only (templates: `resources/templates/`
  keeps `.md`/`.zh.md` pairs in sync with each other).
- **Repo docs** (README, LICENSE, this file, AGENTS.md) → README has a `zh-cn/README.md` mirror;
  keep the mirror's install/usage/iteration notes in step. `AGENTS.md` at the repo root carries the
  same sync rules so any agent editing here auto-loads them.
