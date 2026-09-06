---
name: init-agent-project
description: 把任意项目初始化为「Agent 驱动」项目：把 auto-mattpocock + deploy-to-server 两个技能拷进项目的 .agents/skills/，解析技术栈（README.md 已记录则读取、否则询问）并**记录到 README.md**，空项目时按技术栈搭建骨架，生成 AGENTS.md、README、deploy.config.json，然后运行 auto-mattpocock 的初始化（读它的 SKILL.md 按其执行）。当用户说「初始化这个项目 / 项目接入 agent 流程 / 搭建 agent 驱动项目」时使用。可复用：技能自带两份技能的副本与模板，拷到任何项目即用。
---

# Init Agent Project

把任意（新或现有）项目初始化成「Agent 驱动」形态：带 `auto-mattpocock`（迭代路由）与
`deploy-to-server`（一键部署）两个技能，配上让 agent 知道「本项目由技能驱动」的 AGENTS.md /
README / deploy.config.json，最后把初始化交给 auto-mattpocock。它解析技术栈——`README.md` 已
记录就直接读取、否则跑一次简短问卷——把结果**记录到 `README.md`**（唯一持久化载体），并在目标
是空项目时搭建骨架。

## 它做什么（五步）

1. **引入技能**：把本技能 `resources/skills/` 下的 auto-mattpocock、deploy-to-server 拷到目标
   项目的 `.agents/skills/`（不存在则创建）。**副本是本技能携带的**——技能更新时重新拷贝即可。
2. **解析技术栈**：先读目标项目的 `README.md`。若它已记录技术栈（`## Tech stack` 段或
   `**Tech stack**:` 行），直接采用，不再询问；否则跑一次简短问卷（**先用英文问对话语言**，再问
   项目名、前端框架、后端框架、数据库、对外端口）。不问设计细节——那是之后 auto-mattpocock grill
   流程的事。
3. **搭建项目骨架**（仅当目标为空项目）：按解析出的技术栈建目录结构与 package.json（步骤 4 会
   用到这些答案，见下方步骤 4）。
4. **持久化技术栈 + 生成引导文件**：写 `README.md`（**技术栈的唯一持久化记录**——下次运行时步骤
   2 会从这读取），以及 `AGENTS.md`、`deploy.config.json`。
5. **移交给 auto-mattpocock 的初始化**（见下方步骤 5）：读 `auto-mattpocock/SKILL.md` 并按它的初始化
   执行。本技能在交接处结束——之后由 auto-mattpocock 自己的流程接手。

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

### 2. 解析技术栈（先读 README.md，读不到再问）

**先读目标项目的 `README.md`。** 若它已有可识别的技术栈条目（`## Tech stack` 段或 `**Tech
stack**:` 行），直接采用这些答案，不再询问。这就是技术栈可持久化的关键：对已初始化项目再次运行
本技能时会沿用已记录的技术栈，而不是重新问一遍。

若 README 没有技术栈条目（全新项目，或 README 从未记录过技术栈），跑下面的问卷。解析出的值在
步骤 4 写进 `README.md`，使 README 成为技术栈的唯一持久化记录。

**第一问先用英文问对话语言**（选项：中文 / English；默认 English）——这是问卷的第一问。它的答案
决定其后一切的语言：问卷其余问题、本次 init 过程中你问的问题、步骤 4 写入的引导文件语言、以及你的
汇报。若用户答中文，后续交互全部切中文；若答 English（或其他），继续用英文。

然后**用所选语言**逐项给**预设选项让用户选**（每项给推荐 + 常用可选项），用户选"其他/自定义"才
自由输入；用默认值即可时直接接受，不逐项追问。带默认建议的项不必等答案——用户没异议就用默认：

- **项目名**（自由输入；用于 README 标题 / deploy.config appName）
- **前端框架**（选项：Vue3+Vite / React+Next / 无（纯后端） / 自定义）
- **后端框架**（选项：Express / Fastify / NestJS / 无（纯前端/静态） / 自定义）
- **数据库**（选项：SQLite / PostgreSQL / MySQL / 无 / 自定义）
- **对外端口**（选项：8080 / 3000 / 80 / 自定义；默认 8080）

**交互方式**：逐项呈现"选项列表 + 推荐标注"，用户可：直接选一项 / 说"默认"接受推荐 /
自己输入选项外的值。**不是开放文本框**——先给选择，用户不愿选才落输入。

**完成判据**：技术栈已定——要么从 README 读到，要么问卷值齐全（每项选中预设、用户自定义、
或明示用默认）。

