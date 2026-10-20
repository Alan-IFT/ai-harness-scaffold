# 本仓库的 AI 开发入口

这里是脚手架源码仓库。`template/` 是分发给目标项目的唯一机制源码；根目录的 `scripts/` 仅转发到 `template/scripts/`，不要在转发脚本里复制逻辑。

## 接手

1. 在仓库根目录运行 `bash scripts/ai-resume.sh [feat]`，读 `MEMORY.md`、当前 `docs/specs/active/<feat>/tasks.md` 与 `verification.md`，再看 `git status` / `git diff`。
2. 从 `docs/architecture/00-INDEX.md` 找到要改的部分。CLI、模板脚本、项目指南是不同模块；跨模块修改按需读多篇。
3. 项目状态保存在 Git 与上述项目文件中。`CLAUDE.md` 只导入本文件，换 IDE 不依赖宿主记忆。

## 开发

- 粗想法先保留在 `docs/INTAKE.md`；非平凡变更建 Spec，需求、设计、任务与 WIP 写进 `docs/specs/active/`。阶段门用 `bash scripts/ai-gate.sh check|pass <feat> <gate>`。G6 由 Agent 执行客观核验，②③只把需判断的风险和结果交给人决定；归档时更新 `docs/metrics.md`。
- 修改脚手架脚本时编辑 `template/scripts/`，并跑 `bash scripts/harness-selftest.sh`。修改 `bin/` 时至少跑 Bash 语法检查与 `retrofit --dry-run` 冒烟。
- 开发中用 `bash scripts/ai-verify.sh --quick --spec <feat> <file>` 做短检查；G4 前去掉 `--quick` 跑正式验证，产出可交接的 `verification.md`。详细日志留本地；状态指纹按 design §4 精确清单或保守全仓计算。
- `template/AGENTS.md` 与 `template/.agents/skills/` 是交付给目标项目的规则和普通 Markdown 指南；改它们时同步检查 README、CLI 和自检。根目录规则只适用于本仓库开发。
- 老项目改造必须保护已有文件；参考 `template/.agents/skills/retrofit-legacy.md`。`--dry-run` 应保持只读。
- 新知识只记录经证据支持、下次能复用的结论；过期内容按 `template/.agents/skills/gc-memory.md` 清理。

## 命令

| 用途 | 命令 |
| :-- | :-- |
| 恢复现场 | `bash scripts/ai-resume.sh [feat]` |
| 新建 Spec | `bash scripts/ai-new-spec.sh <feat>` |
| 门禁状态 | `bash scripts/ai-gate.sh status [feat]` |
| 增量验证 | `bash scripts/ai-verify.sh --spec <feat> <file>` |
| 开发快检 | `bash scripts/ai-verify.sh --quick --spec <feat> <file>` |
| 门间耗时 | `bash scripts/ai-gate.sh metrics <feat>` |
| 门禁自检 | `bash scripts/harness-selftest.sh` |
| 上下文体检 | `bash scripts/ai-check-bloat.sh` |

本地 TTY 和红线哈希只防误操作，不提供身份认证。需要强制审批时用代码托管平台的权限机制。
