# 原子执行队列与跨工具接力棒 (Tasks & Handoff): {{FEATURE_NAME}}

- **需求文档**: `@docs/specs/active/{{FEATURE_NAME}}/requirements.md`
- **设计文档**: `@docs/specs/active/{{FEATURE_NAME}}/design.md`
- **当前阶段**: 以 `bash scripts/ai-gate.sh status {{FEATURE_NAME}}` 为准。`docs/specs/active/{{FEATURE_NAME}}/.gates` 由脚本维护，**禁止手改**。

## 0. 阶段门（G1~G7）
| 门 | 通过条件 | 推进方式 |
| :-- | :-- | :-- |
| G1 需求澄清 | 四项必答非空、待确认问题清零 | `bash scripts/ai-gate.sh pass {{FEATURE_NAME}} g1` |
| G2 验收标准 | AC 表有通过 / 不通过 / 量化证据 | `pass g2` |
| G3 方案设计 | 依赖序 + 文件清单 + 对抗自审 + 检查点 | `pass g3` |
| G4 实现完成 | 任务全 `[x]` 且最近一次增量验证 PASS | `pass g4` |
| G5 独立 CR | 独立上下文产出 `review.md`，关键问题 = 0 | `pass g5` |
| G6 人工验收 | 人类读需求 / 设计 / 重要代码 / 验收报告 | **人工交互终端** `pass g6 --by human` |
| G7 归档 | 按 `@.agents/skills/archive-spec.md` 归档 | `pass g7` |

## 1. 上下文清单（开工前先填，避免乱读）
- **必读**：`requirements.md`、`design.md`、本文件、目标模块活文档（1 篇）
- **条件读**（命中才读）：其他模块公共契约（`index.ts` / `types.ts`）、`harness/redlines.conf`（涉及阈值时）
- **明确不读**：`docs/specs/archive/**`、其他模块内部实现、全量测试输出
- **本次不变量**（改坏即视为回归，例如：「对外 API 路径不变」「旧数据无需迁移」）：

## 2. 原子任务序列 (Atomic Execution Queue)
> 铁律：
> 1. 每次只认领 **1 个** `[ ]`，粒度 5~15 分钟；单任务 >5 文件或跨 2 子系统必须拆。
> 2. TDD：先写 / 改测试 → 写实现 → `bash scripts/ai-verify.sh <file>` 通过。
> 3. 完成后：勾 `[x]` → 清空 WIP → 原子 commit（记 commit hash）。

- [ ] **Task 1: 定义数据结构与接口契约类型** `[<<< CURRENT ACTIVE TASK]`
  - **涉及文件**: `path/to/types.ts`
  - **对应需求 / 验收**: REQ-01 / AC-01
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh path/to/types.ts`
  - **检查点**: 无 / 有（第 N 步后暂停，等谁确认）

- [ ] **Task 2: 编写核心业务逻辑与单元测试 (TDD)**
  - **涉及文件**: `path/to/service.ts`, `path/to/service.test.ts`
  - **对应需求 / 验收**: REQ-01, ERR-01 / AC-01
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh path/to/service.test.ts`

- [ ] **Task 3: 暴露路由 / 控制器接口并完成收尾**
  - **涉及文件**: `path/to/controller.ts`
  - **完成判据**: 
  - **验证命令**: `bash scripts/ai-verify.sh path/to/controller.ts`
  - **收尾动作**: 阅读并执行 `@.agents/skills/code-review.md` 与 `@.agents/skills/archive-spec.md`

## 3. 发现但不碰（范围外问题，只记录不处理）
> 编码时发现的越界问题写在这里，**不要顺手改**。格式：位置 / 现象 / 本次不处理的原因 / 建议归属。

- 记录：

---

## 4. 🔄 Current WIP & Handoff Scratchpad (跨工具断点续传区)

> **致下一个接手的 AI Agent (Claude / Codex / DeepSeek)**：
> 上一个工具可能因额度耗尽（429）或超时中断。请结合 `git diff` 与本区继续，**严禁推倒重写已通过验证的代码**！

- **当前正在执行的任务**: `Task 1`
- **已完成的小步进展**: 尚未开始（随开发进度实时更新）
- **正在编辑的文件**（下一个 Agent 必须**重新读**这些文件，不要凭记忆）：
  - 
- **已排除的死胡同 / 错误方案 (勿重复踩坑)**: 无
- **下一步立即执行的唯一动作 (Next Immediate Action)**：按照 `design.md` 第 3.2 节定义接口类型并跑验证脚本。
- **knowledge_feedback**（若 `@MEMORY.md` 或模块活文档与代码不符，记在这里，GC 时降权）：
