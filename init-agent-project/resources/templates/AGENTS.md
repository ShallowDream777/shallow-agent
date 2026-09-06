# AGENTS.md

## General conventions

- **Language**: AI agent conversations in this project default to {{language}}.
- **Iteration workflow**: 需求、变更、bug 一律先走 `auto-mattpocock` 技能（它负责判断阶段并执行对应工程流程，产出 spec + tickets）。
- **Deployment**: 部署/升级由 `deploy-to-server` 技能一键完成（配置见 `deploy.config.json`）；直接对 agent 说"部署"即可。
- **Issue tracker**: Issues are tracked as local markdown files under `.scratch/<feature>/` (see `docs/agents/issue-tracker.md`).
- **Domain docs**: Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root (see `docs/agents/domain.md`).
- **Correction-handling rule**: When asked to fix something that touches spec- or prototype-defined behavior, first compare the current implementation against the spec (`.scratch/<feature>/spec.md`) and the prototype (if one exists). Determine which layer the root cause is in:
  - If the **spec is wrong or incomplete**, surface it and propose updating the spec first (via auto-mattpocock's to-spec flow); let the user decide. After any spec change, also sync the affected ticket(s).
  - If the **spec and prototype conflict**, stop and ask the user to arbitrate — never pick a side yourself.
  - If the **implementation deviates** from a clear spec/prototype, fix the code directly, then verify against the spec.

## Tech stack

- {{techstack_lines}}

## Agent skills

See `docs/agents/*.md` for issue-tracker / triage / domain conventions (produced by the setup flow on first use).
