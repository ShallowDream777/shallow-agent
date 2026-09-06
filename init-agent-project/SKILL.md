---
name: init-agent-project
description: Initialize any project as an "agent-driven" project: copy the auto-mattpocock + deploy-to-server skills into the project's .agents/skills/, ask the tech stack, scaffold AGENTS.md / README / deploy.config.json, then hand off to auto-mattpocock's own initialization (it installs its dependency skills, configures the repo conventions, and grills what to build now). This skill only places skills and scaffold — it does not know about setup-matt-pocock-skills. Use when the user says "initialize this project / wire this project up with the agent flow / set up an agent-driven project". Reusable: the skill bundles both skills and templates, so it works on any project as-is.
---

# Init Agent Project

Turn any (new or existing) project into an "agent-driven" shape: ship it with
`auto-mattpocock` (iteration router) and `deploy-to-server` (one-click deploy), plus an
AGENTS.md / README / deploy.config.json that tell the agent this project runs on these skills.

## What it does (three steps)

1. **Install the skills**: copy `auto-mattpocock` and `deploy-to-server` from this skill's
   `resources/skills/` into the target project's `.agents/skills/` (create it if missing). **The
   copies are bundled with this skill** — re-copy to refresh them when the skills update.
2. **Ask the tech stack**: project name, conversation default language, frontend framework,
   backend framework, database, public port (a short questionnaire; no design detail — that is left
   to auto-mattpocock's grill flow later).
3. **Scaffold the guidance files**: fill the templates with the answers —
   - `AGENTS.md` (Iteration workflow → auto-mattpocock, Deployment → deploy-to-server, Tech stack)
   - `README.md` (agent-driven section + one-click deploy section + tech stack + dir map)
   - `deploy.config.json` draft (appName/port filled; server empty until first deploy asks)

## Usage

### 0. Confirm the target project

- Clarify the target project root (default: current dir). Note: **what this skill hands to other
  projects are templates; the thing being run on is the target project.**
- If the target's `.agents/skills/` already has a same-named skill → ask whether to overwrite
  (default: keep existing, only fill gaps).

### 1. Install the skills

Copy `auto-mattpocock` and `deploy-to-server` from `resources/skills/` into the target
`.agents/skills/` (keep every file in each dir: SKILL.md, agents/, scripts/, etc.).

**Completion**: both `.agents/skills/{auto-mattpocock,deploy-to-server}/SKILL.md` exist in the target.

### 2. Ask the tech stack (short questionnaire)

For each item, present **preset options to pick from** (each with a recommendation and common
choices); free-text only if the user picks "Other/custom". Accept the default when the user is fine
with it; don't chase every answer. Items with a recommended default don't need a reply — use the
default unless the user objects:

- **Project name** (free text; used for README title / deploy.config appName / AGENTS file name)
- **Conversation default language** (options: Chinese / English; default English)
- **Frontend framework** (options: Vue3+Vite / React+Next / none (backend-only) / custom)
- **Backend framework** (options: Express / Fastify / NestJS / none (frontend-only/static) / custom)
- **Database** (options: SQLite / PostgreSQL / MySQL / none / custom)
- **Public port** (options: 8080 / 3000 / 80 / custom; default 8080)

**Interaction**: present each as "options + recommended mark"; the user may pick one / say "default"
to accept the recommendation / type a value outside the options. **Not an open text box** — offer
choices first; fall back to free input only when the user declines to pick.

**Completion**: all values settled — each is either a picked preset, a user-supplied custom value, or
explicitly the default.

### 3. Scaffold the guidance files

Fill the files from `resources/templates/` with step 2's answers and write them to the target
project root. **Pick templates by the chosen language** (step 2's "conversation default language"):

- **Chinese** → `AGENTS.zh.md`, `README.zh.md` (the whole document is produced in Chinese)
- **English / other** → `AGENTS.md`, `README.md`
- `deploy.config.json` is language-neutral (shared template)

Files to write (using the language-matched templates):

- `AGENTS.md` (replace `{{language}}`, `{{techstack_lines}}`)
- `README.md` (replace `{{projectName}}`, `{{one_line_description}}`, `{{techstack_lines}}`; if the
  target already has a README, **merge rather than overwrite** — keep its original content and add
  the agent/one-click-deploy/dir-map sections)
- `deploy.config.json` (replace `{{appName}}`, `{{port}}`)

If a same-named file exists: AGENTS.md with `## Agent skills`/Iteration content → ask whether to
merge; README → merge; deploy.config.json already exists → leave it.

**Completion**: the three files are written to the target project; conflicts were put to the user.

### 4. Hand off to auto-mattpocock's initialization

The project now has the skills and scaffold. **Run `auto-mattpocock`'s initialization sequence next** —
read `auto-mattpocock/SKILL.md` and follow its Preflight section top to bottom: it installs its
mattpocock dependency skills, configures the repo's issue tracker / triage / domain conventions
(`docs/agents/`, AGENTS.md Agent skills block), then **proactively grills what the user wants to work
on now** (the user may stop there if undecided — init is complete either way).

- This skill does **not** know about setup-matt-pocock-skills or the repo-configuration details;
  those belong to auto-mattpocock. init-agent-project's job ends at placing the skills and the
  scaffold, then handing control to auto-mattpocock.
- deploy.config.json's server fields stay empty until the first deploy asks for them.

**Completion**: auto-mattpocock's Preflight ran (or the user explicitly deferred it); report what was
installed/scaffolded and that the agent is now ready for requests.

## Principles

- **Skill copies ship with this skill**: this skill is the distribution vehicle for
  auto-mattpocock + deploy-to-server — when they update, copy the new versions back into
  `resources/skills/` to keep this skill in sync.
- **Templates are editable**: they live in `resources/templates/`; tune them to taste (AGENTS
  wording, README structure). Language pairs: `AGENTS.md`/`AGENTS.zh.md` and
  `README.md`/`README.zh.md` — keep both sides in sync when editing wording.
- **Merge, don't overwrite**: when the target already has README/AGENTS.md, add content rather than
  replacing the file wholesale.
