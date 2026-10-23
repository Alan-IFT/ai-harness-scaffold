# 原子执行队列与接力：feat-t-000011

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000011` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-gate.sh` 第 495~512 行、`template/.agents/skills/retrofit-legacy.md` 第 21 行。
- 条件读：`template/scripts/harness-selftest.sh` 第 505~515 行委托用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：无相关卡片
- 知识检索：`ai-knowledge.sh suggest 模板机制` 只返回 K-0001（locale 匹配写法），本任务只改文案，与之无关，排除。
- 本次不变量：委托快照比对与哈希代码不变；不改 `redlines.conf`。

## 2. 原子任务序列

- [ ] **Task 1: G6 升级提示与升级说明** `[<<< CURRENT ACTIVE TASK]`
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/.agents/skills/retrofit-legacy.md`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：提示断言通过；原委托用例照旧；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000011 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：Task 1
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过
- 正在编辑的文件：
  - `template/scripts/ai-gate.sh`
- 已排除的死胡同：G6 同时接受新旧快照（维护者否决）
- 上次验证与未验证改动：尚未验证
- 下一步立即执行的唯一动作：改 ai-gate.sh 第 507 行文案
- knowledge_feedback：无
