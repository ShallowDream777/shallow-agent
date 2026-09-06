# AGENTS.md

## General conventions（通用约定）

- **Language**: 本项目 AI agent 对话默认使用中文（{{language}}）。
- **Iteration workflow（迭代流程）**: 需求、变更、bug 一律先走 `auto-mattpocock` 技能——它负责判断阶段并执行对应工程流程（产出 spec + tickets）。
- **Deployment（部署）**: 部署/升级由 `deploy-to-server` 技能一键完成（配置见 `deploy.config.json`）；直接对 agent 说"部署"即可。
- **Issue tracker**: Issues are tracked as local markdown files under `.scratch/<feature>/`（见 `docs/agents/issue-tracker.md`）。
- **Domain docs**: Single-context layout — one `CONTEXT.md` + `docs/adr/` at the repo root（见 `docs/agents/domain.md`）。
- **Correction-handling rule（修正处理规则）**: 收到与 spec/原型相关的修正请求时，先对照 spec（`.scratch/<feature>/spec.md`）与原型判定错在哪层：
  - **spec 错/不完整** → 先向用户指出并提议更新 spec（走 auto-mattpocock 的 to-spec 流程），由用户决定；spec 变更后同步受影响的 ticket。
  - **spec 与原型冲突** → 停下请用户裁决，绝不自己选边。
  - **实现偏离清晰 spec/原型** → 直接修代码，改完对照 spec/原型验证。

## Agent skills

`docs/agents/*.md` 记录了 issue-tracker / triage / domain 约定（首次使用时由 setup 流程产出）。