### 3. 搭建项目骨架（仅当目标为空/新建项目）

若目标项目还没有源码（无 frontend/backend 目录、无 package.json），按步骤 2 解析出的技术栈
创建一个最小可运行骨架，让"初始化这个项目"真正产出可继续开发的结构：

- **Node 前端 + 后端**（如 Vue3+Vite + Express）：monorepo 布局，含 `frontend/` 和 `backend/`、
  根 `package.json` 的 `workspaces`、各包 `package.json` 对齐所选框架。
- **纯后端 / 纯前端 / 纯数据库**：对应的单包布局。
- **保持最小**——目录形状 + `package.json`（name、engines、scripts、框架依赖）即可。别过度搭
  建，功能代码之后由 auto-mattpocock 提需求时再写。

**目标已有源码**则跳过此步（不给已有项目强加布局）。

**完成判据**：目标有匹配解析所得技术栈的骨架（或它本有源码、已跳过）。

### 4. 持久化技术栈 + 生成引导文件

用 `resources/templates/` 里的模板 + 步骤 2 解析出的技术栈填出文件，写入目标项目根。**按所选
语言选模板**（步骤 2 的"对话默认语言"）：

- **中文** → `AGENTS.zh.md`、`README.zh.md`
- **English / 其他** → `AGENTS.md`、`README.md`
- `deploy.config.json` 语言无关（共用模板）

要写的文件：

- `README.md`——**技术栈的唯一持久化记录**，也是下次运行时步骤 2 读取的地方。替换
  `{{projectName}}`、`{{one_line_description}}`、`{{techstack_lines}}`。若目标已有 README，**合并
  而非覆盖**——保留原内容，把 agent 引导段 / 部署段 / 目录速查补进去，并写入或刷新技术栈条目。
- `AGENTS.md`——替换 `{{language}}`；agent 约定指向各技能。
- `deploy.config.json`——替换 `{{appName}}` 和 `{{port}}`。这里**不放技术栈**：deploy 从项目自身
  探测运行时，不依赖某个 stack 字段。server 字段留空，直到首次部署时再问。

归属说明：`CONTEXT.md` 是领域词汇表，归 matt-pocock 领域流程所有（只放词汇，不放实现细节）。
auto-mattpocock 的初始化（步骤 5）与之后的 domain-modeling 会创建并填充它。本步骤只写 README /
AGENTS / deploy.config.json，把 CONTEXT.md 交给该流程。

已有同名文件时：AGENTS.md 有 `## Agent skills`/Iteration 内容则提示是否合并；README 合并；
deploy.config.json 已存在则不动。

**完成判据**：README.md / AGENTS.md / deploy.config.json 写入目标项目，技术栈已记录在 README.md；
有冲突处已征询用户。

### 5. 移交给 auto-mattpocock 的初始化

项目现在有了技能、（若新建）骨架和记录在 README.md 里的技术栈。**以交接作为最后一步，启动
auto-mattpocock 的初始化**——读 `auto-mattpocock/SKILL.md` 并按它的初始化章节从头执行。

这是**一次干净的交接，不是合并**。从控制权进入 auto-mattpocock 初始化的那一刻起，之后的一切——
它要装什么、配置什么、问什么问题、何时停下——都归 auto-mattpocock 自己的流程所有。本技能不跟进、
不评判、也不汇报那些。本技能的工作在交接时结束。

**完成判据**：本技能自己的产物都已就位——两个技能在 `.agents/skills/`、技术栈记录在 `README.md`、
AGENTS.md / README / deploy.config.json 已写入、空目标已搭骨架——并且 auto-mattpocock 的初始化已
按其 SKILL.md 完成交接。

## 原则

- **技能副本随引子分发**：本技能是 auto-mattpocock + deploy-to-server 的分发载体——它们更新时，
  把新版本拷回 `resources/skills/` 即完成引子同步。
- **README.md 是技术栈的持久化记录**：技术栈只存在 README.md 一处。步骤 2 会读回它，因此重复
  运行不会重新询问。别在 deploy.config.json 或 CONTEXT.md 里再放一份副本。
- **模板可编辑**：模板在 `resources/templates/`，按团队口味改（AGENTS 措辞、README 结构）。
  语言成对：`AGENTS.md`/`AGENTS.zh.md`、`README.md`/`README.zh.md`——改措辞时两边同步。
- **合并不覆盖**：目标项目已有 README/AGENTS.md 时，补内容而非整份覆盖。
