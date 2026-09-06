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

### One-liner: install the repo, then initialize your project

```bash
# 1. clone and install (copies the three skills to user-level ~/.agents/skills/)
git clone https://github.com/ShallowDream777/shallow-agent.git
bash shallow-agent/install.sh

# 2. in any project, tell your agent:
#    "initialize this project"
```

The agent then runs `init-agent-project`: it copies the two skills into the project's
`.agents/skills/`, asks the tech stack (option-based), and scaffolds `AGENTS.md`,
`README.md` (agent-guidance) and `deploy.config.json`.

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

## License

MIT
