---
name: init-agent-project
description: Initialize any project as an "agent-driven" project: copy the auto-mattpocock + deploy-to-server skills into the project's .agents/skills/, resolve the tech stack (read it from README.md when already recorded, otherwise ask) and record it in README.md, scaffold a skeleton per the stack when the target is empty, write AGENTS.md / README / deploy.config.json, then run auto-mattpocock's initialization sequence (read its SKILL.md and follow it). Use when the user says "initialize this project / wire this project up with the agent flow / set up an agent-driven project". Reusable: the skill bundles both skills and templates, so it works on any project as-is.
---

# Init Agent Project

Turn any (new or existing) project into an "agent-driven" shape: ship it with
`auto-mattpocock` (iteration router) and `deploy-to-server` (one-click deploy), plus AGENTS.md /
README / deploy.config.json that tell the agent this project runs on these skills. It resolves the
tech stack — reading `README.md` when a stack is already recorded there, running a short
questionnaire otherwise — records it in `README.md` (the single durable store), and scaffolds the
project skeleton if the target is empty.

## What it does (five steps)

1. **Install the skills**: copy `auto-mattpocock` and `deploy-to-server` from this skill's
   `resources/skills/` into the target project's `.agents/skills/` (create it if missing). **The
   copies are bundled with this skill** — re-copy to refresh them when the skills update.
2. **Resolve the tech stack**: read the target's `README.md`. If it already records a stack (a `## Tech stack`
   section or a `**Tech stack**:` line), adopt it — no questionnaire. Otherwise run the short
   questionnaire (conversation language **first, asked in English**, then project name, frontend
   framework, backend framework, database, public port). No design detail — that is left to
   auto-mattpocock's grill flow later.
3. **Scaffold the project skeleton** (new empty target): create the directory structure and
   package.json per the resolved stack (step 4 builds on it; see below).
4. **Persist the stack + scaffold the guidance files**: write `README.md` (the **single durable
   record** of the tech stack — step 2 reads it back on a future run), plus `AGENTS.md` and
   `deploy.config.json`.
5. **Hand off to auto-mattpocock's initialization** (step 5 below): read `auto-mattpocock/SKILL.md`
   and follow its initialization. This skill ends at the hand-off — auto-mattpocock's own flow takes
   over from there.

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

### 2. Resolve the tech stack (read README.md, else ask)

**First read the target's `README.md`.** If it already contains a recognizable tech-stack entry (a
`## Tech stack` section or a `**Tech stack**:` bullet), adopt those answers directly — do not
re-ask. This is what makes the stack durable: re-initializing an already-initialized project picks up
the recorded stack instead of re-prompting.

If the README has no tech-stack entry (a brand-new project, or one whose README never recorded it),
run the questionnaire below. The resolved values are written into `README.md` in step 4, which makes
README the single durable record of the stack.

**Ask the conversation language first — in English** — as the very first question (options: Chinese /
English; default English). Its answer decides the language of everything after it: the rest of the
questionnaire, the questions you ask during this init run, the guidance files written in step 4, and
your reports. If the user answers Chinese, switch to Chinese for all subsequent interaction; if
English (or other), continue in English.

Then, **in that chosen language**, present each remaining item as **preset options to pick from**
(each with a recommendation and common choices); free-text only if the user picks "Other/custom".
Accept the default when the user is fine with it; don't chase every answer. Items with a recommended
default don't need a reply — use the default unless the user objects:

- **Project name** (free text; used for README title / deploy.config appName)
- **Frontend framework** (options: Vue3+Vite / React+Next / none (backend-only) / custom)
- **Backend framework** (options: Express / Fastify / NestJS / none (frontend-only/static) / custom)
- **Database** (options: SQLite / PostgreSQL / MySQL / none / custom)
- **Public port** (options: 8080 / 3000 / 80 / custom; default 8080)

**Interaction**: present each as "options + recommended mark"; the user may pick one / say "default"
to accept the recommendation / type a value outside the options. **Not an open text box** — offer
choices first; fall back to free input only when the user declines to pick.

**Completion**: the tech stack is settled — read from README, or all questionnaire values resolved
(each picked, user-supplied, or explicitly the default).

