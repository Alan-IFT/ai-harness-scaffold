# 执行队列：feat-task-pool

- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-task-pool` 为准。

## 1. 上下文清单
- 必读：本 Spec、模板机制、项目指南和本仓库自用架构文档。
- 条件读：`ai-new-spec.sh` 与 `ai-resume.sh` 契约。
- 注入知识：无相关卡片
- 知识检索：运行 `ai-knowledge.sh suggest template-mechanism`；当前索引无卡片，故不注入。
- 本次不变量：根目录脚本只转发；旧 INTAKE 历史不改；retrofit 不覆盖。

## 2. 原子任务序列
- [x] **Task 1: 任务记录与领取脚本**
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/docs/task-pool/README.md`
  - 对应需求 / 验收：REQ-01、REQ-02、REQ-03、REQ-04、ERR-01、ERR-02、AC-01、AC-02、AC-03
  - 对应设计：§1、§3
  - 完成判据：状态流转与拒绝路径可运行。
- [x] **Task 2: 接手提示与自检**
  - 涉及文件：`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`scripts/ai-task-pool.sh`
  - 对应需求 / 验收：REQ-03、ERR-01、ERR-02、AC-02、AC-03、AC-04
  - 对应设计：§2、§3
  - 完成判据：正反例通过，根目录只转发。
- [x] **Task 3: 指南与本仓库自用**
  - 涉及文件：`template/AGENTS.md`、`AGENTS.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/retrofit-legacy.md`、`template/docs/specs/_templates/requirements.md`、`template/docs/INTAKE.md`、`docs/INTAKE.md`、`docs/task-pool/README.md`、`docs/task-pool/T-000001.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`
  - 对应需求 / 验收：REQ-01、REQ-02、REQ-03、REQ-04、AC-04
  - 对应设计：§2、§4
  - 完成判据：新会话与新项目说明一致，正式验证通过。

## 3. 发现但不碰
- 无。

## 4. WIP
- 当前正在执行的任务：无；实现、指南和自检样本已完成。
- 已完成的小步进展：168 项自检通过；快检、retrofit 只读预演和上下文体检通过。最新改动为活跃 Spec 启动保护，待最终正式验证。
- 正在编辑的文件：无。
- 上次验证与未验证改动：上一轮自检 168/168；最终正式验证未运行。
- 下一步立即执行的唯一动作：运行正式 `ai-verify.sh --spec feat-task-pool template/scripts/ai-task-pool.sh`。
