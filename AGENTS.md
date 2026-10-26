# 本仓库的 AI 开发入口

这里是脚手架源码仓库。`template/` 是装进目标项目的唯一机制源码，`skill/SKILL.md` 是接入说明；根目录 `scripts/` 只转发到 `template/scripts/`，不在转发脚本里复制逻辑。本仓库也按 `template/AGENTS.md` 的流程开发（三道门、任务池、WIP 接力），下面只写本仓库特有的约定。

## 接手
1. 运行 `bash scripts/ai-resume.sh owner [feat]`，再读 `MEMORY.md`、个人偏好（`~/.ai-harness/PREFERENCES.md` 与 `PREFERENCES.md`，有则读）、当前 Spec 的 `tasks.md` 与 `verification.md`、`git status` / `git diff`。
2. 从 `docs/architecture/00-INDEX.md` 找到要改的模块；接入技能、模板脚本、项目指南是不同模块。

## 开发
- 维护者直接说需求，AI 用 `bash scripts/ai-task-pool.sh intake "原话"` 收录与路由；非平凡变更走三道门。
- 改脚手架脚本时编辑 `template/scripts/`，跑 `bash scripts/harness-selftest.sh`；改 `skill/SKILL.md` 时按它在临时目录实际接入一次新项目，确认自检通过。
- 改 `template/AGENTS.md` 或 `template/.agents/skills/` 时，同步检查 README、`skill/SKILL.md` 与自检。
- **少就是多**：不写 CLI、兼容或迁移代码，升级与降级写成说明；只支持 Windows（Git Bash）。会让脚手架变臃肿的功能、配置和文档直接删除，追溯交给 Git。
- 正式验证 `bash scripts/ai-verify.sh --spec <feat> <file>`；状态指纹全仓计算，只排除 `process/`。

需要强制审批时用代码托管平台的权限机制。
