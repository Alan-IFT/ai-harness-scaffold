# Project AI Harness & Execution Protocol

> 本文件是跨 AI 工具（Claude Code / OpenAI Codex / OpenCode / DeepSeek / Cursor）的唯一全局指令源。
> 铁律：保持本文件精简（<120 行，由 `scripts/ai-check-bloat.sh` 强制）。模块级规则一律下沉到 `docs/architecture/modules/` 或 Linter。

## 0. 上下文分层（只加载当前层需要的东西）

| 层 | 内容 | 何时加载 | 预算 |
| :-- | :-- | :-- | :-- |
| **L1 常驻** | 本文件 + `@MEMORY.md` | 每个会话（工具自动注入） | 本文件 <120 行、MEMORY <150 行 |
| **L2 按阶段** | `.agents/skills/*.md`（只在对应阶段读）、`harness/redlines.conf` | 进入该阶段时 | 一次只读 1 篇 |
| **L3 按需** | 模块活文档、公共契约、ADR、当前 spec、验证报告 | 由任务路径与门禁决定 | 只读命中的那 1 篇 |

**禁止**：全库 `grep` 找线索；读 `docs/specs/archive/**`；读其他模块的内部实现；把全量测试输出贴进上下文。

## 1. 接力协议 (Session Start & Hot-Swap)
1. **恢复现场**：跑 `bash scripts/ai-resume.sh`，拿到活跃 spec、当前阶段门、未提交改动、上次验证结论。
2. **精准路由**：读 `@docs/architecture/00-INDEX.md`，按任务涉及的代码路径**只加载 1 篇**模块活文档。
3. **受控执行**：只认领 `tasks.md` 里 **1 个** `[ ]` 原子任务；**门禁未过不得开始编码**。

## 2. 质量门 G1~G7（由 `scripts/ai-gate.sh` 机械校验）
| 门 | 名称 | 通过条件 | 谁推进 |
| :-- | :-- | :-- | :-- |
| G1 | 需求澄清 | 四项必答非空、待确认问题清零 | Agent |
| G2 | 验收标准 | AC 表有通过 / 不通过 / 量化证据 | Agent |
| G3 | 方案设计 | 依赖序 + 文件清单 + 对抗自审 + 检查点 | Agent |
| G4 | 实现完成 | tasks 全部 `[x]`、最近一次增量验证 PASS | Agent |
| G5 | 独立 CR | 独立上下文产出 `review.md`，关键问题 = 0 | Agent（换上下文） |
| G6 | 人工验收 | 人类读需求 / 设计 / 重要代码 / 验收报告 | **人类**（AI 停下等） |
| G7 | 归档 | 已按 `archive-spec.md` 归档 | Agent |

- 推进：`bash scripts/ai-gate.sh check <feat> <gate>` → 通过后 `bash scripts/ai-gate.sh pass <feat> <gate>`。
- **人工门（G6）** 必须在交互终端执行；AI 不得用 `--force` 或改 `.gates` 绕过，失败就停。
- **红线不可自改**：`harness/redlines.conf` 只允许人类修改。改动会使基线漂移并阻断 pass，必须人工重跑 `ai-gate.sh baseline`。

## 3. 编码三纪律 (Engineering Discipline)
- **简单优先**：先写最简正确版；三行重复优于过早抽象；不引入"以后可能用得上"的抽象层/配置/依赖。
- **范围纪律**：只碰 `design.md` 文件清单内的文件；清单外的改进记入 `tasks.md` 的「发现但不碰」，不动手。
- **关键路径先测**：先给判断分支、核心计算、状态流转、幂等/并发写测试，再写实现；不写无断言测试来凑覆盖率。

## 4. 防膨胀与验证口径 (Anti-Bloat & Verification)
- **只读契约，不读实现**：跨模块只读目标模块的公共契约文件（`index.ts` / `types.ts` / 接口定义）。
- **验证口径**：本地只跑 `bash scripts/ai-verify.sh <file>`（增量、秒级）；全量测试 / 回归 / 覆盖率由 CI 跑，AI 只读汇总结论，**不把全量输出拉进上下文**。脚本在"没有任何真实检查"时会失败，这是故意的：未验证 ≠ 通过。
- **实时存盘**：每完成一个子步骤，立即更新 `tasks.md` 的 WIP 区（含「正在编辑的文件」）；每个 `[x]` 任务先验证再原子 commit。

## 5. 冷启动与模型分工
- 出现下列信号时，先写完 WIP（进度 / 正在编辑的文件 / 下一步），再开新会话，别在旧上下文里硬撑：同一目标反复失败 ≥3 次、需要推翻已定方案、明显变慢、接近上下文上限。
- 分工：强推理模型做需求澄清 / 方案设计 / 独立 CR / 复杂实现；弱模型做文档同步 / 冒烟 / 格式化 / 归档搬运。

## 6. 命令与技能速查
| 场景 | 命令 |
| :-- | :-- |
| 接手 / 恢复 | `bash scripts/ai-resume.sh` |
| 阶段门状态 | `bash scripts/ai-gate.sh status` |
| 校验 / 推进门 | `bash scripts/ai-gate.sh check\|pass <feat> <gate>` |
| 增量验证 | `bash scripts/ai-verify.sh <file>` |
| 新建 Spec | `bash scripts/ai-new-spec.sh <feat-name>` |
| 体积体检 | `bash scripts/ai-check-bloat.sh` |

**技能**：规划需求与设计 → `@.agents/skills/new-spec.md`；独立审查 → `@.agents/skills/code-review.md`；上线归档 → `@.agents/skills/archive-spec.md`；双周瘦身 → `@.agents/skills/gc-memory.md`。踩坑池 → `@MEMORY.md`。
