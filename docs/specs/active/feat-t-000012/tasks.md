# 原子执行队列与接力：feat-t-000012

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000012` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-gate.sh` 第 74~115 行与 ck_g1、`.knowledge/cards/K-0001.md`。
- 条件读：`template/scripts/harness-selftest.sh` 第 340~350 行 G1 用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（全角空格先归一），本任务为其覆盖关系补注释与用例，采用。
- 本次不变量：判定逻辑不变；不改 `redlines.conf`。

## 2. 原子任务序列

- [ ] **Task 1: 归一覆盖注释与原文入口用例** `[<<< CURRENT ACTIVE TASK]`
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01, ERR-01 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：注释到位；新用例通过且删 field_ok 归一后报出；自检与正式验证通过。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000012 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：Task 1
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过；已查清 field_ok 原文入口为 ck_g1 第 150、158、163 行
- 正在编辑的文件：
  - `template/scripts/ai-gate.sh`
- 已排除的死胡同：合并为单一归一函数（超出最小改动）
- 上次验证与未验证改动：尚未验证
- 下一步立即执行的唯一动作：在 section_body 与 field_ok 处加注释
- knowledge_feedback：无
