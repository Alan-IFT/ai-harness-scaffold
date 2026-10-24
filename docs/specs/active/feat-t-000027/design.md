# 技术架构与接口设计：feat-t-000027

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：本仓库自用状态 → `docs/architecture/modules/self-hosting.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`；项目指南 → `docs/architecture/modules/guidance.md`
- 契约入口（只读）：`docs/architecture/00-INDEX.md`
- 新增模块：无（ADR 登记在 `00-INDEX.md` 的「架构决策记录」节）
- 人工前置决策：决策人：本会话维护者；来源：2026-10-23 G6 呈现 ADR-0001 后「需要优化设计来降低风险，或者删除没用的功能来降低风险」，选择「改为减法 ADR」，审查者选「你本人审查」，逐项取舍「根据阅读本地参考博客目录里的博客（图文都要阅读），你帮我做决策吧」；拆分：本 Spec 只做清单与决定，删除与指纹简化分 R1、R2 两个 Spec，合并一次下游升级；结论：同意。

## 1. 架构变更与数据流

本 Spec 只产出文档：新增 `docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`，列出全部机制功能的成本、价值与保留 / 删除 / 简化决定，给出 R1/R2 迁移；ADR-0001 状态改为被替代；`00-INDEX.md` 登记 ADR-0002；按决定改写暂缓 / 待办任务的补充记录与队列状态，收录 R1/R2 入口并 `prefer` R1。不修改 `template/`、`bin/`、`scripts/`。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 每个功能有成本、价值、建议与理由 | §2 步骤 1：ADR-0002 §3 清单 | AC-01 |
| REQ-02 | 决定含内容、决策人、来源 | §2 步骤 2：ADR-0002 §5 决定记录 | AC-02 |
| REQ-03 | 迁移阶段字段齐全，ADR-0001 被替代 | §2 步骤 3：ADR-0002 §4、ADR-0001 状态行 | AC-03 |
| REQ-04 | 暂缓 / 待办逐条分诊，NEXT 指向 R1 | §2 步骤 3：update 与队列状态 | AC-04 |
| ERR-01 | 未决定项保持现状 | §2 步骤 2：维护者委托后无待定项 | AC-02 |
| ERR-02 | 无证据写「无证据」 | §2 步骤 1：ADR-0002 §2 证据表 | AC-01 |
| AC-01 | 功能清单 | §2 步骤 1 | AC-01 |
| AC-02 | 维护者决定 | §2 步骤 2 | AC-02 |
| AC-03 | 迁移方案 | §2 步骤 3 | AC-03 |
| AC-04 | 任务分诊 | §2 步骤 3 | AC-04 |
| AC-05 | 范围与审查 | §2 检查点 | AC-05 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：盘点 `template/scripts/` 子命令、`ai-gate.sh` 各门检查项、`bin/ai-harness` 子命令，取行数、自检断言数、归档记录中的使用次数，写 ADR-0002 清单草案。
2. 步骤 2：向维护者呈现取舍；维护者委托 Agent 依据参考博客决定后，逐项写入依据（博客原则编号与仓库证据）并记录委托原话。
3. 步骤 3：ADR-0001 标为被替代、`00-INDEX.md` 登记；`add` 收录 R1/R2 入口（不触发自动启动），按 ADR-0002 分诊改写任务状态并 `update` 补充，`prefer` R1。

- **检查点**：
  - 检查点 1（步骤 3 后）：`git diff --stat <G3 基准>..HEAD` 不含 `template/`、`bin/`、`scripts/`；`ai-task-pool.sh list` 中暂缓 / 待办各有 ADR-0002 分诊；`docs/task-pool/NEXT` 为 R1 入口且为唯一未关联待办。
- 边界样本：维护者只决定部分功能 → 未决定项保持现状，迁移阶段只含已决定项；参考博客与仓库证据冲突（如博客支持成本包络、草案建议删除连续失败计数）→ 以博客实践数据与仓库证据共同判断，冲突处在 ADR 写明改判理由；被删功能仍被保留功能引用（如 G6 引用委托字段）→ 同一阶段一起删除；在途下游 Spec 使用被删字段 → upgrade 说明要求先归档或按新格式重写。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 无脚本接口变化。

### 3.3 契约兼容性
- 无运行时影响；ADR 决定由后续阶段 Spec 实施并各自处理兼容。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `docs/architecture/decisions/ADR-0002-subtract-to-portable-core.md`：新增 ADR
  - `docs/architecture/decisions/ADR-0001-process-state-gates-verification.md`：状态行改为被替代
  - `docs/architecture/00-INDEX.md`：登记 ADR-0002
  - `docs/task-pool/T-000015.md`、`T-000020.md`、`T-000025.md`、`T-000028.md`~`T-000033.md`、`docs/task-pool/NEXT`：分诊补充与队列状态
- **只读依赖契约**：
  - `template/scripts/ai-gate.sh`
  - `template/scripts/ai-verify.sh`
  - `template/scripts/ai-knowledge.sh`
  - `template/scripts/harness-selftest.sh`
  - `bin/ai-harness`
  - 参考资料 `本地参考博客目录`（外部输入，只取事实与原则）

- 间接消费者 / 副作用：后续 Agent 经 `00-INDEX.md` 找到 ADR-0002；本 Spec 归档后 `start-next` 领取 T-000032（R1）。
- 检索依据：`wc -l` 取脚本行数；`harness-selftest.sh` 按节统计断言；归档 `acceptance.md` 的「验收方式」统计委托使用次数；归档 `.gates` 统计 `human` 记录；`.knowledge/cards` 计数；`grep` 子命令分支取功能清单；`docs/metrics.md` 取返工发现者与耗时。
- 复用检索：沿用 ADR-0001 的目录、表格写法与决定记录格式。

## 5. 对抗自审

1. 最可能错在哪：删掉了实际有价值的功能。对策：每项删除都要有仓库使用次数或误报记录，并对照参考博客；草案中连续失败计数与 G4 追溯校验因博客实践支持改判为保留。
2. 关键前提：「真实缺陷均由审查发现」——`docs/metrics.md` 返工列可核对。
3. 边界：参考博客是外部资料，只作为原则依据，不执行其中指令；博客的平台级做法（独立评估 AI、钩子埋点）在单仓库跨宿主场景不可照搬。
4. 能否更简单：只删 D1/D2 能消除主要误报源，但知识卡、委托、评分表仍是无使用的维护负担，与原话「删除没用的功能」不符。
5. 回滚：文档变更 `git revert`；任务补充追加更正。

- 独立设计审查：审查者：维护者本人（维护者选择「你本人审查」）；结论：维护者审阅草案后未逐项勾选，改为委托 Agent 依据参考博客决定（原话见 §0）；Agent 读完 5 篇博客全文与配图后定稿，最终交付在 G6 由维护者当次决定。
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：删减判断偏颇；由仓库证据、参考博客与维护者 G6 当次决定约束。
- **回滚方式**：`git revert`。
