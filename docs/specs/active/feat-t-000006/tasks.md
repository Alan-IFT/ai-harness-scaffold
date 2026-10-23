# 原子执行队列与接力：feat-t-000006

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000006` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/modules/template-mechanism.md`、`.knowledge/cards/K-0001.md`。
- 条件读：`template/scripts/ai-gate.sh` 的 quadrant / field_ok / section_body / ck_g3 / ck_g6，`ai-resume.sh` 第 40~55 行，`ai-state-id.sh` 第 30~40 行。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：K-0001
- 知识检索：`ai-knowledge.sh suggest 模板机制` 返回 K-0001（awk 多字节匹配与 locale），与本任务同类，采用。
- 本次不变量：UTF-8 下门禁结论不变；脚本不设置 LC_ALL / LANG；不改 `redlines.conf`。

## 2. 原子任务序列

- [x] **Task 1: ai-gate.sh 象限识别、G3 fail-closed 与全角空格归一**
  - 涉及文件：`template/scripts/ai-gate.sh`
  - 对应需求 / 验收：REQ-01, ERR-01 / AC-01, AC-03
  - 对应设计：design.md §2、§3.2
  - 完成判据：无 locale 下现有自检全过。
  - 验证命令：`env -u LC_ALL bash scripts/harness-selftest.sh`

- [x] **Task 2: ai-resume 与 ai-state-id 的冒号分隔**
  - 涉及文件：`template/scripts/ai-resume.sh`、`template/scripts/ai-state-id.sh`
  - 对应需求 / 验收：REQ-02, ERR-02 / AC-04
  - 对应设计：design.md §2
  - 完成判据：检查点 1 的两种 locale 结论一致。
  - 验证命令：`env -u LC_ALL bash scripts/harness-selftest.sh`

- [x] **Task 3: 自检字节 locale 回归**
  - 涉及文件：`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-03 / AC-02, AC-03, AC-04
  - 对应设计：design.md §2
  - 完成判据：新用例在旧脚本上失败、在新脚本上通过。
  - 验证命令：`env -u LC_ALL bash scripts/harness-selftest.sh`

- [ ] **Task 4: 活文档、知识卡与回归** `[<<< CURRENT ACTIVE TASK]`
  - 涉及文件：`docs/architecture/modules/template-mechanism.md`、`.knowledge/cards/K-0001.md`、`.knowledge/INDEX.md`
  - 对应需求 / 验收：REQ-01, REQ-03 / AC-01, AC-05
  - 对应设计：design.md §2、§4
  - 完成判据：两种 locale 自检 0 失败，正式验证 PASS，脚本中无强制 locale。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000006 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：`template/scripts/ai-task-pool.sh` `nonblank()` / 纯全角空格的需求原话在 C 下视为非空、UTF-8 下视为空 / 不是门禁判定、影响极小 / 如需处理另立任务。

## 4. Current WIP & Handoff

- 当前正在执行的任务：Task 4
- 前置依赖 / 并行关系：Task 3 依赖 Task 1、2；Task 4 依赖前三项
- 已完成的小步进展：G1~G3 通过；独立设计审查首轮需修改，已改入设计
- 正在编辑的文件：
  - `docs/architecture/modules/template-mechanism.md`、`.knowledge/cards/K-0001.md`
- 已排除的死胡同：脚本强制 LC_ALL（维护者否决）；只修自检（会掩盖缺陷）
- 上次验证与未验证改动：尚未验证
- 下一步立即执行的唯一动作：更新 template-mechanism.md 与 K-0001，然后在无 locale 环境下正式验证
- knowledge_feedback：无
