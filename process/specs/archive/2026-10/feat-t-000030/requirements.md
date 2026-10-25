# 需求：feat-t-000030

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000030.md`（原始需求与更新）
- 原始问题 / 原话：重复处以它为准，但存在歧义的，就交给我来决策吧；把应该删除的删除掉，不要让脚手架变得臃肿、累赘，但不要删除好用的和必要的功能；其他的你来决策吧，拿不住的，就交给我来决策，但要给我讲清楚详细情况，方便我做决策
- 需人决定：否（只删重复说明、不删功能；拿不准的项在对话里交维护者）

## 1. 要做什么
- 做什么：收窄 Karpathy 原则的优先级（重复处以它为准、歧义交人），补齐原则 4 的计划示例；删掉 `template/AGENTS.md` 与阶段指南里重复的说明。
- 为谁做：接入脚手架后每个读 AGENTS.md 的 AI。
- 不做：不删脚本、命令和门禁功能；不改 `harness/redlines.conf`。

## 2. 验收标准
| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | §3 开头写明「重复处以它为准；有歧义或冲突时交人决定」，不再写「冲突时以它为准」 | `grep -n "重复处" template/AGENTS.md` |
| AC-02 | 原则 4 含计划格式示例 `1. [步骤] → 验证：[检查]` | `grep -n "验证：\[检查\]" template/AGENTS.md` |
| AC-03 | 删除 §5 命令速查、§2「门只查骗不过的信号」、§1.4、开头「能写成检查的写成检查」；被删表格中独有的命令在正文或阶段指南里仍可找到 | `grep -c "命令速查\|骗不过" template/AGENTS.md` 为 0；`grep -rn "ai-new-spec\|harness-selftest\|ai-resume.sh review\|ai-gate.sh status" template/AGENTS.md template/.agents/skills` 均有结果 |
| AC-04 | `new-spec.md` Step 0 不再复述 AGENTS.md §1.2 的任务池用法 | 阅读 `template/.agents/skills/new-spec.md` |
| AC-05 | 自检与体积检查通过 | `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh` |
