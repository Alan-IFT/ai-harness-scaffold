# 技术设计：feat-t-000004

- 关联需求：`requirements.md`
- 设计者：Codex
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：本仓库自用状态 → `docs/architecture/modules/self-hosting.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`；项目指南 → `docs/architecture/modules/guidance.md`
- 契约入口（只读）：`template/scripts/ai-verify.sh`、`template/scripts/ai-gate.sh`、`harness/verify.conf`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-22「那就按照建议做」；风险取舍：允许改进自用验证配置与分发指南，正式 G4 保留完整自检和 CLI 回归；结论：同意。

## 1. 架构与数据流

`ai-verify.sh` 读取本仓库 `harness/verify.conf`，完整检查调用项目专属的阶段运行器，quick 调用短检查。运行器只在本仓库 `tests/`，不进入目标项目。模板自检在共享沙箱中串行运行，只输出内部节耗时；不改断言语义。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | §2.3 完整 G4 | §2 步骤 1 | AC-01 |
| REQ-02 | §2.3 双区 diff | §2 步骤 1、2 | AC-02 |
| REQ-03 | §2.3 quick 不代替 G4 | §2 步骤 2 | AC-03 |
| REQ-04 | §2.3 G4 前核对 | §2 步骤 3 | AC-04 |
| ERR-01 | 阶段失败 | §3 阶段运行器 | AC-01 |
| ERR-02 | 仅暂存错误 | §3 双区 diff | AC-02 |
| AC-01 | 全阶段及计时 | §2 步骤 1 | AC-01 |
| AC-02 | 暂存区错误 | §2 步骤 1、2 | AC-02 |
| AC-03 | quick 相关性 | §2 步骤 2 | AC-03 |
| AC-04 | 文档核对 | §2 步骤 3 | AC-04 |

## 2. 实现顺序、垂直切片与检查点

1. 新建项目专属完整验证运行器，先以双区 diff 低成本拒绝，再逐阶段计时运行完整检查，失败即停；用隔离 Git 夹具验证暂存错误。自检脚本输出各节耗时，不改变断言。
2. 新建项目专属 quick 运行器：Shell/CLI 语法、全部指南入口的 Markdown 标题与上下文体积检查、双区 diff；验证 quick 不写 G4 摘要。
3. 更新 G4 前准备指南、README 与模块活文档；核对配置、AC、设计清单及实际代码，再跑正式 G4。

- 检查点：步骤 2 后核对 quick/正式的命令列表和失败语义；步骤 3 后实测阶段耗时并判断是否有可靠的低风险优化。
- 拆分自查：每步不超过 5 个交付文件；项目专属逻辑留在 `tests/`，模板机制只加自检计时。
- 边界样本：仅暂存尾随空白、仅工作区尾随空白、阶段失败、无变更、`skill/SKILL.md` 等指南目标、Shell 目标、目标项目未配置 quick。

## 3. 契约与数据结构

- `harness/verify.conf` 保持 CUSTOM_CHECK/QUICK_CHECK 两变量接口；项目专属值分别调用 `tests/verify-repo.sh` 和 `tests/verify-repo-quick.sh`。
- 运行器接受环境变量 TARGET_FILE，返回 0/非 0；完整运行器每阶段打印名称、耗时、结果。
- 无 Schema、公共 CLI 参数或目标项目迁移。

## 4. 影响面与文件清单

- 新建文件：
  - `tests/verify-repo.sh`：完整阶段检查。
  - `tests/verify-repo-quick.sh`：项目 quick 检查。
- 修改文件：
  - `harness/verify.conf`：接入项目运行器。
  - `template/scripts/harness-selftest.sh`：各节耗时。
  - `template/.agents/skills/new-spec.md`：正式 G4 前准备。
  - `README.md`：验证用法说明。
  - `docs/architecture/modules/self-hosting.md`：自用检查事实。
  - `docs/architecture/modules/template-mechanism.md`：模板验证事实。
  - `docs/architecture/modules/guidance.md`：指南行为。
- 只读依赖契约：
  - `template/scripts/ai-verify.sh`
  - `template/scripts/ai-gate.sh`
  - `tests/cli-upgrade.sh`
  - `template/scripts/ai-check-bloat.sh`
- 间接消费者 / 副作用：本仓库 G4、quick 用户和分发指南读者；目标项目不会收到 tests/ 下的自用运行器。
- 检索依据：有界检索 CUSTOM_CHECK、QUICK_CHECK、git diff --check 及自检节标题；正式验证采用保守全仓指纹。

## 5. 对抗自审

1. 最可能错在阶段运行器吞掉失败码或计时改变自检断言；用失败夹具和完整自检检验。
2. 关键前提是分段计时可以揭示主要成本；先记录实测数据，如各阶段相近，不做未经证实的并行化。
3. 暂存区和工作区各自有错误时都应失败；quick 不产生正式摘要；Windows Git Bash 的秒级计时允许舍入。
4. 复用现有 ai-verify.sh 配置接口，只加两个本仓库短脚本，不改分发后的验证机制。
5. 可回退 harness/verify.conf 与两个运行器；自检计时可独立回退，不影响断言。
- 自审结论：先提升可观察性和正确性，再用数据决定后续性能优化。

## 6. 待确认问题

- 无；实现中的性能取舍据实际日志决定。

## 7. 风险与回滚

- 风险：自用配置误接导致正式验证漏检；回滚方式：恢复原配置并跑 harness-selftest.sh 与 CLI 回归。
