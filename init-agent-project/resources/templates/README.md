# {{projectName}}

{{one_line_description}}

> ⚠️ **This project is driven by an AI agent.** Day-to-day iteration (features, bug fixes,
> deployment) happens through agent conversation — the agent runs the
> clarify → spec → tickets → implement → review flow automatically (`auto-mattpocock` skill)
> and deploys with the `deploy-to-server` skill. You don't maintain specs/tickets/deploy scripts
> by hand — just describe what you want.

## Agent-driven workflow

- **Just talk normally**: say "add feature X" / "fix this bug" / "deploy" and the agent handles it
  (`auto-mattpocock` routes iteration, `deploy-to-server` handles deployment).
- **Change requests**: the agent first checks the spec/prototype to decide whether the spec, the
  tickets, or the code is at fault, and syncs whatever doc needs syncing.
- **Tech stack**: {{techstack_lines}}

## Development

```bash
npm install        # install dependencies
npm run dev        # local dev
npm test           # tests
```

## One-click deploy (done by the agent)

Tell the agent "deploy to server" → it reads `deploy.config.json` → packages and uploads → builds
and starts on the server → health-checks and reports the URL. On first use it asks for the server
IP / SSH username, then reuses the config.

## Directory map

- Domain glossary: `CONTEXT.md`
- Spec & tickets: `.scratch/<feature>/`
- Deploy config: `deploy.config.json`
- Agent conventions: `AGENTS.md`, `docs/agents/`
