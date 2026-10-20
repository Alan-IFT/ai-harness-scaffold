# 技术架构与接口设计：feat-delivery-speed

- 关联需求：requirements.md
- 设计者：Codex
- 状态：Approved

## 0. 模块关联
- 主模块：模板机制 → docs/architecture/modules/template-mechanism.md
- 涉及模块：项目指南 → docs/architecture/modules/guidance.md；本仓库自用 → docs/architecture/modules/self-hosting.md
- 契约入口（只读）：template/scripts/ai-verify.sh、template/scripts/ai-state-id.sh、template/scripts/ai-gate.sh、template/AGENTS.md
- 人工前置决策：决策人 维护者；取舍为保留正式全量验证和独立 CR，用 quick 缩短开发循环，并以明确条件委托而非默认免审批处理 G6；结论来自本会话「那就按照建议进行修改吧」。

## 1. 架构变更与数据流
项目仍仅依赖 Bash、Git、项目内 Markdown。quick 只输出终端检查结果，不生成 verification.md；full 维持 G4 证据。G3 的 .gates 行保存基准提交和当时的条件委托哈希；state-id 从设计清单构建 scope，并核对基准至当前的已提交及工作区改动归属，不能安全解析时用全仓算法。G6 必须比对委托快照。阶段时间从 .gates 即时计算，metrics.md 只保留归档事实。

## 2. 实现顺序、垂直切片与检查点
1. 分层验证和本仓库 quick 配置：quick 真检查，full 仍含完整自检；先跑 quick 正反例。
2. G3 边界样本与 G6 条件委托：更新门禁、模板和正反例；检查点 1：拒绝条件的样本先通过。
3. scope 指纹：显式确认验证依赖后从 design §4 的精确文件路径读取，加保守回退及未归属改动保护；Git 沙箱测试目标内外改动。检查点 2：确认旧 Spec 仍可验证。
4. 单一状态和度量输出、①紧凑指南：resume 读 .gates，gate 输出门间耗时，模板删冗余阶段复述；完整回归。
- 检查点：第 2、3 步后均核对旧项目兼容和负样例。
- 边界样本：quick 无检查、quick 不覆盖已通过摘要、缺边界样本、旧 Spec 无清单、清单含 glob 或多路径条目、另一活跃 Spec 改动、未归属改动、指纹目标内变化、委托缺来源、G6 新重大风险、AC 缺项。
- 拆分自查：每步最多跨一个机制切片，跨模块文档在最后一步同步。

## 3. 接口契约与兼容性
- ai-verify.sh [--quick] [--spec feat] target：无 --quick 时仍为正式验证；quick 用 harness/verify.conf 中 QUICK_CHECK，零检查失败且不写摘要。
- ai-state-id.sh [--spec feat] target：提供有效 scope 才用 scoped 算法；旧单参数形式保持全仓算法。
- ai-gate.sh metrics feat：仅从 .gates 输出可证明的门间耗时；缺时间记未知。
- acceptance.md：②③可记录「条件委托」和来源，只有 G3 明确授权且本次风险没有超出委托时生效；默认当次人工决定。
- 旧 Spec、无 Git 项目继续使用保守状态指纹；任何错误都不应变成空范围 PASS。

## 4. 影响面与涉及文件清单
- 新建文件：无。
- 修改文件：
  - `template/scripts/ai-verify.sh`：quick 与 full 证据分离。
  - `template/scripts/ai-state-id.sh`：scope 与保守回退。
  - `template/scripts/ai-gate.sh`：G3 边界样本、G6 委托、metrics 与 scope 调用。
  - `template/scripts/ai-resume.sh`：去过时 G6 提示，显示权威阶段。
  - `template/scripts/harness-selftest.sh`：关键正反例。
  - `template/docs/specs/_templates/design.md`：边界样本与可解析文件清单要求。
  - `template/docs/specs/_templates/tasks.md`：①紧凑说明、阶段不重复记录。
  - `template/docs/specs/_templates/acceptance.md`：条件委托字段。
  - `template/harness/verify.conf.example`：quick 配置范例。
  - `template/docs/metrics.md`：度量的时间来源说明。
  - `template/AGENTS.md`：分层验证和委托语义。
  - `template/.agents/skills/new-spec.md`：G3 边界审查指引。
  - `template/.agents/skills/code-review.md`：审查状态与被审代码绑定。
  - `template/.agents/skills/archive-spec.md`：度量从门禁生成。
  - `harness/verify.conf`：本仓库 quick 检查。
  - `AGENTS.md`：本仓库执行指南。
  - `README.md`：用户命令和兼容说明。
  - `docs/architecture/modules/template-mechanism.md`：活文档。
  - `docs/architecture/modules/guidance.md`：活文档。
  - `docs/architecture/modules/self-hosting.md`：活文档。
  - `docs/INTAKE.md`：需求入口链接。
- 只读依赖契约：
  - `harness/redlines.conf`：验证预算。
  - `template/scripts/ai-config.sh`：阈值加载。
  - `bin/ai-harness`：安装复制行为。
- 间接消费者 / 副作用：根目录薄转发、安装到新项目、旧项目 retrofit、已有 Spec、多个活跃 Spec 及 CI；旧格式缺 scope 必须保守兼容。
- 检索依据：已在 template/scripts、template/docs/specs/_templates、template/AGENTS.md、根目录 scripts、harness、README 及归档 Spec 中有界检索 ai-verify、ai-state-id、G3/G6、metrics；无外部服务。

## 5. 对抗自审
1. 最可能错在 scope 漏依赖而假 PASS；只在精确清单有效时启用，否则全仓。
2. 假设 Git 能识别其他活跃 Spec 的清单；冲突或不可归属应拒绝或全仓。
3. quick 零检查、委托缺来源或风险变化必须明确失败。
4. 不新增宿主插件或状态数据库；只扩展现有脚本。
5. 回滚代码与相应 G4 后门，恢复旧全仓指纹和正式验证。
- 自审结论：以“宁可多跑一次，也不能误报通过”为取舍；测试必须覆盖拒绝路径。

## 6. 待确认问题
- [x] 技术选择：旧 Spec 缺精确清单时使用全仓回退；不阻塞。

## 7. 风险与回滚
- 风险：缩小状态范围可能漏影响，条件委托可能被错误套用。
- 回滚方式：回退本 Spec 的实现提交，重跑完整自检，重置受影响 G4~G6。
