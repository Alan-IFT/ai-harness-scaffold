# 技术设计：feat-requirement-trace-and-knowledge-usage

- 关联需求：requirements.md（G1/G2 已通过）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联
- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`；本仓库自用 → `docs/architecture/modules/self-hosting.md`
- 契约入口：`template/scripts/ai-gate.sh`、`template/scripts/ai-knowledge.sh` 和 `template/AGENTS.md`
- 人工前置决策：决策人 维护者；取舍为按上轮三项建议实施、保留现有 G1~G7；结论为用户本轮「按照建议方案来改动」。

## 1. 架构变更与数据流
新 Spec 的需求表给出稳定 REQ/ERR/AC ID；设计表逐项映射到设计章节并标记语义敏感原文；任务引用设计章节及需求 ID；G5 从原文反查实现。旧 Spec 不要求补写。
知识采用量只从 active/archive Spec 的 tasks.md「注入知识」行派生，每张卡每个 Spec 至多计一次；INDEX 不存手工计数。

### 1.1 需求覆盖矩阵
| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 每项须有落点 | §1、§2 | AC-01 |
| REQ-02 | 回读原文 | §1、§2 | AC-02 |
| REQ-03 | 扩审查输入 | §1、§2 | AC-03 |
| REQ-04 | 由 Spec 派生 | §1、§2 | AC-04 |
| ERR-01 | 旧 Spec 兼容 | §2 | AC-05 |
| ERR-02 | 同一 Spec 去重 | §1、§2 | AC-04 |
| AC-01 | 缺映射拒绝 | §2 | 自检 |
| AC-02 | 防语义转述 | §2 | 模板检查 |
| AC-03 | 审查扩展 | §2 | 指南检查 |
| AC-04 | 使用统计 | §2 | 自检 |
| AC-05 | 兼容分发 | §2 | 正式验证 |

## 2. 实现顺序、垂直切片与检查点
1. 改模板及 G3/G4 完整性检查；通过缺映射与完整映射自检。
2. 改独立审查指南及 README；对照输入清单检查。
3. 改知识工具和索引字段，添加采用统计自检；跑完整自检。
- 检查点：第 1 步后验证旧 Spec 兼容与新 Spec 反例；第 3 步后正式验证。
- 边界样本：同一 Spec 的 `K-0001` 重复出现只计一次；模板占位不算采用；无卡片输出空统计；旧 Spec 无矩阵仍通过已有检查。

## 3. 接口契约与数据结构变更
- `ai-knowledge.sh usage`：只读输出卡片 ID、采用 Spec 数、Spec ID 清单及未采用卡片。
- 新 Spec 以标记字段启用追溯校验；旧 Spec 未标记时沿用原门禁。
- 不修改数据库或对外运行时 API。

## 4. 影响面与涉及文件清单
- 新建文件：本 Spec 的需求、设计、任务、验证、审查与验收记录。
- 修改文件：`template/docs/specs/_templates/requirements.md`、`template/docs/specs/_templates/design.md`、`template/docs/specs/_templates/tasks.md`、`template/docs/specs/_templates/knowledge-card.md`、`template/scripts/ai-gate.sh`、`template/scripts/ai-knowledge.sh`、`template/scripts/harness-selftest.sh`、`template/.agents/skills/code-review.md`、`template/.agents/skills/knowledge-distill.md`、`template/.agents/skills/gc-memory.md`、`template/.knowledge/INDEX.md`、`.knowledge/INDEX.md`、`template/AGENTS.md`、`README.md`、`docs/INTAKE.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`、`docs/metrics.md`。
- 只读依赖契约：`harness/verify.conf`、`template/harness/redlines.conf`、`bin/ai-harness`。
- 间接消费者 / 副作用：新项目初始化复制模板；老项目 retrofit 仅补缺失文件；现有 Spec 与测试夹具使用旧模板格式。用自检和只读 dry-run 复核。
- 检索依据：已检索 `template/scripts/ai-gate.sh` 的 G3/G4、`ai-knowledge.sh` 的 suggest/impact、模板与知识指南，确认当前缺口。

## 5. 对抗自审
1. 最可能错误：用字符串出现代替真实覆盖；因此机器只管 ID 完整性，审查负责语义。
2. 隐含假设：每个 Spec 的任务只有一条「注入知识」行；脚本仍按 ID 去重。
3. 失败路径：旧 Spec 缺标记、无知识卡、重复 ID、未知 ID。
4. 简化：不引入新数据库或钩子，只用现有 Markdown。
5. 回滚：撤回模板与脚本变更，旧 Spec 仍可用。
- 自审结论：先验证反例，再扩展指南，最后跑完整自检。

## 6. 待确认问题
- [x] Q1：采用统计来源？→ Spec 注入记录。

## 7. 风险与回滚
- 风险：新增检查误拒旧 Spec；自检覆盖旧、新样本。
- 回滚方式：Git 撤回本 Spec 的模板和脚本变更。
