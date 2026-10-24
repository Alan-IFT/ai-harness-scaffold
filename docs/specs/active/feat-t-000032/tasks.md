# 原子执行队列与接力：feat-t-000032

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000032` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`、`docs/architecture/modules/template-mechanism.md`、`cli.md`、`guidance.md`。
- 条件读：design §4 所列文件（只读改动处与调用者）。
- 明确不读：归档 Spec 全文。
- 注入知识：无相关卡片
- 知识检索：唯一卡 K-0001 讲被删的门禁正则写法，本 Spec 正是删除它，不注入。
- 本次不变量：K1~K16 行为不变；G3 记录保持 5 列；不改根目录 `harness/redlines.conf`；`--dry-run` 只读。

## 2. 原子任务序列

- [x] **Task 1: 门禁删减（D1 D2 D3 D4 D6）与自检**
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/harness/redlines.conf`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01, REQ-02, REQ-03, REQ-04, REQ-06, ERR-01 / AC-01, AC-02, AC-03
  - 对应设计：design.md §1、§2
  - 完成判据：自检全部通过，含新增 G2 / G6 结构化正反用例。
  - 验证命令：`bash scripts/harness-selftest.sh`

- [x] **Task 2: 知识卡删除（D5）**
  - 涉及文件：`template/scripts/ai-knowledge.sh`、`scripts/ai-knowledge.sh`、`template/scripts/ai-gate.sh`、`template/scripts/ai-new-spec.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`template/.knowledge/`、`template/docs/specs/_templates/knowledge-card.md`
  - 对应需求 / 验收：REQ-05 / AC-01, AC-03
  - 对应设计：design.md §1、§2
  - 完成判据：自检通过，第 11 节已删除，保留节断言仍在。
  - 验证命令：`bash scripts/harness-selftest.sh`

- [x] **Task 3: 模板与指南**
  - 涉及文件：`template/AGENTS.md`、`template/docs/specs/_templates/*.md`、`template/.agents/skills/*.md`、`template/harness/CI.md`、`template/MEMORY.md`
  - 对应需求 / 验收：REQ-02, REQ-07 / AC-06
  - 对应设计：design.md §1、§3
  - 完成判据：模板 acceptance 用新格式；`code-review.md` 有两项新检查；`ai-check-bloat.sh` 通过。
  - 验证命令：`bash scripts/ai-check-bloat.sh && bash scripts/harness-selftest.sh`

- [x] **Task 4: CLI upgrade 已删除托管文件**
  - 涉及文件：`bin/ai-harness`、`tests/cli-upgrade.sh`
  - 对应需求 / 验收：REQ-05, REQ-08, ERR-02 / AC-04
  - 对应设计：design.md §1、§2、§3
  - 完成判据：`tests/cli-upgrade.sh` PASS；`bash -n bin/ai-harness`；`retrofit --dry-run` 冒烟无写入。
  - 验证命令：`bash tests/cli-upgrade.sh`

- [x] **Task 5: 文档、本仓库状态与正式验证**
  - 涉及文件：`README.md`、`docs/architecture/modules/*.md`、`docs/architecture/00-INDEX.md`、`.knowledge/`
  - 对应需求 / 验收：REQ-05 / AC-01, AC-05, AC-06
  - 对应设计：design.md §1、§2
  - 完成判据：AC-01 关键字 `grep` 为空；正式验证 PASS 且耗时低于 363 秒。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000032 template/scripts/ai-gate.sh`

## 3. 发现但不碰

- 记录：根目录 `harness/redlines.conf` 仍有 `FEASIBILITY_MIN`、`KNOWLEDGE_TTL_DAYS` 两个无人读取的旧键（只允许人类修改，交付时提示维护者）。

## 4. Current WIP & Handoff

- 当前正在执行的任务：正式验证，之后 G5 独立审查（本会话 subagent）
- 前置依赖 / 并行关系：Task 2 依赖 Task 1；Task 3~5 依赖 Task 2
- 已完成的小步进展：Task 1~5 完成；`ai-gate.sh` 821→636 行，自检 1161→917 行；自检 215 项 0 失败（275 秒）；`tests/cli-upgrade.sh` PASS（含已删除托管文件 6 种情形）；AC-01 关键字 grep 为空；`retrofit --dry-run` 冒烟只读
- 正在编辑的文件：无
- 已排除的死胡同：upgrade 只报告不删除（旧指南会残留指导 Agent 建卡）
- 上次验证与未验证改动：自检与 CLI 回归已跑；`!` 取反断言改为 if 判断后 CLI 回归由正式验证复跑
- 下一步立即执行的唯一动作：正式验证 `bash scripts/ai-verify.sh --spec feat-t-000032 template/scripts/ai-gate.sh`
- knowledge_feedback：无
