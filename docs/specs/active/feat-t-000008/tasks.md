# 原子执行队列与接力：feat-t-000008

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000008` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/docs/specs/_templates/requirements.md` 第 48~51 行、`template/scripts/ai-gate.sh` 的 ck_g2 词表、`.knowledge/cards/K-0001.md`。
- 条件读：`template/scripts/harness-selftest.sh` 的 t-vague 用例。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001；自检抽取中文例子要遵守其「多字节字符不进字符类」，采用。
- 本次不变量：门禁判定不变；模板 4 个例子保留；不改 `redlines.conf`。

## 2. 原子任务序列

- [ ] **Task 1: 模板说明与词表一致性自检** `[<<< CURRENT ACTIVE TASK]`
  - 涉及文件：`template/docs/specs/_templates/requirements.md`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：一致性检查通过；沙箱删词时报出该词；两种 locale 自检全过；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000008 template/scripts/harness-selftest.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：Task 1
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过
- 正在编辑的文件：
  - `template/docs/specs/_templates/requirements.md`、`template/scripts/harness-selftest.sh`
- 已排除的死胡同：删除模板例子（维护者否决）
- 上次验证与未验证改动：尚未验证
- 下一步立即执行的唯一动作：改模板第 50 行
- knowledge_feedback：无
