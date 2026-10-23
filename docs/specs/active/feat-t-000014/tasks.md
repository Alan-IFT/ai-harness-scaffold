# 原子执行队列与接力：feat-t-000014

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000014` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`template/scripts/ai-state-id.sh`、`template/scripts/ai-verify.sh` 的正式目标检查、`harness-selftest.sh` 的 Git 指纹夹具。
- 条件读：`template/scripts/ai-task-pool.sh`（只确认目录与 `NEXT` 位置）。
- 明确不读：无关模块与归档 Spec 全文。
- 注入知识：无相关卡片
- 知识检索：`ai-knowledge.sh suggest 模板机制` 只返回 K-0001（locale 无关的文本匹配），本次只改 ASCII 路径前缀，不涉及多字节匹配，不注入。
- 本次不变量：流程记录之外的文件照常计入指纹；不改 `redlines.conf`；报错文案不变。

## 2. 原子任务序列

- [x] **Task 1: 指纹与正式验证目标排除任务池**
  - 涉及文件：`template/scripts/ai-state-id.sh`、`template/scripts/ai-verify.sh`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01, ERR-02 / AC-01, AC-02, AC-03, AC-04
  - 对应设计：design.md §1、§2 步骤 1
  - 完成判据：三处指纹排除与一处目标检查均含 `docs/task-pool/` 前缀；头部注释列出流程记录范围。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000014 template/scripts/ai-state-id.sh`

- [x] **Task 2: 自检用例与文档**
  - 涉及文件：`template/scripts/harness-selftest.sh`、`template/AGENTS.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/retrofit-legacy.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`
  - 对应需求 / 验收：REQ-01, REQ-02, ERR-01, ERR-02 / AC-01, AC-02, AC-03, AC-04, AC-05
  - 对应设计：design.md §2 步骤 2、3
  - 完成判据：新用例在两种 locale 下通过；去掉排除后用例报出；文档写明任务池属于流程记录；正式验证 PASS。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000014 template/scripts/ai-state-id.sh`

## 3. 发现但不碰

- 记录：无

## 4. Current WIP & Handoff

- 当前正在执行的任务：正式验证与 G5 独立 CR
- 前置依赖 / 并行关系：Task 2 依赖 Task 1
- 已完成的小步进展：G1~G3 通过（设计审查 2 轮）；三处指纹排除与目标检查已改；自检新增 11 例，默认与 `LC_ALL=C` 下均 258/258
- 正在编辑的文件：
  - `template/scripts/harness-selftest.sh`
- 已排除的死胡同：拷入 Git 夹具的任务池脚本若保持未跟踪，会成为未归属改动使精确清单用例回退全仓，故在取基线前提交
- 上次验证与未验证改动：检查点 1 三处单独变异——去掉未归属 case 报 1 例（精确清单）、去掉 pathspec 报 5 例（提交、未暂存、暂存、补充提交、删除）、去掉未跟踪 case 报 1 例（intake）
- 下一步立即执行的唯一动作：正式验证后提交摘要，进入 G5
- knowledge_feedback：无
