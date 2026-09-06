# shallow-agent

让任意 Node 项目变成 **Agent 驱动**的技能套装：迭代走工程流程（spec + tickets）、一键部署到
Linux 服务器、一键初始化进新项目。技能内**零写死**——项目差异走配置文件。

## 包含

| 技能 | 一句话 |
|---|---|
| `auto-mattpocock` | 把需求/变更/bug 自动路由到 Matt-Pocock 工程流程（设计澄清 → spec → ticket → 实现 → 审查） |
| `deploy-to-server` | 一键把容器化 Node 项目部署/升级到 Linux 服务器（Docker Compose，缺失时自动生成） |
| `init-agent-project` | 把上面两个技能 + AGENTS.md/README/deploy.config.json 引导一次性初始化进任意项目 |

各技能的机制、适用范围、前提细节见各自目录的 `SKILL.md`。

## 安装

### 方式 A：一键初始化（推荐）

装 `init-agent-project`，然后对目标项目说「初始化这个项目」即可——它会拷入另两个技能、
询问技术栈（选项式）、生成引导文件。

```bash
# 用户级（所有项目可用）或项目级 .agents/skills/
cp -r init-agent-project ~/.agents/skills/
```

### 方式 B：只装单个技能

```bash
cp -r <skill目录>  <你的项目>/.agents/skills/
# 支持: auto-mattpocock / deploy-to-server / init-agent-project
```

前提：agent 环境能加载 `.agents/skills/` 下的 SKILL.md。

## 使用

| 你说 | agent 做 |
|---|---|
| 「加个 XX 功能」「开始做」「这个 bug 修一下」 | 走 `auto-mattpocock` 流程 |
| 「部署到服务器」 | 走 `deploy-to-server` |
| 「初始化这个项目」 | 走 `init-agent-project` |

## License

MIT
