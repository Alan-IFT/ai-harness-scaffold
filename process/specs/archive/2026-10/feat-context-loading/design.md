# 技术架构与接口设计：feat-context-loading

- 关联需求：requirements.md
- 设计者：Codex
- 状态：Approved；用户调整接口后待重新检查 G3
- 追溯版本：1

## 0. 模块关联

- 主模块：项目指南 → `docs/architecture/modules/guidance.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`；本仓库自用状态 → `docs/architecture/modules/self-hosting.md`
- 契约入口（只读）：`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`template/scripts/ai-resume.sh`、`template/scripts/ai-gate.sh`
- 人工前置决策：决策人：用户（本会话）；取舍：角色指南与显式角色入口两者都改，允许废弃旧 `ai-resume.sh [feat]`；结论：同意 A+B 且优先简洁重构；来源：用户回复「我觉得A、B都应该改」及「若有更好的设计方案，`ai-resume.sh [feat]` 用法不再兼容」。

## 1. 架构变更与数据流

确定方案：同时更新角色指南与接手脚本，以三个必选子命令替代含糊的默认接手。主 Agent 负责分配文件边界，worker 读取本任务的原件与当前状态；审查者按 `code-review.md` 独立读取需求、设计、diff、验证证据。接手输出只提供索引和必要状态，不复制 Spec 全文或实现者解释。

加载量用固定夹具对比命令输出字节和重复材料项数；实际 token 与墙钟时间仅在宿主提供可信数据时另外记录。字节减少是输出层效果，不等同实际需求耗时减少。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | requirements.md §2.3 无意义复制 | §1 角色边界、§3 显式入口 | AC-01 |
| REQ-02 | requirements.md §2 G5 独立证据 | §1 审查者输入、§3 审查清单 | AC-02 |
| REQ-03 | requirements.md §2.3 耗时归因 | §1 固定夹具、§2 基线步骤 | AC-03 |
| REQ-04 | requirements.md §2 旧调用兼容 | §3 默认入口 | AC-04 |
| ERR-01 | requirements.md §2 无效边界 | §3 参数错误语义 | AC-04 |
| ERR-02 | requirements.md §2 审查证据缺失 | §3 审查输入清单 | AC-02 |
| AC-01 | requirements.md §3 worker 输出减少 | §2 步骤 2、§3 接手入口 | AC-01 |
| AC-02 | requirements.md §3 G5 证据保留 | §2 步骤 3、§3 审查入口 | AC-02 |
| AC-03 | requirements.md §3 可比测量 | §2 步骤 1 与 4 | AC-03 |
| AC-04 | requirements.md §3 兼容和失败路径 | §2 步骤 4、§3 默认入口 | AC-04 |

## 2. 实现顺序、垂直切片与检查点

1. 固定基线：选同一份测试 Spec 与 Git 状态，记录当前 `ai-resume.sh` 输出字节、重复材料项、实际读取路径和命令耗时；写入本 Spec 的 `baseline.md`，未知 token / 实际任务耗时明确标「未知」。
2. 角色入口：在模板指南写清主 Agent、限定 worker 和 G5 审查者的最小输入；以 `owner`、`worker`、`review` 三个子命令重构 `ai-resume.sh`。
3. 审查保护：调整 `code-review.md` 和必要的接手提示，使 G5 继续回读原件；用缺需求、缺 diff、缺验证摘要的失败样本检查。
4. 调用点迁移：同步 README、根目录与分发规则、老项目指南和任务模板，检索仓库内的旧命令示例。
5. 验证与比较：在 `harness-selftest.sh` 覆盖三角色、旧命令迁移提示、参数错误和旧 Spec；用步骤 1 的同一夹具复测并记录差值，同步三篇模块活文档。

- 检查点 1（第 2 步后）：对照默认输出与角色输出，确认没有静默裁掉必要状态。
- 检查点 2（第 3 步后）：独立核对 G5 所需原始材料可达，缺项会提示补读。
- 边界样本：无效角色、worker 无任务文件边界、活跃 Spec 不存在、无 Git 仓库、多个活跃 Spec、G5 缺需求原文 / diff / 验证摘要、无效基准引用、旧 Spec 无新字段、旧式零参数与单参数调用。
- 拆分自查：每步围绕一个入口或一类证据；脚本与指南同步后再运行完整自检。

## 3. 接口契约与兼容性

- 接口：`ai-resume.sh owner [feat]`、`ai-resume.sh worker <feat> <task-id>`、`ai-resume.sh review <feat> <base-ref>`。任务 ID 指 `tasks.md` 中的 Task 编号；审查基准必须是有效 Git commit-ish。
- worker 输出当前任务的路径、边界、依赖、WIP 与 Git 变更路径；不转贴完整 Spec 或上一 Agent 对话。任务详情仍由 Agent 读取项目原件。
- review 输出必读原件的路径和审查范围，不包含实现者的“已完成”断言；要求可解析的 `base-ref` 与非空变更范围。缺证据时提示补读并非零退出，接手成功不代表 G5 通过。
- 对无效角色、缺边界或旧式调用直接报错并保持非零退出，输出新命令示例；旧 Spec 文件格式不变。
- 不新增宿主专属存储、持久缓存或 token 遥测。

## 4. 影响面与涉及文件清单

- 新建文件：
  - `docs/specs/active/feat-context-loading/baseline.md`：同一夹具的基线和改后代理指标。
- 修改文件：
  - `template/scripts/ai-resume.sh`：必选角色子命令与失败处理。
  - `template/scripts/harness-selftest.sh`：角色接手、兼容和缺证据正反例。
  - `template/AGENTS.md`：各角色最小读取规则。
  - `template/.agents/skills/code-review.md`：G5 原始证据清单和独立性。
  - `template/.agents/skills/retrofit-legacy.md`：旧项目接力检查命令迁移。
  - `template/docs/specs/_templates/tasks.md`：WIP 接手提示指向显式角色入口。
  - `README.md`：对外命令与适用条件。
  - `docs/architecture/modules/guidance.md`：项目指南边界。
  - `docs/architecture/modules/template-mechanism.md`：脚本入口语义。
  - `docs/architecture/modules/self-hosting.md`：本仓库接手方式。
  - `AGENTS.md`：本仓库自用命令保持与模板一致。
- 只读依赖契约：
  - `template/scripts/ai-gate.sh`：G5 门禁和阶段状态。
  - `template/docs/specs/_templates/verification.md`：验证摘要格式。
  - `harness/verify.conf`：本仓库自检调用。
- 间接消费者 / 副作用：根目录薄转发脚本、已安装到目标项目的旧入口、跨 IDE 会话、G5 审查者和多 Spec 工作区；旧调用需迁移提示，现存文档和自检调用点需同步。
- 检索依据：已检索 `template/AGENTS.md`、`template/.agents/skills/`、`template/scripts/ai-resume.sh`、`template/scripts/ai-gate.sh`、`README.md`、架构索引和已有交付度量中的 subagent、独立上下文、并行与接手用法。

不启用 scoped 状态指纹；尚未核对所有验证命令的隐含依赖，正式 G4 保守使用全仓。

## 5. 对抗自审

1. 最可能的错误是减少了输出，却使 worker 漏读任务约束或审查者漏读原始需求；用缺项负例验证。
2. 输出字节数下降不证明模型 token、费用或端到端耗时下降；报告分开呈现。
3. 角色参数不能识别 Agent 身份，也不能阻止外部工具自行复制全文；文档必须说明适用边界。
4. 若新入口未达固定样本目标，回到 G3 调整脚本输出范围，不以指南变更掩盖失败。
5. 回滚时恢复上一版接手脚本和相应指南，重新运行自检。

## 6. 待确认问题

- [x] Q1：前置架构取舍由维护者决定：A）改角色指南；B）增加显式角色接手参数。→ 结论：两者都做；来源为用户本会话「我觉得A、B都应该改」。
- [x] Q2：旧命令是否继续兼容？→ 结论：用户允许不兼容。采用更简单的必选角色子命令，旧命令明确提示迁移。

## 7. 风险与回滚

- 风险：角色化输出遗漏约束；代理指标被误读为真实耗时收益；旧调用方未迁移。
- 回滚：恢复上一版脚本和指南，重跑完整自检；保留基线作为风险分析证据。
