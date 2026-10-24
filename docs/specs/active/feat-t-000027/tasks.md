# 原子执行队列与接力：feat-t-000027

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000027` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`、`docs/metrics.md`、`docs/task-pool/T-000015.md`~`T-000027.md`。
- 条件读：`template/scripts/ai-gate.sh`、`ai-state-id.sh`、`ai-task-pool.sh`、`tests/verify-repo.sh`（只核对 ADR 引用的位置）。
- 明确不读：归档 Spec 全文（只读 review.md 结论与 metrics 行）。
- 注入知识：无相关卡片
- 知识检索：`ai-knowledge.sh suggest 模板机制` 只返回 K-0001（locale 无关的文本匹配），本 Spec 只写决策文档，不涉及脚本匹配，不注入。
- 本次不变量：不修改 `template/`、`bin/`、`scripts/`；架构结论只记录维护者明确决定。

## 2. 原子任务序列

- [ ] **Task 1: ADR 草案与独立审查**
  - 涉及文件：`docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`、`docs/architecture/00-INDEX.md`
  - 对应需求 / 验收：REQ-01, REQ-03 / AC-01, AC-03
  - 对应设计：design.md §2 步骤 1、2
  - 完成判据：四问题各有证据、不少于 2 个方案、代价与推荐；独立审查无关键问题。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000027 docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`

- [ ] **Task 2: 维护者逐项决定**
  - 涉及文件：`docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`
  - 对应需求 / 验收：REQ-02, ERR-01 / AC-02, AC-03
  - 对应设计：design.md §2 步骤 3
  - 完成判据：决定记录表四行均有决定与原话来源或经确认的待定；迁移表去掉依赖待定问题的阶段。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000027 docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`

- [ ] **Task 3: 待办分诊落地**
  - 涉及文件：`docs/task-pool/T-000015.md`~`docs/task-pool/T-000026.md`、`docs/task-pool/T-000028.md`、`docs/task-pool/NEXT`、新收录的阶段入口任务、`docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`
  - 对应需求 / 验收：REQ-04, ERR-02 / AC-04, AC-05
  - 对应设计：design.md §2 步骤 4、检查点
  - 完成判据：13 条补充与状态一致；阶段入口已收录并回填 ADR；`NEXT` 指向第一个阶段入口且它是唯一未关联待办；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000027 docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：Task 1（设计审查第 2 轮）
- 前置依赖 / 并行关系：Task 2 依赖 Task 1；Task 3 依赖 Task 2
- 已完成的小步进展：G1、G2 通过（审查首轮后回退重过）；ADR 已按首轮 6 项关键问题修订
- 正在编辑的文件：
  - `docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`
- 已排除的死胡同：隐藏目录 `.harness/` 作流程根（rg 默认跳过、与 `harness/` 混淆）；只用 update 追加分诊而不改队列状态（next 仍会领取旧任务）
- 上次验证与未验证改动：尚未验证
- 下一步立即执行的唯一动作：等设计审查第 2 轮结论
- knowledge_feedback：无
