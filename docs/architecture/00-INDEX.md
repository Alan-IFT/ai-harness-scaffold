# 本仓库架构索引

| 模块 | 代码路径 | 对外入口 | 活文档 |
| :-- | :-- | :-- | :-- |
| 接入技能 | `skill/**` | `skill/SKILL.md` | `docs/architecture/modules/install-skill.md` |
| 模板机制 | `template/scripts/**`, `template/harness/**`, `template/process/specs/_templates/**` | `template/scripts/*.sh` | `docs/architecture/modules/template-mechanism.md` |
| 项目指南 | `template/AGENTS.md`, `template/.agents/skills/**`, `skill/**`, `README.md` | `template/AGENTS.md` | `docs/architecture/modules/guidance.md` |
| 本仓库自用状态 | 根目录 `AGENTS.md`、`scripts/**`、`docs/**`、`process/**`、`harness/**` | `AGENTS.md` | `docs/architecture/modules/self-hosting.md` |

本索引用于定位当前代码，不描述模板中的示例业务模块。

## 架构决策记录

- `docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`：做减法，只保留跨宿主核心；功能清单、删除与简化决定、R1/R2 迁移（2026-10-23 已决定）。
- `docs/architecture/decisions/ADR-0003-three-gates-no-compat-code.md`：三道门（计划 / 验证 / 审查）替代 G1~G7，升级与迁移只写说明不写代码（2026-10-25 已决定）。
