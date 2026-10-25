# 需求：feat-t-000031

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000031.md`（原始需求与更新）
- 原始问题 / 原话：关于这几篇博客，看看是否有值得学习或借鉴取用的，只取用好用的、必要的部分，不取用会使脚手架变得累赘、臃肿的部分，好用的脚手架永远都是干净、整洁、设计完美的
- 需人决定：否（只在现有条目里补几句说明，不加脚本、配置键和文件；取舍结果在对话里交维护者）

## 1. 要做什么
- 做什么：从 5 篇博客（800 行规则、90 万行重构、防翻车指南、端到端研发流程、Claude 用法）里，只补脚手架还缺、且一两句话就能落地的做法：任务回到原文核对、任务按依赖排序、复审只看增量、审查 AI 协作产物、零用例假绿、规则升级门槛。
- 为谁做：接入脚手架后每个读 AGENTS.md 与阶段指南的 AI。
- 不做：不加脚本、配置键、新文件或新阶段；不引入代码图谱、命中埋点、变异测试、覆盖矩阵、沙箱与工具白名单、多维审查子 Agent 等重机制；不改 `harness/redlines.conf`。

## 2. 验收标准
| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 任务模板每个任务有「对应验收」字段；AGENTS.md §3 写明动手前回读原话与对应验收标准，任务描述只作索引，不一致以原文为准并告诉人 | `grep -n "对应验收" template/process/specs/_templates/tasks.md template/AGENTS.md` |
| AC-02 | `new-spec.md` 写明任务按依赖顺序排 | `grep -n "依赖顺序" template/.agents/skills/new-spec.md` |
| AC-03 | `code-review.md` 写明复审只核对上轮关键问题与修复本身；规则与文档检查含「一次性经验写成通用结论、混入个人调试信息」 | `grep -n "复审\|一次性经验" template/.agents/skills/code-review.md` |
| AC-04 | `verify.conf` 模板注释写明检查命令在零用例时必须失败 | `grep -n "零用例" template/harness/verify.conf` |
| AC-05 | AGENTS.md §4 写明反复出现又写不成检查的才提议进规则、由人决定 | `grep -n "由人决定" template/AGENTS.md` |
| AC-06 | 自检与体积检查通过，`template/AGENTS.md` 净增不超过 2 行 | `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`、`git diff --stat` |
