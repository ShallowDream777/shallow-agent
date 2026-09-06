# shallow-agent

A set of skills that turn any Node project into an **agent-driven** project: iterative
engineering workflow (spec + tickets), one-click deployment to a Linux server, and one-shot
bootstrapping into a new project. Skills contain **no hardcoded project values** — project
differences live in config files.

> Chinese mirror for reading only: [zh-cn/](zh-cn/README.md)

## Contents

| Skill | What it does |
|---|---|
| `auto-mattpocock` | Routes requests (features / changes / bugs) into the Matt-Pocock engineering flow — clarify → spec → tickets → implement → review |
| `deploy-to-server` | One-click deploy/upgrade of a containerized Node project to a Linux server (Docker Compose; generates Dockerfile/compose when missing) |
| `init-agent-project` | Bootstraps the two skills above plus AGENTS.md / README / deploy.config.json guidance into any project |

Mechanics, scope and prerequisites of each skill live in its own `SKILL.md`.

## Install

### One-liner: hand this to your agent

In any project, tell your agent:

> **Install the skills from https://github.com/ShallowDream777/shallow-agent, then initialize
> this project.**

The agent (which can run shell commands and reach GitHub) does this on its own:

1. `git clone https://github.com/ShallowDream777/shallow-agent` into a hidden temp dir inside this
   project (e.g. `.shallow-agent-tmp/`) — never into the project root or a real source folder
2. run `bash shallow-agent/install.sh` to copy the three skills
   (`auto-mattpocock`, `deploy-to-server`, `init-agent-project`) to user-level `~/.agents/skills/`
3. run `init-agent-project`: copy the two skills into this project's `.agents/skills/`, ask the
   tech stack (option-based), and scaffold `AGENTS.md`, `README.md` (agent-guidance) and
   `deploy.config.json`
4. **delete the temporary clone** — do not leave the shallow-agent repo inside this project
5. tell you to start a new session (or refresh) so the agent discovers the skills

> If your agent cannot clone (no shell / no GitHub access), fall back to the manual steps below.

### Manual steps (no agent)

```bash
git clone https://github.com/ShallowDream777/shallow-agent.git
bash shallow-agent/install.sh          # user-level: ~/.agents/skills/
# then tell your agent: "initialize this project"
```

### Install options for `install.sh`

```bash
bash install.sh                 # user-level: ~/.agents/skills/ (every project)
bash install.sh -p <project>    # project-level: <project>/.agents/skills/
bash install.sh -d <dir>        # custom skills directory
```

### Install a single skill (no repo clone)

```bash
cp -r <skill-dir>  <your-project>/.agents/skills/
# available: auto-mattpocock / deploy-to-server / init-agent-project
```

Prerequisite: an agent environment that loads `SKILL.md` files from `.agents/skills/`.

## Usage

| You say | The agent does |
|---|---|
| "Add feature X" / "start" / "fix this bug" | runs the `auto-mattpocock` flow |
| "Deploy to server" | runs `deploy-to-server` |
| "Initialize this project" | runs `init-agent-project` |

## Iterating on this repo

Changing a skill ships it into other projects, so edits must keep the English master, the
`init-agent-project` bundled copies, and the `zh-cn/` Chinese mirror in sync — **English is the
authoritative source; `zh-cn/` is a read-only mirror**. See [CONTRIBUTING.md](CONTRIBUTING.md) for
the sync rules and change checklist.

## License

MIT
