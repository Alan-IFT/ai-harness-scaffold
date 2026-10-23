# 原子执行队列与接力：feat-t-000009

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000009` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-gate.sh` 的 ck_g2、`template/scripts/harness-selftest.sh` 的 t-vague 用例组、`.knowledge/cards/K-0001.md`。
- 条件读：`docs/architecture/modules/template-mechanism.md`。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（awk 出错须按未通过处理、可移植写法），直接相关，采用。
- 本次不变量：门禁判定不变；不改 `redlines.conf`。

## 2. 原子任务序列

- [x] **Task 1: G2 四类自检用例与跨 awk 实测记录**
  - 涉及文件：`template/scripts/harness-selftest.sh`、`docs/architecture/modules/template-mechanism.md`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01, ERR-02 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：4 项用例按预期；逐项破坏后对应用例报出；活文档记录 mawk 与 onetrue-awk 实测；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000009 template/scripts/harness-selftest.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 独立 CR
- 前置依赖 / 并行关系：无
- 已完成的小步进展：G1~G3 通过；调查阶段已在 WSL mawk 1.3.4 与 Docker onetrue-awk 20250116 下跑通现有自检 230/230
- 正在编辑的文件：
  - `template/scripts/harness-selftest.sh`
- 已排除的死胡同：wsl.exe 直接传 `bash -c` 会被 WSL 默认 shell 提前展开变量；Git Bash 会改写 `/mnt/c` 路径，需 `MSYS_NO_PATHCONV=1` 并用脚本文件
- 上次验证与未验证改动：无 locale 正式验证 PASS（256s）；自检 235/235；四处逻辑逐项改坏后对应用例均报出
- 下一步立即执行的唯一动作：新上下文运行 `ai-resume.sh review feat-t-000009 8471ce8` 写 review.md
- knowledge_feedback：无
