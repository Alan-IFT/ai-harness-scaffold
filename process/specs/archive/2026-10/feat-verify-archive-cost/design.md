# 技术架构与接口设计：feat-verify-archive-cost

- 关联需求：requirements.md
- 设计者：Codex
- 状态：Approved

## 0. 模块关联
- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`；本仓库自用 → `docs/architecture/modules/self-hosting.md`
- 契约入口：`template/scripts/ai-gate.sh`（只读）、`template/scripts/harness-selftest.sh`（增加负例）、`template/docs/INTAKE.md`（修改入口格式）
- 人工前置决策：决策人 维护者；取舍为先以实测评估门禁提速，不保留无总收益的机制改动，并用稳定 ID 代替入口中的阶段路径副本；结论来自本会话「那就看看这两个耗时点，是否能单独优化」。

## 1. 架构变更与数据流
性能试验用同一 Windows + Git Bash 环境对 `harness-selftest.sh` 的 12 段各计时一次。原版第 3 段为 64 秒；G6 材料前移试验为 61 秒，但总耗时仍约 139 秒且新增两条必要反例。样本与检查数不同，不能量化净加速；该试验未显示可靠的整体收益，故撤回。完整自检和 120 秒提醒线维持原样；后续若需显著提速，应单独设计独立夹具并发执行或更少的进程启动，先证明不会产生共享状态竞态。

| 计时口径 | 原版 | G6 顺序试验 | 结论 |
| :-- | --: | --: | :-- |
| 第 2 段：空模板拒绝 | 27 秒 | 27 秒 | 无变化 |
| 第 3 段：好样例与 G6 正反例 | 64 秒 | 61 秒 | 局部少 3 秒 |
| 全套剖析运行 | 约 140 秒 / 121 项 | 约 139 秒 / 123 项 | 各一次且断言数不同，无法确认净加速 |
| 前一 Spec 的正式验证 | 137 秒 / 121 项 | 不适用 | 120 秒提醒线仅告警 |

入口记录只保存原始需求、一次处理决定和不随物理归档变化的 Spec ID。`ai-new-spec.sh` 在 active 和 archive 中检查 ID 占用，拒绝重用已归档 ID。当前位置与当前阶段由 `ai-gate.sh status <id>` 从 `.gates` 和目录解析。归档指南不再要求同步入口中的路径或完成状态；知识卡和路线图等非流程文件在最后一次正式 G4 前写妥，归档时只复核。正式验证目标必须是归档后路径和内容稳定的项目文件；`ai-verify.sh` 拒绝 `docs/specs/**` 与 `docs/metrics.md` 作为正式目标，避免目标文件独立哈希在归档后失效。

## 2. 实现顺序、垂直切片与检查点
1. 剖析自检并试验 G6 顺序：核对总收益，试验无收益就撤回代码和新增负例。
2. 把模板及本仓库入口改为稳定 ID，拒绝重用已归档 ID，更新建 Spec 与归档指南，并验证已归档 Spec 可按 ID 查询；知识卡和路线图更新前移到最后一次正式 G4 之前；正式验证拒绝归档时会变动的流程文件目标。
3. 跑完整自检与正式验证，归档时不动入口；复核 G4 摘要未过期。
- 检查点：第 1 步根据总耗时而非局部耗时决定取舍；第 2 步后确认归档无需改写入口。
- 边界样本：总耗时未下降、检查数意外减少、已归档 ID 查询与重用拒绝、旧入口行迁移、归档后知识卡或路线图改动使 G4 摘要过期、以 Spec 文档或 metrics 为正式目标被拒绝。
- 拆分自查：性能结论和入口契约分两切片，不引入新的状态表或持久缓存。

## 3. 接口契约与兼容性
- `ai-gate.sh check/pass <feat> g6` 参数、检查顺序和通过条件均不变；无收益试验不留在交付源码。
- `ai-gate.sh status <feat>` 已能解析 active 和 archive；入口以 `<feat>` 为稳定引用。
- `ai-verify.sh` 拒绝正式验证使用归档时会变动的流程文件目标；`--quick` 仍可用于这些文件。120 秒预算和 G4 正式证据规则不变。
- `ai-new-spec.sh` 保留现有 CLI，仅新增已归档 ID 的拒绝条件；`harness-selftest.sh` 增一条对应负例，原 121 项均保留。

## 4. 影响面与涉及文件清单
- 新建文件：无。
- 修改文件：
  - `template/docs/INTAKE.md`：关联 Spec ID 的入口契约。
  - `docs/INTAKE.md`：本仓库入口迁移和本需求 R-004。
  - `template/.agents/skills/new-spec.md`：创建时记录稳定 ID。
  - `template/.agents/skills/archive-spec.md`：归档时不重写入口阶段/路径。
  - `template/.agents/skills/knowledge-distill.md`、`template/AGENTS.md`：知识卡在最后一次正式 G4 前蒸馏，归档时复核。
  - `template/scripts/ai-new-spec.sh`：拒绝重用已归档 Spec ID。
  - `template/scripts/harness-selftest.sh`：已归档 ID 重用负例。
  - `template/scripts/ai-verify.sh`：正式目标排除归档时会变动的流程文件。
  - `README.md`：公开入口和归档语义。
  - `docs/architecture/modules/guidance.md`：稳定 ID 指引。
  - `docs/architecture/modules/self-hosting.md`：本仓库入口说明。
- 只读依赖契约：
  - `template/scripts/ai-gate.sh`：性能剖析过的门禁；试验已撤回。
  - `template/scripts/ai-state-id.sh`：流程文件指纹排除规则。
  - `harness/redlines.conf`：原 120 秒提醒线；不修改。
- 间接消费者 / 副作用：根目录薄转发、新项目安装后的模板、老项目 retrofit、旧 Spec 归档、跨 IDE 接力；不更改脚本路径或门禁参数。
- 检索依据：已在 `template/scripts`、`template/.agents/skills`、`template/docs/INTAKE.md`、根目录 `docs/INTAKE.md` 和 `README.md` 有界搜索 G6、INTAKE、archive、state-id 与 selftest。

## 5. 对抗自审
1. 最可能的错误是把局部 3 秒改善误认为整体提速；以完整运行结果否决该试验。
2. 假设入口只用于路由和原意，不被验证命令当作代码输入；不改指纹排除规则，因此入口在本 Spec 实现时仍参与正式验证。
3. 入口 ID 必须能查到唯一的已归档 Spec；归档时不能漏掉活文档、知识卡、路线图等其他可能触发指纹变化的文件。
4. 不新增缓存、后台服务或宿主插件；以现有 Bash 创建脚本保证 ID 唯一。
5. 回滚本 Spec 提交，恢复原入口路径写法；重新正式验证。
- 自审结论：用实测取舍，保留完整验证和原门禁；归档流程仅保留稳定 ID 这一处事实。

## 6. 待确认问题
- [x] Q1：归档入口是否保留可点击目录链接？→ 稳定 ID 优先，使用 `ai-gate.sh status <id>` 定位；不维护目录路径副本。

## 7. 风险与回滚
- 风险：入口 ID 对纯文档浏览不如目录链接直观；已有手工制造的重复 ID 不在本次自动修复范围；归档时若修改其他非流程文件，仍须重验。
- 回滚方式：回退入口与指南改动，恢复原目录链接；完整门禁机制本次没有改动。
