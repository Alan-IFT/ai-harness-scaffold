# 项目指南

- **范围**：`template/AGENTS.md`（规则入口）、`template/.agents/skills/`（按阶段读的指南）、Spec 模板与 `README.md`。
- **为什么只写一份入口**：各 AI 工具都能读 `AGENTS.md`，`CLAUDE.md` 只做导入；规则写两份就会分叉。
- **为什么指南只引用配置键**：阈值以项目自己的 `harness/redlines.conf` 为准，指南里写死数字会和配置不一致。
- **为什么方案并进 tasks.md、人的决定并进 review.md**：`design.md` 与 `acceptance.md` 只被格式检查读过，真实缺陷都由独立审查发现（ADR-0003）。
- **为什么「需人决定：是」要先审方案**：编码后再推翻方案代价最高；任何宿主都能用新会话或 subagent 做这一步。
- **为什么编码原则用 Karpathy 准则原文**：维护者 2026-10-25 定下吸收原文，重复处以它为准，与流程、红线有歧义时交人决定；同一说法只留一处，指南不复述 AGENTS.md。
- **改动时**：同步检查 `skill/SKILL.md` 与自检，确保指南里的命令与脚本一致。
