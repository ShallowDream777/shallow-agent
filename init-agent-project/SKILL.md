---
name: init-agent-project
description: Initialize any project as an "agent-driven" project: copy the auto-mattpocock + deploy-to-server skills into the project's .agents/skills/, ask the tech stack and record it durably (write CONTEXT.md + a stack field in deploy.config.json), scaffold a skeleton per the stack when the target is empty, write AGENTS.md / README / deploy.config.json, then run auto-mattpocock's initialization sequence (read its SKILL.md and follow it). Use when the user says "initialize this project / wire this project up with the agent flow / set up an agent-driven project". Reusable: the skill bundles both skills and templates, so it works on any project as-is.
---

# Init Agent Project

Turn any (new or existing) project into an "agent-driven" shape: ship it with
`auto-mattpocock` (iteration router) and `deploy-to-server` (one-click deploy), plus AGENTS.md /
README / deploy.config.json that tell the agent this project runs on these skills. It asks the
tech stack once, records it durably, and scaffolds the project skeleton if the target is empty.

## What it does (five steps)

1. **Install the skills**: copy `auto-mattpocock` and `deploy-to-server` from this skill's
   `resources/skills/` into the target project's `.agents/skills/` (create it if missing). **The
   copies are bundled with this skill** — re-copy to refresh them when the skills update.
2. **Ask the tech stack**: project name, conversation default language, frontend framework,
   backend framework, database, public port (a short questionnaire; no design detail — that is left
   to auto-mattpocock's grill flow later).
3. **Scaffold the project skeleton** (new empty target): create the directory structure and
   package.json per the chosen stack (step 4 builds on the stack answers; see below).
4. **Persist the stack + scaffold the guidance files**: write `CONTEXT.md` (records the stack for
   later domain work), `AGENTS.md`, `README.md`, and `deploy.config.json` (incl. a `stack` field).
5. **Run auto-mattpocock's initialization** (step 5 below): it finishes setting up the repo and
   asks what to work on.

## Usage

### Source & cleanup (when this skill was installed from a repo clone)

If this skill reached the project by cloning the shallow-agent repository (one-line install), the
clone was a temporary delivery vehicle — **it is not part of the project**. Clean it up:

- Clone into a **hidden temp dir inside the project**, e.g. `.shallow-agent-tmp/` (gitignore it),
  never straight into the project root or a real source folder.
- **After initialization completes, delete that temp clone** (`rm -rf` it). Leaving the whole
  shallow-agent repo (with `.git`) inside the project is a bug.
- This applies to both project-level and user-level installs: install the skills from the temp
  clone, then remove the clone.

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

### 3. Scaffold the project skeleton (only if the target is empty/new)

If the target project has no source yet (no frontend/backend dirs, no package.json), create a
minimal runnable skeleton that matches the chosen stack, so "initialize this project" yields a real
structure the agent can build on. Match the stack answers from step 2:

- **Node frontend + backend** (e.g. Vue3+Vite + Express): a monorepo layout with `frontend/` and
  `backend/`, root `package.json` with `workspaces`, and each package's `package.json` pinned to the
  chosen framework.
- **Backend-only / frontend-only / database-only**: the matching single-package layout.
- Keep it minimal — a directory shape plus `package.json` (name, engines, scripts, the framework
  dep). Do not over-scaffold; feature code comes later via auto-mattpocock.

**If the target already has source**, skip this step (don't impose a layout on an existing project).

**Completion**: the target has a skeleton matching the chosen stack (or it already had source and
this was skipped).

### 4. Persist the stack & scaffold the guidance files

Fill the files from `resources/templates/` with step 2's answers and write them to the target
project root. **Pick language templates by the chosen language** (step 2's "conversation default
language"):

- **Chinese** → `AGENTS.zh.md`, `README.zh.md`, `CONTEXT.zh.md`
- **English / other** → `AGENTS.md`, `README.md`, `CONTEXT.md`
- `deploy.config.json` is language-neutral (shared template)

Files to write:

- `CONTEXT.md` (records the stack + one-line description — the durable record later
  domain-modeling / grill reads; replace `{{projectName}}`, `{{one_line_description}}`,
  `{{techstack_lines}}`)
- `AGENTS.md` (replace `{{language}}`, `{{techstack_lines}}`)
- `README.md` (replace `{{projectName}}`, `{{one_line_description}}`, `{{techstack_lines}}`; if the
  target already has a README, **merge rather than overwrite**)
- `deploy.config.json` (replace `{{appName}}`, `{{port}}`, `{{frontend}}`, `{{backend}}`, `{{db}}` —
  the `stack` field records the chosen frameworks so deploy can reuse them)

If a same-named file exists: AGENTS.md with `## Agent skills`/Iteration content → ask whether to
merge; README → merge; CONTEXT.md already exists → ask whether to update the Tech stack; 
deploy.config.json already exists → leave it.

**Completion**: CONTEXT.md / AGENTS.md / README.md / deploy.config.json are written to the target
project; conflicts were put to the user.

### 5. Run auto-mattpocock's initialization

The project now has the skills, a skeleton (if new), and the recorded stack. **Run
`auto-mattpocock`'s initialization next** — read `auto-mattpocock/SKILL.md` and follow its
initialization section top to bottom. It completes the repo setup and then asks the user what to
work on (the user may stop there if undecided — the project is fully initialized either way).
deploy.config.json's server fields stay empty until the first deploy asks for them.

**Completion**: auto-mattpocock's initialization ran (or the user explicitly deferred it); report
what was installed/scaffolded and that the agent is now ready for requests.

## Principles

- **Skill copies ship with this skill**: this skill is the distribution vehicle for
  auto-mattpocock + deploy-to-server — when they update, copy the new versions back into
  `resources/skills/` to keep this skill in sync.
- **Templates are editable**: they live in `resources/templates/`; tune them to taste (AGENTS
  wording, README structure). Language pairs: `AGENTS.md`/`AGENTS.zh.md` and
  `README.md`/`README.zh.md` — keep both sides in sync when editing wording.
- **Merge, don't overwrite**: when the target already has README/AGENTS.md, add content rather than
  replacing the file wholesale.
