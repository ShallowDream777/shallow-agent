---
name: auto-mattpocock
description: 把 Matt-Pocock 工程流程变成项目的默认迭代方式，可移植、自初始化。它的初始化序列（装依赖技能 → 跑 setup-matt-pocock-skills 配置仓库 → 主动 grill 问现在要做什么，可中止）是项目的初始化入口，可被其他技能调用（如 init-agent-project）。初始化后，对话里的每个请求（功能、修改、bug、设计决策）都路由到对应工程技能，产出 spec + tickets；需求不清晰会自动再 grill。开发者无需记忆任何技能名。
---

# Auto Matt-Pocock

把 Matt-Pocock 工程流程（设计澄清 → spec → tickets → 实现 → 审查）变成项目的默认迭代方式。
本技能是**可移植的路由器**：它只做阶段判断，实际流程由它发现/安装的工程技能执行。
**开箱即用**：把它放到任何项目的技能目录（或用户级技能目录），首次运行自动补齐依赖。

## 前置：初始化（每次运行先检查）

依赖的工程技能（下表）可能尚未安装——尤其在新项目或用户级安装时。**每次运行先检查它们是否可发现，缺失的先安装，再走阶段判断。**

### 依赖清单

| 依赖技能 | 何时需要 |
| --- | --- |
| grill-with-docs | 阶段 A 设计澄清 |
| to-spec | 阶段 B/D spec |
| to-tickets | 阶段 C/D ticket |
| implement | 阶段 C 实现 |
| code-review | 实现后审查 |
| diagnosing-bugs | 阶段 E 疑难 bug |
| tdd | implement 内可选 |
| setup-matt-pocock-skills | 产出 AGENTS.md/docs 约定 |

### 检查与安装

**如何判断依赖可发现**：本技能所在目录的**同级目录**（即与 `auto-mattpocock/` 并列的兄弟技能目录，如 `.agents/skills/` 或用户级 `skills/` 下的其他目录）中存在 `<依赖名>/SKILL.md`，或已知技能根（见下）能搜到。缺失即在安装清单内。可用 glob 或目录列举逐个确认（如搜 `**/to-spec/SKILL.md`、`**/to-tickets/SKILL.md`）。

**安装到哪**：**跟随本技能所在层级**——本技能在项目技能目录（如 `X/.agents/skills/`）→ 依赖装项目级；本技能在用户级（如 `~/.agents/skills/`）→ 依赖装用户级。**不写死项目级路径，不缓存安装命令。**

**如何安装（以官方 README 为准，勿写死命令）**：mattpocock/skills 的安装方式会随官方演进（当前多种途径：skills CLI、Claude Code plugin 等）。**执行时先读取官方 README 的 Installation 章节**（https://github.com/mattpocock/skills —— 用 web_fetch 读 raw README：`https://raw.githubusercontent.com/mattpocock/skills/main/README.md`），按其**最新推荐的、适用于当前 agent/场景的途径**执行。然后：

- 确保安装覆盖**本依赖清单里的全部技能**（无论哪种安装途径，都要让 setup-matt-pocock-skills 在内的 8 个技能可用）
- 若官方途径是交互式的（如 skills CLI 让你挑技能/agent），用其非交互 flags 或程序化应答完成，不卡在交互上
- 保持官方工具对安装的追踪（如 skills CLI 的 `skills-lock.json`）完整，不要绕过它手写文件
- 用户级安装用官方途径的全局/用户级开关（如 skills CLI 的 `-g`）

**无法访问官方源时**：告知用户"auto-mattpocock 需要联网按官方 README 安装依赖技能"，不硬跑。

**已知技能根**（查找依赖时都扫）：本技能同级的 skills 目录、项目 `.agents/skills/`、项目 `.dsh/skills/`、用户 `~/.agents/skills/`、`~/.dsh/skills/`。

### 第 2 步：跑仓库配置（setup-matt-pocock-skills）

**装完技能不等于配置完仓库。** setup-matt-pocock-skills 安装后还需**执行它的配置流程**一次，否则 `.scratch/`、`docs/agents/`（issue-tracker/triage/domain 三文件）、AGENTS.md 的 Agent skills 块都不存在，后续 to-spec/to-tickets 无处落盘。

**何时跑**：本技能**首次**在某个项目目录触发，且探测到该仓库尚未配置（无 `docs/agents/issue-tracker.md`、无 `AGENTS.md`/`CLAUDE.md` 的 `## Agent skills` 块）时。若已有这些产物，跳过（不重复配置）。

