# 任务与接力：feat-t-000031

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000031` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：博客里的大部分做法脚手架已有（三道门、独立审查、改善即批准、安全六项、发现但不碰、黄卡、脱敏、红线只由人改、记忆信号与晋升）。只补 6 处缺口，每处并进现有条目，不新增条目或文件：
  - 「三道闸」（800 行规则一文：PRD「上限 20」被任务概括成「一键全部收回」）→ 任务挂 AC 编号 + 动手前回读原文。
  - 「按依赖图排序」（端到端一文）→ new-spec Step 3 一句话。
  - 「复审只看增量」「AI 协作产物也要审」（800 行规则一文 4.4）→ code-review 现有条目各补半句。
  - 「门禁零用例假绿 TOTAL>0」（防翻车一文 Dry Run）→ verify.conf 注释一句。
  - 「少升级为规则」（800 行规则一文 3.5）→ AGENTS.md §4 现有「写成检查」句后补半句。
- 改动文件：`template/AGENTS.md`、`template/process/specs/_templates/tasks.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/code-review.md`、`template/harness/verify.conf`。
- 影响与风险：`ai-gate.sh` g1 只查「思路」与 `[ ] Task` 行，新增「对应验收」子项不影响校验；脚本、README、`skill/SKILL.md` 不涉及这些措辞（已 grep）。

## 2. 任务
- [x] Task 1：补 6 处说明
  - 对应验收：AC-01~AC-05
  - 涉及文件：`template/AGENTS.md`、`template/process/specs/_templates/tasks.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/code-review.md`、`template/harness/verify.conf`
  - 验证：按 AC 逐条 grep
- [x] Task 2：自检与体积
  - 对应验收：AC-06
  - 涉及文件：无新增
  - 验证：`bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`

## 3. 发现但不碰
- `template/AGENTS.md:31`「并告诉人」与 §3 歧义交人决定重复，可删（审查建议）
- `template/harness/verify.conf` 注释里的 pytest 退出码举例可去掉具体工具（审查建议）
- 「对应验收」无机械校验，反复漏写再考虑加检查（审查建议）

## 4. WIP 接力区
- 当前任务：无（待审查）
- 已完成：读完 5 篇博客全文与 45 张图，对照脚手架列出缺口
- 正在编辑的文件：无
- 已排除的方案：代码图谱 MCP、命中埋点钩子、变异测试、PRD 覆盖矩阵、按阶段 allowed_tools、mcp-lockfile、records.json 审计链、可行性 7 维打分、知识 TTL、按阶段选模型、快速通道、多维审查子 Agent（都会让脚手架变重或依赖特定平台）
- 下一步：独立审查 g3
