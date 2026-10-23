# 原子执行队列与接力：feat-t-000013

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000013` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-gate.sh` 的 ck_g6、`.knowledge/cards/K-0001.md`、设计审查原型（会话 scratchpad 的 `scan.awk` 与 `all-cases.txt`，已在 design.md 记录规则）。
- 条件读：`template/scripts/harness-selftest.sh` 的 t-multi-ac G6 用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（多字节不进字符类、awk 出错不放宽、跨 awk 写法），直接相关，采用。
- 本次不变量：剥离与零计数豁免之外的关键词判断不变；不改 `redlines.conf`。

## 2. 原子任务序列

- [x] **Task 1: ai-gate.sh 的 G6 扫描程序与三处判断**
  - 涉及文件：`template/scripts/ai-gate.sh`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01, ERR-02, ERR-03 / AC-01, AC-02, AC-03
  - 对应设计：design.md §1、§2
  - 完成判据：扫描程序存于具名变量；三处关键词判断用 scan 结果，两处正向判定用 strip 结果；awk 失败不放宽。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000013 template/scripts/ai-gate.sh`

- [x] **Task 2: 自检 41 例矩阵与 G6 端到端用例，文档说明**
  - 涉及文件：`template/scripts/harness-selftest.sh`、`template/docs/specs/_templates/acceptance.md`、`docs/architecture/modules/template-mechanism.md`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01, ERR-02 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：41 例在 `LC_ALL=C` 与默认 locale 下按期望；端到端零计数放行、矛盾拒绝；去掉扫描后用例报出；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000013 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 独立 CR
- 前置依赖 / 并行关系：Task 2 依赖 Task 1
- 已完成的小步进展：G1~G3 通过；独立设计审查三轮，原型 41 例在 gawk、mawk、onetrue-awk 的两种 locale 下符合期望
- 正在编辑的文件：
  - `template/scripts/harness-selftest.sh`
- 已排除的死胡同：gsub 连带删除边界字符（可吞掉关键词）；正向判定直接匹配 `0 失败` 子串（可被「10 失败」命中）
- 上次验证与未验证改动：无 locale 正式验证 PASS（327s）；自检 245/245；旧 ai-gate 下新用例报出
- 下一步立即执行的唯一动作：新上下文 G5 审查
- knowledge_feedback：无
