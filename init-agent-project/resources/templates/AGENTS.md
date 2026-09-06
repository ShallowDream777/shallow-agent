# AGENTS.md

## General conventions

- **Language**: AI agent conversations in this project default to {{language}}.
- **Iteration workflow**: Route every feature, change, and bug request through the `auto-mattpocock` skill — it decides the stage and runs the matching engineering flow (spec + tickets).
- **Deployment**: Deploys/upgrades are done in one step by the `deploy-to-server` skill (config in `deploy.config.json`); just tell the agent "deploy".
- **Issue tracker**: Issues are tracked as local markdown files under `.scratch/<feature>/` (see `docs/agents/issue-tracker.md`).
- **Domain docs**: Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root (see `docs/agents/domain.md`).
- **Correction-handling rule**: When asked to fix something that touches spec- or prototype-defined behavior, first compare the current implementation against the spec (`.scratch/<feature>/spec.md`) and the prototype (if one exists). Determine which layer the root cause is in:
  - If the **spec is wrong or incomplete**, surface it and propose updating the spec first (via auto-mattpocock's to-spec flow); let the user decide. After any spec change, also sync the affected ticket(s).
  - If the **spec and prototype conflict**, stop and ask the user to arbitrate — never pick a side yourself.
  - If the **implementation deviates** from a clear spec/prototype, fix the code directly, then verify against the spec.

## Tech stack

{{techstack_lines}}

## Agent skills

See `docs/agents/*.md` for issue-tracker / triage / domain conventions (produced by the setup flow on first use).