### 3. Scaffold the project skeleton (only if the target is empty/new)

If the target project has no source yet (no frontend/backend dirs, no package.json), create a
minimal runnable skeleton that matches the resolved stack from step 2, so "initialize this project"
yields a real structure the agent can build on:

- **Node frontend + backend** (e.g. Vue3+Vite + Express): a monorepo layout with `frontend/` and
  `backend/`, root `package.json` with `workspaces`, and each package's `package.json` pinned to the
  chosen framework.
- **Backend-only / frontend-only / database-only**: the matching single-package layout.
- Keep it minimal — a directory shape plus `package.json` (name, engines, scripts, the framework
  dep). Do not over-scaffold; feature code comes later via auto-mattpocock.

**If the target already has source**, skip this step (don't impose a layout on an existing project).

**Completion**: the target has a skeleton matching the resolved stack (or it already had source and
this was skipped).

### 4. Persist the stack & scaffold the guidance files

Fill the files from `resources/templates/` with step 2's resolved stack and write them to the target
project root. Pick language templates by the chosen language (step 2's "conversation default
language"):

- **Chinese** → `AGENTS.zh.md`, `README.zh.md`
- **English / other** → `AGENTS.md`, `README.md`
- `deploy.config.json` is language-neutral (shared template)

Files to write:

- `README.md` — **the single durable record of the tech stack**, and the place step 2 reads from on
  a future run. Replace `{{projectName}}`, `{{one_line_description}}`, `{{techstack_lines}}`. If the
  target already has a README, **merge** rather than overwrite: keep its original content, add the
  agent-guidance / deploy / directory sections, and set or refresh its tech-stack entry.
- `AGENTS.md` — replace `{{language}}`; agent conventions pointing at the skills.
- `deploy.config.json` — replace `{{appName}}` and `{{port}}`. No tech stack here: deploy reads the
  runtime from the project itself, not from a stack field. Server fields stay empty until the first
  deploy asks for them.

Ownership: `CONTEXT.md` is the domain glossary and belongs to the matt-pocock domain flow (glossary
only — no implementation detail). auto-mattpocock's init (step 5) and later domain-modeling create
and fill it. This step writes README / AGENTS / deploy.config.json and leaves CONTEXT.md to that
flow.

If a same-named file exists: AGENTS.md with `## Agent skills`/Iteration content → ask whether to
merge; README → merge; deploy.config.json already exists → leave it.

**Completion**: README.md / AGENTS.md / deploy.config.json are written to the target project, with
the stack recorded in README.md; conflicts were put to the user.

### 5. Hand off to auto-mattpocock's initialization

The project now has the skills, a skeleton (if new), and the stack recorded in README.md. **Start
auto-mattpocock's initialization as the final hand-off**: read `auto-mattpocock/SKILL.md` and follow
its initialization section top to bottom.

This is a **clean hand-off**, not a merge. The moment control enters auto-mattpocock's
initialization, auto-mattpocock's own flow owns everything that follows — what it installs or
configures, the questions it asks, and when it stops. Init-agent-project does not follow, judge, or
report on any of that. Its work ends at the hand-off.

**Completion**: this skill's own deliverables are in place — both skills in `.agents/skills/`, the
stack recorded in `README.md`, AGENTS.md / README / deploy.config.json written, and a skeleton
scaffolded if the target was empty — and auto-mattpocock's initialization has been handed over per
its SKILL.md.

## Principles

- **Skill copies ship with this skill**: this skill is the distribution vehicle for
  auto-mattpocock + deploy-to-server — when they update, copy the new versions back into
  `resources/skills/` to keep this skill in sync.
- **README.md is the durable stack record**: the tech stack lives only in README.md. Step 2 reads
  it back, so re-runs don't re-ask. Don't add parallel copies in deploy.config.json or CONTEXT.md.
- **Templates are editable**: they live in `resources/templates/`; tune them to taste (AGENTS
  wording, README structure). Language pairs: `AGENTS.md`/`AGENTS.zh.md` and
  `README.md`/`README.zh.md` — keep both sides in sync when editing wording.
- **Merge, don't overwrite**: when the target already has README/AGENTS.md, add content rather than
  replacing the file wholesale.
