---
name: ai-harness-scaffold
description: 给已有代码项目渐进接入 ai-harness 跨 IDE 开发脚手架，或初始化新项目。用户说“把这个老项目接入脚手架”“用这套规范管理开发”等话时使用；先摸底、保护原文件，再由 AI 完成安装和验证。
version: 1.2.0
---

# ai-harness-scaffold

以本技能文件定位共享仓库：若同目录有 `bin/ai-harness`，该目录就是仓库根；否则取本文件的上一级目录。确认 `bin/ai-harness` 和 `template/.agents/skills/retrofit-legacy.md` 存在；缺失时停止并报告路径，不凭记忆重建流程。

用户一句话指定老项目路径时，读取共享的 `template/.agents/skills/retrofit-legacy.md` 并执行其中的渐进接入；新项目则读仓库 `README.md` 的 init 流程。目标项目路径不明确时，先从当前项目上下文定位；只有多个候选且无法判定时才询问。

老项目先只读侦察 Git 状态、现有规则与 CI，再运行 `bash <仓库根>/bin/ai-harness retrofit <目标> --dry-run --no-git`。核对预演计划后由 AI 继续运行 `retrofit <目标> --skip-doctor --no-git`，逐项合并 `.ai-harness/suggested/`；只为一个真实试点模块写活文档、配置真实验证命令并运行体检。不要覆盖已有文件、清理未提交改动、补造历史 Spec，或把目录候选当作模块事实。

若目标已有 `.ai-harness/version`，先改用 `upgrade <目标> --dry-run` 查看升级计划，再运行 `upgrade <目标>`；自动更新未改动的机制文件并补缺。冲突保留目标文件，合并建议后逐文件用 `--accept-custom <相对路径>` 记录定制基线。无 manifest 的旧安装只自动补缺，不覆盖不同内容。项目状态和红线不自动替换。

用户负责架构、权限和阈值等真正需要人的取舍；AI 负责运行命令、编写项目文档和验证。项目内 `AGENTS.md`、Spec、活文档与 Git 是后续 Claude Code / Codex 接力状态。最后报告已接入内容、实际验证、冲突处理及尚需决定的事项。
