# 技术架构与接口设计：feat-t-000003

- 关联需求：`requirements.md`
- 设计者：Codex
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：项目指南 → `docs/architecture/modules/guidance.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`；本仓库自用状态 → `docs/architecture/modules/self-hosting.md`
- 契约入口（只读）：`template/scripts/ai-gate.sh`、`template/scripts/ai-task-pool.sh`、`template/harness/redlines.conf`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-22「按照建议来改，然后把存在的问题也修复掉」；取舍：按先前 D1~D8 复核结论修改指南与模板，不改人类专属红线和门禁逻辑；结论：同意。

## 1. 架构变更与数据流

目标项目读取 `template/` 分发的指南和 Spec 模板；本仓库的 README 与模块活文档说明行为。只改 Markdown，不改运行时脚本、配置或数据流。CI 阈值仍由项目流水线读取并裁决；G1 的固定权重与单项门槛保持原行为。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | T-000003；行动与结果 | §2 步骤 1：requirements / new-spec | AC-01 |
| REQ-02 | T-000003；关键前提证伪 | §2 步骤 1：design | AC-01 |
| REQ-03 | 本会话 D4/D5 取舍 | §2 步骤 2：acceptance / archive | AC-02 |
| REQ-04 | 本会话 D6/D7/D8 取舍 | §2 步骤 2：requirements / CI | AC-03 |
| ERR-01 | 不强制每项命令 | §2 步骤 2：acceptance | AC-02 |
| ERR-02 | 填阈值不等于接线 | §2 步骤 2：CI | AC-03 |
| AC-01 | 结果与前提 | §2 步骤 1 | AC-01 |
| AC-02 | AC 与后续问题 | §2 步骤 2 | AC-02 |
| AC-03 | 评分与 CI | §2 步骤 2 | AC-03 |
| AC-04 | 回归 | §2 步骤 3 | AC-04 |

## 2. 实现顺序、垂直切片与检查点

1. 更新需求澄清指南、需求与设计模板，补行动结果与可证伪前提；对照原需求和 G1 现有行为做快速校验。
2. 更新验收与归档指南、CI 指南，澄清观察证据、候选后续问题、固定评分与可选阈值接线；检查无自动入队或改红线。
3. 同步 README、模块活文档及提案决策记录；跑自检和正式验证。

- 检查点：步骤 2 后回读 `redlines.conf`、G1 代码与模板，确认说明精确且旧 Spec 不受新门禁影响。
- 拆分自查：各步最多 5 个交付文件；跨指南和机制仅同步文档，不改脚本。
- 边界样本：AC 是人工观察时允许报告或可观察输出；CI 未接线时不得显示阈值通过；单项得分 3 被 G1 拒绝而 3.5 可通过；旧 Spec 无新增字段仍能过 G1。

## 3. 接口契约与数据结构变更

- 无 CLI/API 或数据结构变更。文档约定保持 G1 固定七项权重、单项得分须大于 3 和项目 CI 自行接线。

## 4. 影响面与涉及文件清单

- 新建文件：无。
- 修改文件：
  - `template/docs/specs/_templates/requirements.md`：目标、评分说明。
  - `template/docs/specs/_templates/design.md`：关键前提证伪。
  - `template/docs/specs/_templates/acceptance.md`：AC 证据与有证据的后续问题。
  - `template/.agents/skills/new-spec.md`：澄清目标，不缩小目标。
  - `template/.agents/skills/archive-spec.md`：候选后续问题的范围。
  - `template/harness/CI.md`：可选阈值的接线核对。
  - `README.md`：用户侧说明。
  - `docs/architecture/modules/guidance.md`：活文档同步。
  - `docs/architecture/modules/template-mechanism.md`：模板机制说明同步。
  - `docs/PROPOSAL-2026-10-blog-ai-ambition.md`：决策与复核结果。
- 只读依赖契约：
  - `template/scripts/ai-gate.sh`
  - `template/scripts/ai-task-pool.sh`
  - `template/harness/redlines.conf`
- 间接消费者 / 副作用：目标项目新建 Spec 时使用模板；旧项目只有更新模板后才看到新增提示，旧门禁不变。
- 检索依据：`rg` 检索评分权重、质量阈值、AC、后续动作和 `start-next`，核对 README、模板及指南；正式验证采用全仓指纹。

## 5. 对抗自审

1. 最可能错在把倡议写成新的强制门槛，令旧 Spec 失败；因此不修改门禁脚本。
2. 关键前提是「现有验收已记录实际结果」；已在 acceptance.md §3 证实。低成本证伪：核对模板和 G6 代码，不把结果记录误称为已证明用户价值。
3. 人工观察、未接线 CI、旧项目不更新模板是边界；分别保留观察证据、写明接线责任、保持脚本兼容。
4. 只改现有模板和指南，复用已有后续动作，不新增字段门禁或任务池机制。
5. 若指南产生歧义，按 Git diff 回退相关 Markdown；红线和脚本未动。
- 自审结论：仅以可核对文档澄清执行口径，验证关注自检、CI 说明和向后兼容。

## 6. 待确认问题

- [x] Q1：是否改红线或门禁？→ 不改；维护者已批准按先前复核建议落地。

## 7. 风险与回滚

- 风险：目标项目复制指南后可能把候选后续问题当成自动工作，或误解可选 CI 阈值。
- 回滚方式：撤销本 Spec 的 Markdown 改动；不涉及数据迁移。
