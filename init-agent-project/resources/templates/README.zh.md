# {{projectName}}

{{one_line_description}}

> ⚠️ **本项目由 AI Agent 驱动。** 日常迭代（提需求、改 bug、部署）通过 agent 对话完成——
> agent 自动走「设计澄清 → spec → ticket → 实现 → 审查」流程（`auto-mattpocock` 技能），
> 部署由 `deploy-to-server` 技能一键完成。开发者不需要手动维护 spec/ticket/部署脚本——
> 正常描述需求即可。

## Agent 驱动的工作方式

- **正常对话即可**：说「加个 XX 功能」「这个 bug 修一下」「部署」等，agent 自动处理
  （`auto-mattpocock` 路由迭代流程，`deploy-to-server` 处理部署）。
- **修改请求**：agent 会先对照 spec/原型判断错在 spec / ticket / 代码哪一层，该同步的文档会同步。
- **技术栈**：{{techstack_lines}}

## 开发

```bash
npm install        # 安装依赖
npm run dev        # 本地开发
npm test           # 测试
```

## 一键部署（由 agent 完成）

对 agent 说「部署到服务器」→ agent 读 `deploy.config.json` → 打包上传 → 服务器构建启动 →
健康检查并报告访问地址。首次会问服务器 IP / SSH 用户名，之后复用配置。

## 目录速查

- 领域词汇：`CONTEXT.md`
- 规格与 ticket：`.scratch/<feature>/`
- 部署配置：`deploy.config.json`
- Agent 约定：`AGENTS.md`、`docs/agents/`
