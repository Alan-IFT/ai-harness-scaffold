# 原子执行队列与接力：feat-t-000010

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000010` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-task-pool.sh` 第 25~30 行与第 110~150 行、`.knowledge/cards/K-0001.md`。
- 条件读：`template/scripts/harness-selftest.sh` 第 930~950 行任务池用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（全角空格先归一），直接相关，采用。
- 本次不变量：含文字的原话与补充照常处理；不改 `redlines.conf`。

## 2. 原子任务序列

- [x] **Task 1: nonblank 全角空格归一与自检**
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01, ERR-01 / AC-01, AC-02, AC-03
  - 对应设计：design.md §2
  - 完成判据：两项新用例按预期；旧函数下报出；自检全部通过；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000010 template/scripts/ai-task-pool.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 独立 CR
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过；修法已在 C 与 C.UTF-8 下实测
- 正在编辑的文件：
  - `template/scripts/ai-task-pool.sh`
- 已排除的死胡同：无
- 上次验证与未验证改动：无 locale 正式验证 PASS；自检 237/237；旧 nonblank 下两项新用例报出（另有因空任务占号导致的连锁失败）
- 下一步立即执行的唯一动作：新上下文运行 `ai-resume.sh review feat-t-000010 HEAD~1` 写 review.md
- knowledge_feedback：无
