# 原子执行队列与跨工具接力棒 (Tasks & Handoff): feat-t-000033

- **需求文档**: `docs/specs/active/feat-t-000033/requirements.md`
- **设计文档**: `docs/specs/active/feat-t-000033/design.md`
- 追溯版本：1（与 design.md 配套；旧 Spec 无此行仍沿用旧门禁）
- **当前阶段**: 以 `bash scripts/ai-gate.sh status feat-t-000033` 为准。`docs/specs/active/feat-t-000033/.gates` 由脚本维护，**禁止手改**。

## 0. 阶段门
以 `bash scripts/ai-gate.sh status feat-t-000033` 的 `.gates` 结果为准；规则见 `AGENTS.md`。此处只记未完成任务，不复制阶段表。回滚后用 `ai-gate.sh reset` 使受影响门失效。

## 1. 上下文清单（开工前先填，避免乱读）
- **必读**：`requirements.md`、`design.md`、本文件、涉及模块的活文档
- **条件读**（命中才读）：`bin/ai-harness` 的 `cmd_upgrade`（Task 3）、`tests/cli-upgrade.sh`、ADR-0002 §3.3
- **明确不读**：`docs/specs/archive/**`（迁移后为 `process/specs/archive/**`）、全量测试输出
- **相关记忆**（`MEMORY.md` 中与本任务有关的条目；没有写「无」）：无
- **本次不变量**（改坏即视为回归）：门禁 G1~G7 行为不变；任务池命令行为不变；根目录 `harness/redlines.conf` 不改；归档 Spec 与任务原文内容原样移动；`--dry-run` 只读。

## 2. 原子任务序列 (Atomic Execution Queue)
> 铁律：
> 1. 每次只认领 **1 个** `[ ]`，粒度 5~15 分钟；单任务 >5 文件或跨 2 子系统必须拆。
> 2. 先写 / 改关键测试 → 写实现 → 开发中用 `ai-verify.sh --quick --spec feat-t-000033 <file>`；G4 前用无 `--quick` 的正式验证。quick 不生成 G4 摘要。
> 3. 完成后：勾 `[x]` → 清空 WIP → 原子 commit。
> 4. 拆分出口：每个任务引用设计章节；实现入口：写代码前回读该章节和 requirements.md §2.3 的相关原文锚点。任务摘要与设计冲突时先修任务，不据摘要实现。

- [ ] **Task 1: 指纹简化为全仓模式（仍用旧路径）** `[<<< CURRENT ACTIVE TASK]`
  - **涉及文件**: `template/scripts/ai-state-id.sh`、`template/scripts/harness-selftest.sh`
  - **对应需求 / 验收**: REQ-02 / AC-02
  - **对应设计**: design.md §1、§2、§3.2
  - **完成判据**: scoped 函数与分支全部删除；`--spec` 与无参数指纹相同；自检全过
  - **验证命令**: `bash scripts/harness-selftest.sh`

- [ ] **Task 2: 路径迁移到 process/ 与本仓库自迁移（同一提交）**
  - **涉及文件**: `template/scripts/*.sh`、`template/process/**`（`git mv`）、`template/harness/redlines.conf`、`template/.gitignore`、`template/.cursorignore`、`template/.claudeignore`、`process/**`（`git mv`）、`.gitignore`、`scripts/ai-new-spec.sh`、`AGENTS.md`、`MEMORY.md`、`docs/architecture/00-INDEX.md`
  - **对应需求 / 验收**: REQ-01, REQ-02, REQ-03, ERR-02 / AC-01, AC-02, AC-04, AC-05
  - **对应设计**: design.md §1、§2、§3.2、§4
  - **完成判据**: 自检全过（含 `process/` 与 `process-x/` 指纹断言、旧布局守卫断言）；`ai-gate.sh status feat-t-000033` 与 `ai-task-pool.sh list` 在本仓库正常
  - **验证命令**: `bash scripts/harness-selftest.sh && bash scripts/ai-gate.sh status feat-t-000033`
  - **检查点**: 有（检查点 1，Agent 自查后再进入 Task 3）

- [ ] **Task 3: upgrade 迁移下游与 2.0.0**
  - **涉及文件**: `bin/ai-harness`、`tests/cli-upgrade.sh`
  - **对应需求 / 验收**: REQ-04, REQ-05, ERR-01 / AC-03, AC-05
  - **对应设计**: design.md §1、§2、§3.2、§3.3
  - **完成判据**: 五个迁移用例通过；`bash -n` 通过；`retrofit --dry-run` 冒烟只读
  - **验证命令**: `bash -n bin/ai-harness && bash tests/cli-upgrade.sh`
  - **检查点**: 有（检查点 2，人工看一遍迁移输出文案）

- [ ] **Task 4: 指南、README 与活文档同步**
  - **涉及文件**: `template/AGENTS.md`、`template/.agents/skills/*.md`、`template/process/specs/_templates/*.md`、`template/docs/**`、`README.md`、`skill/SKILL.md`、`docs/architecture/modules/*.md`、ADR-0002
  - **对应需求 / 验收**: REQ-01 / AC-01
  - **对应设计**: design.md §2、§4
  - **完成判据**: AC-01 的 `grep` 在 `template/`、`scripts/`、`skill/`、`README.md`、`AGENTS.md` 中无命中；`retrofit-legacy.md` 写明迁移、拒绝条件、红线提示与回滚
  - **验证命令**: `grep -rn 'docs/specs\|docs/metrics\|docs/task-pool' template scripts skill README.md AGENTS.md`

- [ ] **Task 5: 正式验证与收尾**
  - **涉及文件**: `process/specs/active/feat-t-000033/verification.md`
  - **对应需求 / 验收**: AC-06
  - **对应设计**: design.md §2
  - **完成判据**: 正式验证 PASS，`verification.md` 摘要有效
  - **验证命令**: `bash scripts/ai-verify.sh --spec feat-t-000033 template/scripts/ai-state-id.sh`
  - **收尾动作**: 阅读并执行 `.agents/skills/code-review.md` 与 `.agents/skills/archive-spec.md`

## 3. 发现但不碰（范围外问题，只记录不处理）
> 编码时发现的越界问题写在这里，**不要顺手改**。格式：位置 / 现象 / 本次不处理的原因 / 建议归属。

- 记录：

---

## 4. 🔄 Current WIP & Handoff Scratchpad (跨工具断点续传区)

> **致下一个接手的 AI Agent (Claude / Codex / DeepSeek)**：
> 上一个工具可能因额度耗尽（429）或超时中断。请结合 `git diff` 与本区继续，**严禁推倒重写已通过验证的代码**！

- **当前正在执行的任务**: `Task 1`
- **前置依赖 / 并行关系**: 无（并行任务须写明依赖和各自负责的文件）
- **已完成的小步进展**: 尚未开始（随开发进度实时更新）
- **正在编辑的文件**（下一个 Agent 必须**重新读**这些文件，不要凭记忆）：
  - 
- **已排除的死胡同 / 错误方案 (勿重复踩坑)**: 无
- **上次验证与未验证改动**: 看 `verification.md`；G4 前若代码内容变化，重跑正式验证。`ai-resume.sh owner <feat>` 会提示摘要是否过期；G5 用 `review <feat> <base-ref>` 检查审查证据。
- **下一步立即执行的唯一动作 (Next Immediate Action)**：开始 Task 1（指纹简化）。
- **knowledge_feedback**（若 `MEMORY.md`、规则或模块活文档与代码不符，记在这里，GC 时修正或删除）：
