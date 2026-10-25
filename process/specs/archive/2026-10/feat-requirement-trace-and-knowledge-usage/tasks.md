# 任务与接力：feat-requirement-trace-and-knowledge-usage
- 追溯版本：1

- 需求文档：`docs/specs/active/feat-requirement-trace-and-knowledge-usage/requirements.md`
- 设计文档：`docs/specs/active/feat-requirement-trace-and-knowledge-usage/design.md`
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-requirement-trace-and-knowledge-usage` 为准。

## 0. 阶段门
按 G1~G7 执行；G3 前不编码。

## 1. 上下文清单
- 必读：本 Spec、模板机制与项目指南活文档、相关模板及脚本。
- 条件读：旧 Spec 样本、CLI 安装入口、自检夹具。
- 明确不读：无关归档 Spec 和详细报告。
- 注入知识：无相关卡片。
- 知识检索：`ai-knowledge.sh suggest template-mechanism` 与 `.knowledge/INDEX.md` 无有效卡片；采用源码和活文档。
- 本次不变量：旧 Spec 兼容；根目录脚本仍只转发；无手工计数副本。

## 2. 原子任务序列
- [x] Task 1：模板追溯字段与 G3/G4 检查。对应设计 §1、§2，REQ-01/02、AC-01/02；新旧 Spec 正反例通过。
  - 对应需求 / 验收：REQ-01、REQ-02 / AC-01、AC-02
  - 对应设计：design.md §1、§2
- [x] Task 2：扩展独立审查指南及相关 README。对应设计 §2，REQ-03、AC-03；G5 字段正反例通过。
  - 对应需求 / 验收：REQ-03 / AC-03
  - 对应设计：design.md §2
- [x] Task 3：知识使用派生统计、索引去计数与自检。对应设计 §1、§2，REQ-04、ERR-02、AC-04；G4 过滤、去重和归档样本通过。
  - 对应需求 / 验收：REQ-04、ERR-02 / AC-04
  - 对应设计：design.md §1、§2
- [x] Task 4：分发/兼容验证、活文档同步、正式验证。对应设计 §2、§4，ERR-01、AC-05；139/139 自检、quick 和 retrofit dry-run 通过，正式验证见 verification.md。
  - 对应需求 / 验收：ERR-01 / AC-05
  - 对应设计：design.md §2、§4

## 3. 发现但不碰
- 无。

## 4. Current WIP & Handoff Scratchpad
- 当前正在执行的任务：G1~G7 已完成，待 Git 提交。
- 前置依赖 / 并行关系：顺序执行。
- 已完成的小步进展：G1~G6 已通过；首轮 CR 的 3 项关键问题均修复，第二轮 CR 关键问题 0、判定通过；用户决定验收通过。
- 正在编辑的文件：无。
- 已排除的死胡同 / 错误方案：不引入 hook 或额外数据库。
- 上次验证与未验证改动：修复后正式验证 PASS，完整自检 139/139；此后仅更新 Spec 交接文字，无源码改动。
- 下一步立即执行的唯一动作：完成收尾体检与 Git 提交。
- knowledge_feedback：无。
