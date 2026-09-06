---
name: auto-mattpocock
description: Makes the Matt-Pocock engineering workflow the project's default iteration mode — portable and self-initializing. Its initialization sequence (install dependency skills → run setup-matt-pocock-skills to configure the repo → proactively grill what to build now, stop allowed) is the project's init entry point and can be invoked by other skills (e.g. init-agent-project). After init, every request in conversation (feature, change, bug, design decision) is routed to the matching engineering skill, producing spec + tickets; unclear requests auto-grill again. Developers never need to remember skill names.
---

# Auto Matt-Pocock

Makes the Matt-Pocock engineering workflow (clarify → spec → tickets → implement → review) the
project's default iteration mode. This skill is a **portable router**: it only decides the stage;
the actual flows are executed by engineering skills it discovers/installs. **Out of the box**: drop
it into any project's skills dir (or user-level), first run installs its dependencies.

## Preflight: initialization (check every run)

Dependency engineering skills (table below) may not be installed — especially on a new project or a
user-level install. **Every run, first check they are discoverable; install what's missing, then do
stage routing.**

### Dependency list

| Dependency skill | Needed for |
| --- | --- |
| grill-with-docs | Stage A design clarification |
| to-spec | Stage B/D spec |
| to-tickets | Stage C/D tickets |
| implement | Stage C implementation |
| code-review | Post-implementation review |
| diagnosing-bugs | Stage E hard bugs |
| tdd | optional inside implement |
| setup-matt-pocock-skills | produce AGENTS.md / docs conventions |

### Check & install

**How to tell a dependency is discoverable**: a `<name>/SKILL.md` exists in a sibling skills
directory at this skill's own level (e.g. `.agents/skills/` or a user-level `skills/` dir), or is
findable in the known skill roots below. Anything missing goes on the install list. Confirm with
glob or directory listing (e.g. search `**/to-spec/SKILL.md`, `**/to-tickets/SKILL.md`).

**Where to install**: **follow this skill's own level** — this skill in a project skills dir (e.g.
`X/.agents/skills/`) → install dependencies project-level; in a user-level dir (e.g.
`~/.agents/skills/`) → install user-level. **No hardcoded project path, no cached install command.**

**How to install (defer to the official README, never hardcode the command)**: mattpocock/skills'
install route evolves (currently several: skills CLI, Claude Code plugin, …). **Before installing,
read the official README's Installation section** (`https://github.com/mattpocock/skills` — fetch the
raw README at `https://raw.githubusercontent.com/mattpocock/skills/main/README.md`) and follow its
**latest recommended route for the current agent/situation**. Then:

- If the route fetches the mattpocock/skills repo (clone/download) to read and install from it,
  **stage that fetch in a hidden temp dir inside the project**, e.g. `.mattpocock-tmp/` (gitignore
  it) — never in the project root or a real source folder. **Delete it after the install**
  (`rm -rf`). Do not leave the mattpocock repo behind.
- Make sure the install covers **every skill in the dependency list** (however it installs, all 8
  skills including setup-matt-pocock-skills must be available)
- If the official route is interactive (e.g. skills CLI asking which skills/agents), drive it with
  its non-interactive flags or programmatic answers — do not stall on prompts
- Keep the official tool's install tracking (e.g. skills CLI's `skills-lock.json`) intact; do not
  bypass it by hand-writing files
- User-level installs use the official route's global/user switch (e.g. skills CLI `-g`)

**If the official source is unreachable**: tell the user "auto-mattpocock needs network access to
install dependency skills per the official README"; do not improvise.

**Known skill roots** (scan all when locating a dependency): this skill's sibling skills dir,
project `.agents/skills/`, project `.dsh/skills/`, user `~/.agents/skills/`, `~/.dsh/skills/`.

### Step 2: run repo configuration (setup-matt-pocock-skills)

**Installing the skills is not configuring the repo.** After setup-matt-pocock-skills is installed,
run its configuration flow once — otherwise `.scratch/`, `docs/agents/` (issue-tracker/triage/domain
files), and AGENTS.md's Agent skills block don't exist, and to-spec/to-tickets have nowhere to land.

