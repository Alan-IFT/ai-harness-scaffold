# 本仓库的 AI 开发入口

这里是脚手架源码仓库。`template/` 是分发给目标项目的唯一机制源码；根目录的 `scripts/` 仅转发到 `template/scripts/`，不要在转发脚本里复制逻辑。

## 接手

1. 主 Agent 在仓库根目录运行 `bash scripts/ai-resume.sh owner [feat]`；输出会提示续做的 Spec 或任务池下一项。限定任务运行 `worker <feat> <task-id>`；独立审查运行 `review <feat> <base-ref>`。按角色读取原件；主 Agent 再读 `MEMORY.md`、当前 Spec 的 `tasks.md` 与 `verification.md`、`git status` / `git diff`。
2. 从 `docs/architecture/00-INDEX.md` 找到要改的部分。CLI、模板脚本、项目指南是不同模块；跨模块修改按需读多篇。
3. 项目状态保存在 Git 与上述项目文件中。`CLAUDE.md` 只导入本文件，换 IDE 不依赖宿主记忆。

## 开发

- 维护者直接说需求，主 Agent 判断独立新需求还是已有需求的补充：新需求由 AI 调用 `bash scripts/ai-task-pool.sh intake "原话"` 自动入队并按活跃 Spec、人工指定、收录顺序路由；补充用 `update <T-ID> "补充"`，已开始的任务同步修订 Spec 并回退门。新会话接手或归档后，若无活跃 Spec 且 `next` 指向待办，AI 用 `start-next` 原子选取并启动。维护者说“先做某项”时 AI 用 `prefer <T-ID>` 持久指定下一项；无活跃 Spec 时立即 `start-next`。旧 `docs/INTAKE.md` 保留历史。非平凡变更的需求、设计、任务与 WIP 写进 `process/specs/active/`。阶段门用 `bash scripts/ai-gate.sh check|pass <feat> <gate>`。G6 由 Agent 执行客观核验，②③只把需判断的风险和结果交给人决定；归档时更新 `process/metrics.md`。
- 修改脚手架脚本时编辑 `template/scripts/`，并跑 `bash scripts/harness-selftest.sh`。修改 `bin/` 时至少跑 Bash 语法检查与 `retrofit --dry-run` 冒烟。
- 开发中用 `bash scripts/ai-verify.sh --quick --spec <feat> <file>` 做短检查；G4 前去掉 `--quick` 跑正式验证，产出可交接的 `verification.md`。详细日志留本地；状态指纹全仓计算，只排除 `process/`。
- `template/AGENTS.md` 与 `template/.agents/skills/` 是交付给目标项目的规则和普通 Markdown 指南；改它们时同步检查 README、CLI 和自检。根目录规则只适用于本仓库开发。
- 老项目改造必须保护已有文件；参考 `template/.agents/skills/retrofit-legacy.md`。`--dry-run` 应保持只读。
- 新知识只记录经证据支持、下次能复用的结论；过期内容按 `template/.agents/skills/gc-memory.md` 清理。

## 命令

| 用途 | 命令 |
| :-- | :-- |
| 主 Agent 恢复现场 | `bash scripts/ai-resume.sh owner [feat]` |
| AI 收录 / 补充 / 指定下一项 | `bash scripts/ai-task-pool.sh intake "原话"` / `update <T-ID> "补充"` / `prefer <T-ID>` |
| 自动领取下一项 | `bash scripts/ai-task-pool.sh start-next` |
| 限定任务接手 | `bash scripts/ai-resume.sh worker <feat> <task-id>` |
| 独立审查接手 | `bash scripts/ai-resume.sh review <feat> <base-ref>` |
| 新建 Spec | `bash scripts/ai-new-spec.sh <feat>` |
| 门禁状态 | `bash scripts/ai-gate.sh status [feat]` |
| 增量验证 | `bash scripts/ai-verify.sh --spec <feat> <file>` |
| 开发快检 | `bash scripts/ai-verify.sh --quick --spec <feat> <file>` |
| 门间耗时 | `bash scripts/ai-gate.sh metrics <feat>` |
| 门禁自检 | `bash scripts/harness-selftest.sh` |
| 上下文体检 | `bash scripts/ai-check-bloat.sh` |

本地 TTY 和红线哈希只防误操作，不提供身份认证。需要强制审批时用代码托管平台的权限机制。
