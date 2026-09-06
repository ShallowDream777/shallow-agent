---
name: init-agent-project
description: 把任意项目初始化为「Agent 驱动」项目：把 auto-mattpocock + deploy-to-server 两个技能拷进项目的 .agents/skills/，询问技术栈并**持久化记录**（写 CONTEXT.md + deploy.config.json 的 stack 字段），空项目时按技术栈搭建骨架，生成 AGENTS.md、README（agent 引导段）等，然后运行 auto-mattpocock 的初始化（读它的 SKILL.md 按其执行）。当用户说「初始化这个项目 / 项目接入 agent 流程 / 搭建 agent 驱动项目」时使用。可复用：技能自带两份技能的副本与模板，拷到任何项目即用。
---

# Init Agent Project

把任意（新或现有）项目初始化成「Agent 驱动」形态：带 `auto-mattpocock`（迭代路由）与
`deploy-to-server`（一键部署）两个技能，配上让 agent 知道「本项目由技能驱动」的 AGENTS.md /
README / deploy.config.json，最后把初始化交给 auto-mattpocock。它只问一次技术栈、**把结果
持久化记录下来**（CONTEXT.md + deploy.config.json 的 stack 字段），并在目标是空项目时搭建骨架。

## 它做什么（五步）

1. **引入技能**：把本技能 `resources/skills/` 下的 auto-mattpocock、deploy-to-server 拷到目标
   项目的 `.agents/skills/`（不存在则创建）。**副本是本技能携带的**——技能更新时重新拷贝即可。
2. **询问技术栈**：问项目名、对话默认语言、前端框架、后端框架、数据库、对外端口
   （一次简短问卷，不问设计细节）。
3. **搭建项目骨架**（仅当目标为空项目）：按所选技术栈建目录结构与 package.json（见下方步骤 3）。
4. **持久化技术栈 + 生成引导文件**：写 `CONTEXT.md`（记录技术栈供后续领域工作）、`AGENTS.md`、
   `README.md`、`deploy.config.json`（含 `stack` 字段）。
5. **运行 auto-mattpocock 的初始化**（见下方步骤 5）——它完成仓库收尾配置并问要做什么。

## 使用

### 来源与清理（当本技能是通过 clone 仓库安装来时）

如果本技能是通过 clone shallow-agent 仓库（一句话安装）到达项目的，那个 clone 只是**临时投递
载体**——不是项目的一部分。要清理：

- **clone 到项目内的隐藏临时目录**，如 `.shallow-agent-tmp/`（加入 gitignore），绝不 clone 进
  项目根目录或真实源码文件夹。
- **初始化完成后删除那个临时 clone**（`rm -rf`）。把整个 shallow-agent 仓库（含 `.git`）留在
  项目里是一个 bug。
- 项目级和用户级安装都适用：从临时 clone 里装技能，然后删除 clone。

### 0. 确认目标项目

- 问清楚目标项目根目录（默认当前目录）。注意：**本技能拷给别人的是"模板"，运行对象是目标项目**。
- 目标项目的 `.agents/skills/` 若已有同名技能 → 询问是否覆盖（默认保留现有，只补缺失）。

### 1. 引入技能

从 `resources/skills/` 复制 auto-mattpocock、deploy-to-server 到目标 `.agents/skills/`：
（保留目录内全部文件：SKILL.md、agents/、scripts/ 等）

**完成判据**：目标项目 `.agents/skills/{auto-mattpocock,deploy-to-server}/SKILL.md` 均存在。

### 2. 询问技术栈（简短问卷）

逐项给**预设选项让用户选**（每项给推荐 + 常用可选项），用户选"其他/自定义"才自由输入；
用默认值即可时直接接受，不逐项追问。带默认建议的项不必等答案——用户没异议就用默认：

- **项目名**（自由输入；用于 README 标题 / deploy.config appName / AGENTS 文件名）
- **对话默认语言**（选项：中文 / English；**决定引导文档整体语言**，见步骤 3）
- **前端框架**（选项：Vue3+Vite / React+Next / 无（纯后端） / 自定义）
- **后端框架**（选项：Express / Fastify / NestJS / 无（纯前端/静态） / 自定义）
- **数据库**（选项：SQLite / PostgreSQL / MySQL / 无 / 自定义）
- **对外端口**（选项：8080 / 3000 / 80 / 自定义；默认 8080）

