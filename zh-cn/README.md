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

## 镜像内容

- [auto-mattpocock/SKILL.md](auto-mattpocock/SKILL.md)
- [deploy-to-server/SKILL.md](deploy-to-server/SKILL.md)
- [init-agent-project/SKILL.md](init-agent-project/SKILL.md)
- 各技能 `openai.yaml`（display_name / short_description 中文对照）

> 使用与安装请以英文主 `../README.md` 为准。
