# 原子执行队列与接力：feat-t-000007

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000007` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-gate.sh` 的 ck_g2、`.knowledge/cards/K-0001.md`。
- 条件读：`template/scripts/harness-selftest.sh` 的 t-vague 用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（词边界写法与 locale），直接相关，采用。
- 本次不变量：「大概率」与独立英文含糊词仍被拒；两种 locale 结论一致；不改 `redlines.conf`。

## 2. 原子任务序列

- [x] **Task 1: 英文标识符边界与「大概率」提示**
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`、`docs/architecture/modules/template-mechanism.md`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：新正反例按预期；两种 locale 自检全过；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000007 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 独立 CR
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过
- 正在编辑的文件：
  - `template/scripts/ai-gate.sh`
- 已排除的死胡同：把「大概率」加入放行复合词（维护者否决）
- 上次验证与未验证改动：无 locale 正式验证 PASS（248s）；两种 locale 自检 228/228；旧 ai-gate 跑新用例有 3 项不成立
- 下一步立即执行的唯一动作：新上下文运行 `ai-resume.sh review feat-t-000007 d7a07b4` 写 review.md
- knowledge_feedback：无
