# 接入技能

- **职责**：`skill/SKILL.md` 描述新项目接入、老项目渐进接入与收尾检查；升级与降级在 `template/.agents/skills/upgrade.md`。没有安装命令，由 AI 按说明判断执行。
- **边界**：只装 `git ls-files template` 列出的文件；不覆盖已有文件、不删除、不自动改红线；目标项目的模块边界、公共契约和权限须基于证据确认，目录名只是候选。
- **为什么不做 CLI**：2.0 曾有约 750 行 `bin/ai-harness`（init / retrofit / upgrade / doctor / install-skill）。命令行规则死板，老项目的特殊情况处理不了，最后还是要 AI 合并冲突、选验证命令和试点模块；维护者 2026-10-25 决定只保留技能说明（ADR-0003）。
- **验证**：改 `skill/SKILL.md` 后，按它在临时目录实际接入一次新项目，确认 `harness-selftest.sh`、`ai-check-bloat.sh` 与 `ai-gate.sh status` 通过。