**交互方式**：逐项呈现"选项列表 + 推荐标注"，用户可：直接选一项 / 说"默认"接受推荐 /
自己输入选项外的值。**不是开放文本框**——先给选择，用户不愿选才落输入。

**完成判据**：上述值齐全（每项要么选中一个预设、要么用户给了自定义值、要么明示用默认）。

### 3. 搭建项目骨架（仅当目标为空/新建项目）

若目标项目还没有源码（无 frontend/backend 目录、无 package.json），按所选技术栈创建一个最小
可运行骨架，让"初始化这个项目"真正产出可继续开发的结构。匹配步骤 2 的技术栈答案：

- **Node 前端 + 后端**（如 Vue3+Vite + Express）：monorepo 布局，含 `frontend/` 和 `backend/`、
  根 `package.json` 的 `workspaces`、各包 `package.json` 对齐所选框架。
- **纯后端 / 纯前端 / 纯数据库**：对应的单包布局。
- **保持最小**——目录形状 + `package.json`（name、engines、scripts、框架依赖）即可。别过度搭
  建，功能代码之后由 auto-mattpocock 提需求时再写。

**目标已有源码**则跳过此步（不给已有项目强加布局）。

**完成判据**：目标有匹配所选技术栈的骨架（或它本有源码、已跳过）。

### 4. 持久化技术栈 + 生成引导文件

用 `resources/templates/` 里的模板 + 步骤 2 的答案填出文件，写入目标项目根。**按所选语言选模板**
（步骤 2 的"对话默认语言"）：

- **中文** → `AGENTS.zh.md`、`README.zh.md`、`CONTEXT.zh.md`
- **English / 其他** → `AGENTS.md`、`README.md`、`CONTEXT.md`
- `deploy.config.json` 语言无关（共用模板）

要写的文件：

- `CONTEXT.md`（记录技术栈 + 项目一句话——这是后续领域建模/grill 会读的持久化记录；替换
  `{{projectName}}`、`{{one_line_description}}`、`{{techstack_lines}}`）
- `AGENTS.md`（替换 `{{language}}`、`{{techstack_lines}}`）
- `README.md`（替换 `{{projectName}}`、`{{one_line_description}}`、`{{techstack_lines}}`；
  若目标已有 README，**合并而非覆盖**——保留其原内容，把 agent 引导段/部署段/目录速查补进去）
- `deploy.config.json`（替换 `{{appName}}`、`{{port}}`、`{{frontend}}`、`{{backend}}`、`{{db}}`——
  `stack` 字段记录所选框架，供后续 deploy 复用）

已有同名文件时：AGENTS.md 有 `## Agent skills`/Iteration 内容则提示是否合并；README 合并；
CONTEXT.md 已存在则询问是否更新 Tech stack；deploy.config.json 已存在则不动。

**完成判据**：CONTEXT.md / AGENTS.md / README.md / deploy.config.json 写入目标项目；有冲突处已征询用户。

### 5. 运行 auto-mattpocock 的初始化

项目现在有了技能、（若新建）骨架和记录的技术栈。**接下来运行 `auto-mattpocock` 的初始化**——
读 `auto-mattpocock/SKILL.md` 并按它的初始化章节从头执行。它会完成仓库的收尾配置，然后
**问用户现在想做什么**（用户没想好可以中止——项目到这也已初始化完成）。`deploy.config.json`
的 server 字段留空，直到首次部署时再问。

**完成判据**：auto-mattpocock 的初始化已执行（或用户明确推迟）；报告已安装/生成了什么，
并说明 agent 现在可以接受需求了。

## 原则

- **技能副本随引子分发**：本技能是 auto-mattpocock + deploy-to-server 的分发载体——它们更新时，
  把新版本拷回 `resources/skills/` 即完成引子同步。
- **模板可编辑**：模板在 `resources/templates/`，按团队口味改（AGENTS 措辞、README 结构）。
  语言成对：`AGENTS.md`/`AGENTS.zh.md`、`README.md`/`README.zh.md`——改措辞时两边同步。
- **合并不覆盖**：目标项目已有 README/AGENTS.md 时，补内容而非整份覆盖。