**怎么跑**：按 `setup-matt-pocock-skills/SKILL.md` 的流程执行——它自己会探索仓库现状并逐节询问用户（issue tracker 选型 / triage 标签 / domain 布局），最后写 `docs/agents/` 三文件与 AGENTS.md 的 Agent skills 块。**它是 prompt-driven，需要用户回答几个问题**，不要跳过提问直接写。

**完成判据**：`docs/agents/issue-tracker.md` 存在（或用户显式选择了 tracker 类型）；`AGENTS.md`/`CLAUDE.md` 有 `## Agent skills` 块；`CONTEXT.md` 约定就位。

### 第 3 步：主动发起 grill（问现在要做什么）

仓库配置完成、可用了。**主动问用户现在想做什么**——用设计澄清的 grill（阶段 A 的 grill-with-docs）开场，而不是干等用户提需求。用户没想好可以中止（"还没有 / 只是先搭好"）——没关系，初始化到此已完成。之后用户随时提需求，本技能按正常阶段路由处理（需求不清晰会自动再 grill）。

**怎么做**：上面整个 Preflight 序列（检查 → 安装 → setup → grill）**就是本技能的初始化入口**。
其他技能可以通过读本 SKILL.md、从头按 Preflight 执行来调用它——它们不需要知道
setup-matt-pocock-skills 的存在。`init-agent-project` 放好技能后正是这么做的。

## 执行方式

依赖的工程技能大多是 user-invoked（`disable-model-invocation: true`），模型不能通过 Skill 工具触发它们。**替代机制：用 read 工具读取目标技能的 SKILL.md 文件，按其指令执行。** 定位目标技能：在"已知技能根"中搜索 `<技能名>/SKILL.md`，第一个找到即用（安装到本技能同级的优先）。

**本技能只做阶段判断，不重复技能内容。** 目标 SKILL.md 是权威指令。

## 阶段判断

### A. 设计 / 规划阶段
**触发**：重大变更、新的大功能、需求不清晰、有设计决策或方向性问题。
**执行**：读 grill-with-docs 的 SKILL.md 执行 → 产出/更新 `CONTEXT.md` 术语与 `docs/adr/` 决策。
**完成判据**：设计树走完、术语已落盘。然后进入 B。

### B. Spec 阶段
**触发**：需求已清楚、要把讨论固化成 spec。
**执行**：读 to-spec 的 SKILL.md 执行 → 产出 `.scratch/<feature-slug>/spec.md`（`Status: ready-for-agent`）。
**完成判据**：spec 含问题陈述/解决方案/用户故事/实现与测试决定，已发布。完成后**询问用户是否拆 ticket**。

### C. 拆解 + 执行阶段
**触发**：用户说"执行 / 开始做 / 拆 ticket / 实现 / 继续实现"。
**执行**：先读 to-tickets 拆解（产出 `.scratch/<feature-slug>/issues/NN-*.md`）→ 再读 implement 执行（可用 tdd）。
**完成判据**：tickets 全部实现、测试通过。完成后用 code-review 验证。

### D. 修改阶段（bug / 改错 / 变更）
**触发**：用户报告缺陷、指出"不对 / 和原型不符 / 要改"，或提出变更需求。
**先做根因分流**（遵循 `AGENTS.md` 的 Correction-handling rule）：对照 spec 与原型，判定错在哪层：

1. **Spec 错 / 需求变更**：读 to-spec 更新 spec。
2. **Ticket 错**：读 to-tickets 更新 ticket。
3. **代码错**：直接修改代码，改完对照 spec/原型验证。

**分支判据**：spec 与原型冲突 → 停下请用户裁决；spec 明确且实现偏离 → 分支 3。

**强制收尾校验（每个分支）**：核对 spec / ticket / 代码三方一致——spec 变更会使 ticket 过时，ticket 随之更新；不要假设"已完成就不需同步"。

### E. 疑难 bug / 性能回归
**触发**：原因不明的崩溃/报错/慢。
**执行**：读 diagnosing-bugs 执行（建反馈回路 → 复现 → 假设 → 修 → 回归测试）。

## 总则

- 用户不需要知道自己在哪个阶段——判断是本技能的职责；进入新阶段时用一句话说明"进入 X 阶段，将产出 Y"。
- 产物落点与术语以 `docs/agents/issue-tracker.md`、`CONTEXT.md`、`AGENTS.md` 为准（未初始化时提示先跑 setup-matt-pocock-skills 或由它自动完成）。
- 一次只推进一个阶段；阶段间需要用户确认（如 spec 是否拆 ticket）就停下来问。
