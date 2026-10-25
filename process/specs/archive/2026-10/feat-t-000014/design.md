# 技术架构与接口设计：feat-t-000014

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`
- 契约入口（只读）：`template/scripts/ai-state-id.sh`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-23「选择A方案」（针对 A/B/C）；取舍：把 `docs/task-pool/**` 与 `docs/specs/**`、`docs/metrics.md` 同样视为流程记录，两种指纹模式都不计入，正式验证拒绝以其为目标；接受任务池文件改动不触发重验；结论：同意。

## 1. 架构变更与数据流

`ai-state-id.sh` 现有三处排除流程记录：精确清单模式检查未归属改动的 `case`、全仓模式 `git ls-files` / `git diff` 的 `:(exclude)` pathspec、全仓模式未跟踪文件的 `case`。三处各加 `docs/task-pool/*`（pathspec 写 `':(exclude)docs/task-pool/**'`），带斜杠的目录前缀不会误排除 `docs/task-pool-x/` 或 `scripts/ai-task-pool.sh`。头部注释写明流程记录的三项范围。`ai-verify.sh` 正式验证目标的 `case` 同样加 `docs/task-pool/*`，提示文案不变（「流程文件」）。精确清单模式本就只哈希清单内路径，排除只影响「是否回退全仓」的判断。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 全仓模式不计入 | §2 步骤 1：pathspec 与未跟踪 case | AC-01 |
| REQ-02 | 精确清单不回退 | §2 步骤 1：未归属 case | AC-03 |
| ERR-01 | 目标拒绝 | §2 步骤 1：ai-verify case | AC-04 |
| ERR-02 | 相近路径与脚本照常计入 | §2 步骤 1：带斜杠前缀 | AC-02 |
| AC-01 | 中途收录不过期 | §2 步骤 2 | AC-01 |
| AC-02 | 其他改动仍过期 | §2 步骤 2 | AC-02 |
| AC-03 | 精确清单模式 | §2 步骤 2 | AC-03 |
| AC-04 | 目标拒绝 | §2 步骤 2 | AC-04 |
| AC-05 | 回归与文档 | §2 步骤 3 与检查点 | AC-05 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/ai-state-id.sh` 三处排除与头部注释；`template/scripts/ai-verify.sh` 目标检查。
2. 步骤 2：`template/scripts/harness-selftest.sh` 在 Git 指纹夹具中补用例：
   - 真实执行 `ai-task-pool.sh intake` 新建任务文件、`prefer` 写 `NEXT`（未跟踪），全仓指纹不变；把任务池提交后再 `update`（未暂存修改）、`git add`（已暂存）、提交、删除 `NEXT`，每一步全仓指纹都等于基线——已跟踪路径才经过 pathspec 排除；
   - `docs/task-pool-x/` 下新增文件与修改 `scripts/ai-task-pool.sh` 后指纹变化；
   - 精确清单模式（spec one）下新增未跟踪任务池文件，指纹仍等于此前 scoped 值；
   - 主夹具中以 `docs/task-pool/` 下文件为正式验证目标时被拒并提示「流程文件」，`./docs/task-pool/...` 同样被拒。
3. 步骤 3：文档写明任务池属于流程记录——`template/AGENTS.md` 验证口径、`template/.agents/skills/archive-spec.md` 正式目标说明、`template/.agents/skills/retrofit-legacy.md` 升级说明（升级会改 `scripts/ai-state-id.sh`，它在两种指纹模式里都计入，所以已过 G4 的在途 Spec 都须重跑正式验证）、`README.md` 指纹段、`docs/architecture/modules/template-mechanism.md` 验证行、`docs/architecture/modules/guidance.md` 正式目标说明。指南同时写明 `docs/task-pool/` 由脚手架专用，代码与构建不得引用其中内容，流程文件不写进 §4 清单。

- **检查点**：
  - 检查点 1（第 2 步后）：两种 locale 自检全过；沙箱中对 `ai-state-id.sh` 三处排除分别单独去掉（未归属 `case`、pathspec、未跟踪 `case`），每次至少一个对应用例报出：未归属 → 精确清单用例，pathspec → 已跟踪修改 / 暂存 / 删除用例，未跟踪 → intake 用例。
  - AC-01 的「G6 不报过期」由指纹相等推出：`ck_g6` 调用 `ck_g4`，`ck_g4` 只用 `ai-state-id.sh --spec` 与摘要 `state` 比较；Git 指纹夹具不含门禁脚本，用例直接比对指纹值（主夹具不是 Git 仓库，走 `no-git` 分支，不能证明本项）。
- 边界样本：不计入——未跟踪 `docs/task-pool/T-000001.md`、`docs/task-pool/NEXT`，已跟踪任务文件的未暂存修改、暂存、提交与删除，精确清单模式下的未跟踪任务文件；计入——`docs/task-pool-x/a.md`、`docs/task-poolz`、`scripts/ai-task-pool.sh`、整目录换成符号链接的 `docs/task-pool`；正式目标拒绝——`docs/task-pool/T-000001.md`、`./docs/task-pool/NEXT`；非默认配置——`GIT_LITERAL_PATHSPECS=1` 时排除失效而计入（偏保守）。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 退出码与报错文案不变。

### 3.3 契约兼容性
- 升级会改动 `scripts/ai-state-id.sh`，它是 scoped 模式的固定依赖，也计入全仓指纹，因此两种模式的指纹都会变化：已过 G4 的在途 Spec 升级后须重跑正式验证，不会因此放过未验证的代码改动。原先因未跟踪任务池文件回退全仓的 Spec，升级后可恢复 scoped。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/ai-state-id.sh`：排除任务池
  - `template/scripts/ai-verify.sh`：目标检查
  - `template/scripts/harness-selftest.sh`：指纹与目标用例
  - `template/AGENTS.md`：验证口径
  - `template/.agents/skills/archive-spec.md`：正式目标说明
  - `template/.agents/skills/retrofit-legacy.md`：升级说明
  - `README.md`：指纹说明
  - `docs/architecture/modules/template-mechanism.md`：验证说明
  - `docs/architecture/modules/guidance.md`：正式目标说明
- **只读依赖契约**：
  - `template/scripts/ai-task-pool.sh`
  - `template/harness/redlines.conf`

- 间接消费者 / 副作用：`ai-gate.sh` 的 G4 / G6 通过 `ai-state-id.sh` 比对摘要 state，无需改动；`bin/ai-harness` 分发 template，不涉及路径常量。
- 检索依据：`grep -n 'docs/metrics.md' template/scripts/*.sh` 命中 `ai-state-id.sh` 三处与 `ai-verify.sh` 一处；`grep -n 'POOL=' template/scripts/ai-task-pool.sh` 确认任务池目录固定为 `docs/task-pool`（含 `NEXT`）；`grep -rn '流程文件\|docs/metrics.md' template/AGENTS.md template/.agents README.md docs/architecture` 得出文档清单。
- 复用检索：沿用现有 `docs/specs/*|docs/metrics.md` 的 `case` 与 `:(exclude)` 写法，不新增函数。

## 5. 对抗自审

1. 最可能错在哪：pathspec 与 `case` 写法不一致导致只排除了一半（如已跟踪改动排除、未跟踪新文件未排除）；用例分别覆盖新文件、修改与 `NEXT`。
2. 关键前提：任务池文件不影响代码行为。`ai-task-pool.sh` 只读写这些文件，门禁读取它们只用于路由与展示，不参与 G1~G7 判定。
3. 边界：项目若让代码或构建引用 `docs/task-pool/` 内容（含符号链接），改动不会触发重验；`GIT_ICASE_PATHSPECS=1` 时大小写不同的已跟踪路径会被 pathspec 排除而 `case` 不排除。与 `docs/specs/**` 是同一类既有限制，指南写明该目录专用、不得被代码引用。`ai-verify.sh` 拒绝文案「归档时会移动或更新的流程文件」对任务文件不完全贴切，沿用以免改动既有断言。
4. 能否更简单：只改 pathspec 不改未归属检查，精确清单模式下仍会因中途收录回退全仓并使指纹变化，不满足 REQ-02。
5. 回滚：`git revert`。

- 独立设计审查：审查者：独立 subagent（未参与设计，只读）；结论：首轮「需修改」，2 项关键问题——Git 夹具的任务池文件全是未跟踪，只给 `case` 加排除、pathspec 不改的变异版本仍能通过计划用例（审查者原型复现）；`guidance.md` 的正式目标说明漏列——已改为提交任务池后测未暂存、暂存、提交、删除，检查点改为三处排除分别单独变异，补列 guidance.md；采纳兼容说明更正（两种模式都变）、目录专用与不得被代码引用的说明、AC-01 推导写明等建议。第 2 轮「通过」：两项关键问题已解决，推演确认三处排除逐一去掉都有对应用例报出；采纳基线取在 intake 之前且不中途重取、相近路径用例后清理夹具的建议。
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：排除范围过宽；由带斜杠前缀与相近路径用例约束。
- **回滚方式**：`git revert`。
