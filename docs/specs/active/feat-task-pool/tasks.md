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
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/ai-new-spec.sh`、`template/docs/task-pool/README.md`
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
- [x] **Task 4: 已安装项目安全升级**
  - 涉及文件：`bin/ai-harness`、`tests/cli-upgrade.sh`、`harness/verify.conf`
  - 对应需求 / 验收：REQ-05、REQ-06、ERR-03、AC-05
  - 对应设计：§1、§2、§3
  - 完成判据：新旧安装、未改动更新、定制冲突/确认、dry-run 和不安全路径样本通过。
- [x] **Task 5: 升级指南与重新交付**
  - 涉及文件：`README.md`、`skill/SKILL.md`、`template/AGENTS.md`、`template/.agents/skills/retrofit-legacy.md`、`docs/architecture/modules/cli.md`、本 Spec 验收与验证
  - 对应需求 / 验收：REQ-05、REQ-06、AC-05
  - 对应设计：§4
  - 完成判据：说明、正式验证、独立复审与 G5 重新通过。

## 3. 发现但不碰
- 无。

## 4. WIP
- 当前正在执行的任务：无；Task 4、5 的实现与指南已完成，待正式验证和独立复审。
- 已完成的小步进展：原任务池正式验证 184/184；新增升级 CLI 临时项目回归 PASS，Bash 语法、retrofit 只读预演和 bloat 通过；新增需求的 G1~G3 已重过。
- 正在编辑的文件：本 Spec 的验证与验收记录。
- 上次验证与未验证改动：旧 `verification.md` 仅覆盖任务池；升级实现已通过专门回归，尚未跑全量正式验证。
- 下一步立即执行的唯一动作：暂存完整改动后正式验证，再独立复审并核对 AC。
