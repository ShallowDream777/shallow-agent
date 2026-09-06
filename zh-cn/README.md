# shallow-agent（中文镜像）

> **本目录是中文镜像，只供阅读。** 仓库主内容为英文（README 与各技能），中文版随英文维护：
> 英文主文件变更后需同步更新本目录对应文件。镜像仅覆盖文档（README + 各技能 SKILL.md 与
> yaml）——scripts/ 等代码不镜像（以英文主目录为准）。

让任意 Node 项目变成 **Agent 驱动**的技能套装：迭代走工程流程（spec + tickets）、一键部署到
Linux 服务器、一键初始化进新项目。技能内**零写死**——项目差异走配置文件。

## 包含

| 技能 | 一句话 |
|---|---|
| `auto-mattpocock` | 把需求/变更/bug 自动路由到 Matt-Pocock 工程流程（设计澄清 → spec → ticket → 实现 → 审查） |
| `deploy-to-server` | 一键把容器化 Node 项目部署/升级到 Linux 服务器（Docker Compose，缺失时自动生成） |
| `init-agent-project` | 把上面两个技能 + AGENTS.md/README/deploy.config.json 引导一次性初始化进任意项目 |

各技能的机制、适用范围、前提细节见英文主目录 `../` 下各技能或本目录对应文件。

## 快速安装

### 一句话：把这句话交给你的 agent

在任意项目中，对你的 agent 说：

> **从 https://github.com/ShallowDream777/shallow-agent 安装技能，然后初始化这个项目。**

agent（能跑 shell 命令、能访问 GitHub）会自己完成：

1. `git clone https://github.com/ShallowDream777/shallow-agent` 到临时目录
2. 运行 `bash shallow-agent/install.sh`，把三个技能（`auto-mattpocock`、`deploy-to-server`、
   `init-agent-project`）拷到用户级 `~/.agents/skills/`
3. 提示你开新会话（或刷新），让 agent 能发现这些技能
4. 运行 `init-agent-project`：把两个技能拷进本项目的 `.agents/skills/`、选项式询问技术栈、
   生成 `AGENTS.md`、`README.md`（agent 引导段）与 `deploy.config.json`

> 如果 agent 无法 clone（没有 shell / 访问不了 GitHub），退回下面的手动步骤。

### 手动步骤（不用 agent）

```bash
git clone https://github.com/ShallowDream777/shallow-agent.git
bash shallow-agent/install.sh           # 用户级：~/.agents/skills/
# 然后对你的 agent 说: 「初始化这个项目」
```

### install.sh 参数

```bash
bash install.sh                  # 用户级：~/.agents/skills/（所有项目可用）
bash install.sh -p <项目目录>     # 项目级：<项目目录>/.agents/skills/
bash install.sh -d <目录>         # 自定义技能目录
bash install.sh -f               # 强制替换已存在（默认不覆盖）
```

### 只装单个技能（不克隆仓库）

```bash
cp -r <技能目录>  <你的项目>/.agents/skills/
# 可选: auto-mattpocock / deploy-to-server / init-agent-project
```

前提：agent 环境能加载 `.agents/skills/` 下的 SKILL.md。

## 使用

| 你说 | agent 做 |
|---|---|
| 「加个 XX 功能」「开始做」「这个 bug 修一下」 | 走 `auto-mattpocock` 流程 |
| 「部署到服务器」 | 走 `deploy-to-server` |
| 「初始化这个项目」 | 走 `init-agent-project` |

## 镜像内容

- [auto-mattpocock/SKILL.md](auto-mattpocock/SKILL.md)
- [deploy-to-server/SKILL.md](deploy-to-server/SKILL.md)
- [init-agent-project/SKILL.md](init-agent-project/SKILL.md)
- 各技能 `openai.yaml`（display_name / short_description 中文对照）
