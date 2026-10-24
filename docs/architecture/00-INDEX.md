# 本仓库架构索引

| 模块 | 代码路径 | 对外入口 | 活文档 |
| :-- | :-- | :-- | :-- |
| CLI 与安装 | `bin/**` | `bin/ai-harness` | `docs/architecture/modules/cli.md` |
| 模板机制 | `template/scripts/**`, `template/harness/**`, `template/docs/specs/_templates/**` | `template/scripts/*.sh` | `docs/architecture/modules/template-mechanism.md` |
| 项目指南 | `template/AGENTS.md`, `template/.agents/skills/**`, `skill/**`, `README.md` | `template/AGENTS.md` | `docs/architecture/modules/guidance.md` |
| 本仓库自用状态 | 根目录 `AGENTS.md`、`scripts/**`、`docs/**`、`harness/**` | `AGENTS.md` | `docs/architecture/modules/self-hosting.md` |

本索引用于定位当前代码，不描述模板中的示例业务模块。

## 架构决策记录

- `docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`：流程状态布局与指纹、自然语言门禁、验证结构、任务分诊（已被 ADR-0002 替代，问题分析仍可参考）。
- `docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`：做减法，只保留跨宿主核心；功能清单、删除与简化决定、R1/R2 迁移（2026-10-23 已决定）。
