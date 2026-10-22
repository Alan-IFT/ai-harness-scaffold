# 原子执行队列与接力：feat-t-000003

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000003` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/00-INDEX.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`。
- 条件读：G1 与任务池脚本、红线样本、README、CI 指南。
- 明确不读：无关业务模块和归档 Spec 全文。
- 注入知识：无相关卡片。
- 知识检索：`ai-knowledge.sh suggest guidance` 返回无有效候选；已读模块活文档与真实模板。
- 本次不变量：不修改 `redlines.conf`、门禁脚本或自动任务池行为；旧 Spec 不新增必填门槛。

## 2. 原子任务序列

- [x] **Task 1: 需求目标与关键前提**
  - 涉及文件：`template/docs/specs/_templates/requirements.md`、`template/docs/specs/_templates/design.md`、`template/.agents/skills/new-spec.md`
  - 对应需求 / 验收：REQ-01, REQ-02 / AC-01
  - 对应设计：design.md §2
  - 完成判据：有行动、效果、观察信号与低成本证伪提示；不新增门禁。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000003 README.md`

- [x] **Task 2: 验收、后续问题与评分/CI 说明**
  - 涉及文件：`template/docs/specs/_templates/acceptance.md`、`template/.agents/skills/archive-spec.md`、`template/harness/CI.md`、`template/docs/specs/_templates/requirements.md`
  - 对应需求 / 验收：REQ-03, REQ-04, ERR-01, ERR-02 / AC-02, AC-03
  - 对应设计：design.md §2
  - 完成判据：观察证据可用；候选问题不自动入队；固定权重及单项门槛、CI 接线责任准确。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000003 README.md`

- [x] **Task 3: 同步说明并完成回归**
  - 涉及文件：`README.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`、`docs/PROPOSAL-2026-10-blog-ai-ambition.md`
  - 对应需求 / 验收：REQ-01, REQ-04 / AC-04
  - 对应设计：design.md §2
  - 完成判据：文档相互一致，自检与正式验证通过。
  - 验证命令：`bash scripts/harness-selftest.sh`、`bash scripts/ai-verify.sh --spec feat-t-000003 README.md`

## 3. 发现但不碰

- 暂无。

## 4. Current WIP & Handoff Scratchpad

- 当前正在执行的任务：无；独立 CR 已通过，待记录 G5 与完成 G6。
- 前置依赖 / 并行关系：先更新模板，再同步指南与回归。
- 已完成的小步进展：Task 1~3 内容完成；两处审查问题已修复，G1~G4 重过；最终正式验证 PASS（自检 210/210、CLI 回归 PASS），独立 CR 第 2 轮关键问题 0。
- 正在编辑的文件：无。
- 已排除的死胡同 / 错误方案：仅加红线注释无法解决 CI 未接线；删除权重校验会造成评分失真。
- 上次验证与未验证改动：最终 `verification.md` state 已与当前 Git 内容匹配；之后仅更新 Spec 流程记录，未改交付文件。
- 下一步立即执行的唯一动作：记录 G5，通过客观 G6 核验后呈交维护者判断。
- knowledge_feedback：无。