**When to run**: the first time this skill fires in a project directory **and** probing shows the
repo is unconfigured (no `docs/agents/issue-tracker.md`, no `## Agent skills` block in
`AGENTS.md`/`CLAUDE.md`). If those exist, skip (don't reconfigure).

**How to run**: follow `setup-matt-pocock-skills/SKILL.md`'s flow — it probes the repo itself and
asks the user section by section (issue tracker choice / triage labels / domain layout), then writes
the three `docs/agents/` files and AGENTS.md's Agent skills block. **It is prompt-driven and needs a
few user answers** — do not skip its questions and write directly.

**Completion**: `docs/agents/issue-tracker.md` exists (or the user explicitly chose a tracker type);
`AGENTS.md`/`CLAUDE.md` has an `## Agent skills` block; `CONTEXT.md` conventions in place.

### Step 3: kick off with a grill (ask what to build now)

The repo is now configured and usable. **Proactively ask what the user wants to work on right now** —
open with a design-clarification grill (stage A's grill-with-docs), not a silence that waits for a
request. The user may stop here if they haven't decided yet ("nothing yet / just setting up"); that is
fine — initialization is complete either way. Later, whenever the user brings a request, this skill
re-runs the normal stage routing (stage A automatically grills again if the request is unclear).

**How**: the whole Preflight sequence above (check → install → setup → grill) **is the initialization
entry point of this skill.** Other skills may call it by reading this SKILL.md and following the
Preflight section top to bottom — they do not need to know setup-matt-pocock-skills exists.
`init-agent-project` does exactly this after placing the skills.

## How to execute skills

Most dependency engineering skills are user-invoked (`disable-model-invocation: true`); the model
cannot fire them through the Skill tool. **Workaround: read the target skill's SKILL.md file with the
read tool and follow its instructions.** Locate it by searching the known skill roots for
`<name>/SKILL.md`; use the first hit (installed at this skill's level wins).

**This skill only routes; it does not duplicate skill content.** The target SKILL.md is authoritative.

## Stage routing

### A. Design / planning
**Trigger**: major change, large new feature, unclear requirements, design decisions or direction
questions (stack choice, domain concepts, architecture trade-offs).
**Execute**: read grill-with-docs' SKILL.md and follow it → produce/update `CONTEXT.md` terms and
`docs/adr/` decisions.
**Completion**: design tree walked (no open branches), terms recorded. Then proceed to B.

### B. Spec stage
**Trigger**: requirements are clear; the discussion should be frozen into a spec.
**Execute**: read to-spec's SKILL.md → produce `.scratch/<feature-slug>/spec.md`
(`Status: ready-for-agent`).
**Completion**: spec has problem statement/solution/user stories/implementation & testing
decisions, published. Then **ask the user whether to break it into tickets**.

### C. Tickets + execution
**Trigger**: user says "execute / start / break into tickets / implement / continue".
**Execute**: first read to-tickets to break down (produce `.scratch/<feature-slug>/issues/NN-*.md`)
→ then read implement to execute (may use tdd).
**Completion**: all tickets implemented, tests passing. Then verify with code-review.

### D. Modification stage (bug / wrong / change)
**Trigger**: user reports a defect, points out something is wrong / off from spec or prototype, or
asks for a change.
**Root-cause first** (per AGENTS.md's Correction-handling rule): compare against the spec and
prototype, decide which layer is wrong:

1. **Spec wrong / requirement change**: read to-spec and update the spec.
2. **Ticket wrong**: read to-tickets and update the ticket.
3. **Code wrong**: fix the code directly, then verify against spec/prototype.

**Branch rule**: spec and prototype conflict → stop and ask the user to arbitrate (never pick a
side); spec clear and implementation deviates → branch 3.

**Mandatory closing check (every branch)**: verify spec / ticket / code are consistent — a spec
change makes tickets stale, so update tickets too; never assume "it's done so no sync needed".

### E. Hard bugs / performance regressions
**Trigger**: unexplained crash / error / slowness.
**Execute**: read diagnosing-bugs and follow it (build feedback loop → reproduce → hypothesize →
fix → regression test).

## General rules

- The user doesn't need to know which stage they're in — deciding is this skill's job; when entering
  a new stage, say in one line "entering stage X, will produce Y" so they have expectations.
- Artifact locations and terms follow `docs/agents/issue-tracker.md`, `CONTEXT.md`, `AGENTS.md`
  (when uninitialized, prompt to run setup-matt-pocock-skills first or let it run).
- Advance one stage at a time; when a stage boundary needs user confirmation (e.g. whether to break
  the spec into tickets), stop and ask.
