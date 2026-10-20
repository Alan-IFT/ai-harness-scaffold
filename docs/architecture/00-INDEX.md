# 本仓库架构索引

| 模块 | 代码路径 | 对外入口 | 活文档 |
| :-- | :-- | :-- | :-- |
| CLI 与安装 | `bin/**` | `bin/ai-harness` | `docs/architecture/modules/cli.md` |
| 模板机制 | `template/scripts/**`, `template/harness/**`, `template/docs/specs/_templates/**` | `template/scripts/*.sh` | `docs/architecture/modules/template-mechanism.md` |
| 项目指南 | `template/AGENTS.md`, `template/.agents/skills/**`, `skill/**`, `README.md` | `template/AGENTS.md` | `docs/architecture/modules/guidance.md` |
| 本仓库自用状态 | 根目录 `AGENTS.md`、`scripts/**`、`docs/**`、`harness/**` | `AGENTS.md` | `docs/architecture/modules/self-hosting.md` |

本索引用于定位当前代码，不描述模板中的示例业务模块。
