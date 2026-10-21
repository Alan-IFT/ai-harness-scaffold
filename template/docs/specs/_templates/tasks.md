# 原子执行队列与跨工具接力棒 (Tasks & Handoff): {{FEATURE_NAME}}

- **需求文档**: `docs/specs/active/{{FEATURE_NAME}}/requirements.md`
- **设计文档**: `docs/specs/active/{{FEATURE_NAME}}/design.md`
- 追溯版本：1（与 design.md 配套；旧 Spec 无此行仍沿用旧门禁）
- **当前阶段**: 以 `bash scripts/ai-gate.sh status {{FEATURE_NAME}}` 为准。`docs/specs/active/{{FEATURE_NAME}}/.gates` 由脚本维护，**禁止手改**。

## 0. 阶段门
以 `bash scripts/ai-gate.sh status {{FEATURE_NAME}}` 的 `.gates` 结果为准；规则见 `AGENTS.md`。此处只记未完成任务，不复制阶段表。回滚后用 `ai-gate.sh reset` 使受影响门失效。

## 1. 上下文清单（开工前先填，避免乱读）
- **必读**：`requirements.md`、`design.md`、本文件、涉及模块的活文档
- **条件读**（命中才读）：其他模块公共契约（`index.ts` / `types.ts`）、`harness/redlines.conf`（涉及阈值时）
- **明确不读**：`docs/specs/archive/**`、其他模块内部实现、全量测试输出
- **注入知识**（先检索后选择；过期或待验证的卡片不能注入）：
  - 注入知识：无相关卡片
> 有采用时把上行改成真实卡片 ID；G4 会核对卡片存在且有效。不要在「无相关卡片」行保留示例 ID。
> 先运行 `bash scripts/ai-knowledge.sh suggest <module>`，记录模块、候选及采用或排除理由；不能只写「无相关卡片」。
- 知识检索：
- **本次不变量**（改坏即视为回归，例如：「对外 API 路径不变」「旧数据无需迁移」）：

## 2. 原子任务序列 (Atomic Execution Queue)
> 铁律：
> 1. 每次只认领 **1 个** `[ ]`，粒度 5~15 分钟；单任务 >5 文件或跨 2 子系统必须拆。
> 2. 先写 / 改关键测试 → 写实现 → 开发中用 `ai-verify.sh --quick --spec {{FEATURE_NAME}} <file>`；G4 前用无 `--quick` 的正式验证。quick 不生成 G4 摘要。
> 3. 完成后：勾 `[x]` → 清空 WIP → 原子 commit。
> 4. 拆分出口：每个任务引用设计章节；实现入口：写代码前回读该章节和 requirements.md §2.3 的相关原文锚点。任务摘要与设计冲突时先修任务，不据摘要实现。

- [ ] **Task 1: 定义数据结构与接口契约类型** `[<<< CURRENT ACTIVE TASK]`
  - **涉及文件**: `path/to/types.ts`
  - **对应需求 / 验收**: REQ-01 / AC-01
  - **对应设计**: design.md §3.2
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh --spec {{FEATURE_NAME}} path/to/types.ts`
  - **检查点**: 无 / 有（第 N 步后暂停，等谁确认）

- [ ] **Task 2: 编写核心业务逻辑与单元测试 (TDD)**
  - **涉及文件**: `path/to/service.ts`, `path/to/service.test.ts`
  - **对应需求 / 验收**: REQ-01, ERR-01 / AC-01
  - **对应设计**: design.md §2、§3.2
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh --spec {{FEATURE_NAME}} path/to/service.test.ts`

- [ ] **Task 3: 暴露路由 / 控制器接口并完成收尾**
  - **涉及文件**: `path/to/controller.ts`
  - **对应需求 / 验收**: REQ-01 / AC-01
  - **对应设计**: design.md §2、§3.2
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh --spec {{FEATURE_NAME}} path/to/controller.ts`
  - **收尾动作**: 阅读并执行 `.agents/skills/code-review.md`、`.agents/skills/knowledge-distill.md` 与 `.agents/skills/archive-spec.md`

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
- **上次验证与未验证改动**: 看 `verification.md`；G4 前若代码内容变化，重跑正式验证。`ai-resume.sh` 会提示摘要是否过期。
- **下一步立即执行的唯一动作 (Next Immediate Action)**：按照 `design.md` 第 3.2 节定义接口类型并跑验证脚本。
- **knowledge_feedback**（若 `MEMORY.md` / 知识卡 / 模块活文档与代码不符，记在这里，GC 时降权）：
