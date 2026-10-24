# 原子执行队列与接力：feat-t-000027

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000027` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`、`docs/metrics.md`、暂缓与待办任务原件。
- 条件读：`template/scripts/*.sh`、`bin/ai-harness`（只取子命令、检查项与行数）；参考博客 `本地参考博客目录` 5 篇及配图（外部资料，只取原则）。
- 明确不读：归档 Spec 全文（只统计 `acceptance.md` 验收方式与 `.gates` 记录者）。
- 注入知识：无相关卡片
- 知识检索：全仓唯一卡 K-0001 讲门禁正则写法，本 Spec 只写决策文档，不注入；ADR-0002 决定删除知识卡系统。
- 本次不变量：不修改 `template/`、`bin/`、`scripts/`；取舍依据维护者委托与可核对证据。

## 2. 原子任务序列

- [x] **Task 1: 功能清单与证据**
  - 涉及文件：`docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`
  - 对应需求 / 验收：REQ-01, ERR-02 / AC-01
  - 对应设计：design.md §2
  - 完成判据：脚本子命令、各门检查项、CLI 子命令均在保留 / 删除 / 简化表中，每项有依据。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000027 docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`

- [x] **Task 2: 依据参考博客定稿决定**
  - 涉及文件：`docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`
  - 对应需求 / 验收：REQ-02, ERR-01 / AC-02
  - 对应设计：design.md §2
  - 完成判据：§1 列出博客原则 B1~B6；每项决定写依据；§5 记录委托原话；改判项写明理由。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000027 docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`

- [x] **Task 3: 迁移与任务分诊**
  - 涉及文件：`docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`、`docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`、`docs/architecture/00-INDEX.md`、`docs/task-pool/T-000015.md`、`docs/task-pool/T-000020.md`、`docs/task-pool/T-000025.md`、`docs/task-pool/T-000028.md`~`docs/task-pool/T-000033.md`、`docs/task-pool/NEXT`
  - 对应需求 / 验收：REQ-03, REQ-04 / AC-03, AC-04, AC-05
  - 对应设计：design.md §2
  - 完成判据：R1/R2 字段齐全且入口为 T-000032/T-000033；ADR-0001 被替代；暂缓 / 待办各有分诊；NEXT 为 T-000032；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000027 docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 维护者本人审查
- 前置依赖 / 并行关系：Task 2 依赖 Task 1；Task 3 依赖 Task 2
- 已完成的小步进展：ADR-0001 G6 未通过，回退 G1 改为减法；ADR-0002 依博客与仓库证据定稿；T-000032/T-000033 收录，T-000015/20/31 作废、29/30 合并，25/28 暂缓；NEXT=T-000032
- 正在编辑的文件：无
- 已排除的死胡同：ADR-0001 五阶段重组（两次下游升级）；草案中删除连续失败计数与 G4 追溯校验（博客实践支持，改判保留）
- 上次验证与未验证改动：正式验证 PASS（363 秒，ADR-0002 目标）
- 下一步立即执行的唯一动作：取得维护者审查结论并写 review.md
- knowledge_feedback：无
