# 原子执行队列与跨工具接力棒：feat-context-loading

- 需求文档：`docs/specs/active/feat-context-loading/requirements.md`
- 设计文档：`docs/specs/active/feat-context-loading/design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-context-loading` 为准。

## 0. 阶段门

以 `.gates` 为阶段事实。用户已决定指南和脚本都改，并允许废弃旧接手用法；需求与设计更新后重过 G1~G3。

## 1. 上下文清单

- 必读：`requirements.md`、`design.md`、本文件、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`。
- 条件读：修改脚本时读 `template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`；修改审查指南时读 `template/.agents/skills/code-review.md` 和 G5 的 `template/scripts/ai-gate.sh` 契约。
- 明确不读：历史 Spec 全文、无关模块内部实现、全部自检日志。
- 注入知识：无相关卡片。
- 知识检索：已运行 `ai-knowledge.sh suggest guidance` 与 `suggest template-mechanism`；两者均无有效候选，因此不注入。已核对对应模块活文档与实际接手脚本。
- 本次不变量：三种角色均需显式选择；旧命令有迁移提示；G5 独立审查的原始证据不被精简摘要取代；代理指标不冒充 token 或真实耗时。

## 2. 原子任务序列

- [x] **Task 1：建立固定夹具与加载基线**
  - 涉及文件：`docs/specs/active/feat-context-loading/baseline.md`
  - 对应需求 / 验收：REQ-03 / AC-03
  - 对应设计：design.md §2、§3
  - 完成判据：固定 Git 状态、三类角色输入、字节和重复项计数方法；无法取得的数据标「未知」。
  - 验证命令：复算记录中的 `ai-resume.sh` 输出字节；核对夹具提交与命令。
  - 检查点：G3 前不启动。

- [x] **Task 2：实现必选角色接手入口**
  - 涉及文件：`template/scripts/ai-resume.sh`、`template/AGENTS.md`
  - 对应需求 / 验收：REQ-01、REQ-04、ERR-01 / AC-01、AC-04
  - 对应设计：design.md §1、§2、§3
  - 完成判据：owner、worker、review 入口清晰；worker 仅给相关路径和必要状态；旧式调用及无效参数非零退出并给迁移提示。
  - 验证命令：`bash -n template/scripts/ai-resume.sh`；三角色与旧式调用夹具检查。
  - 检查点：第 2 步后对照必要状态。

- [x] **Task 3：保住 G5 原始证据与失败提示**
  - 涉及文件：`template/.agents/skills/code-review.md`、`template/scripts/ai-resume.sh`
  - 对应需求 / 验收：REQ-02、ERR-02 / AC-02
  - 对应设计：design.md §1、§2、§3
  - 完成判据：审查者得到原始证据路径；缺需求、diff 或验证状态会提示补读；不注入实现者自评。
  - 验证命令：G5 正反例夹具与 `bash scripts/harness-selftest.sh`。
  - 检查点：第 3 步后独立核对审查输入。

- [x] **Task 4：迁移项目指南与正式调用点**
  - 涉及文件：`README.md`、`AGENTS.md`、`template/.agents/skills/retrofit-legacy.md`、`template/docs/specs/_templates/tasks.md`
  - 对应需求 / 验收：REQ-01、REQ-04 / AC-01、AC-04
  - 对应设计：design.md §2、§3、§4
  - 完成判据：所有正式命令示例使用必选角色；旧命令仅在迁移说明和负例中出现。
  - 验证命令：`rg -n 'ai-resume\.sh' README.md AGENTS.md template`；`git diff --check`。
  - 检查点：确认根目录转发脚本仍不复制逻辑。

- [x] **Task 5：机制自检、架构文档与对比测量**
  - 涉及文件：`template/scripts/harness-selftest.sh`、`docs/specs/active/feat-context-loading/baseline.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/self-hosting.md`
  - 对应需求 / 验收：REQ-02、REQ-03、REQ-04、ERR-01、ERR-02 / AC-01、AC-02、AC-03、AC-04
  - 对应设计：design.md §1、§2、§3、§4
  - 完成判据：同一夹具复测并写出差值；三角色、旧式调用迁移提示、错误路径、旧 Spec 与 G5 自检通过。
  - 验证命令：`bash scripts/harness-selftest.sh`；`bash scripts/ai-verify.sh --spec feat-context-loading template/scripts/ai-resume.sh`。
  - 检查点：G4 前完整验证。

## 3. 发现但不碰

- 暂无。宿主级 token / 耗时遥测若不可得，只记录为未知，不扩展平台权限。

## 4. Current WIP & Handoff Scratchpad

- 当前正在执行的任务：实现、G5 独立复审和 G6 交付核验已完成；正在归档。
- 前置依赖 / 并行关系：Task 1 → Task 2 → Task 3 → Task 4 → Task 5。Task 2 与 Task 3 共用 `ai-resume.sh`，顺序执行。
- 已完成的小步进展：第一轮审查的三项问题已修复；正式验证重新 PASS（154/154 自检，170 秒）；独立复审关键问题 0、G5 已通过；同状态旧版、worker、review 输出为 5792 / 1237 / 1367 字节，读取路径与命令来源见 `baseline.md`。
- 正在编辑的文件：无。
- 已排除的死胡同 / 错误方案：不能从现有门间耗时推断重复加载造成严重拖延；不将 G5 的必要独立阅读计为无意义复制。
- 上次验证与未验证改动：修复后正式验证 PASS；之后仅更新本 Spec 的度量、复审、验收记录及归档度量，未再修改实现文件。
- 下一步立即执行的唯一动作：归档 Spec，运行 G7 和收尾体检。
- knowledge_feedback：无。
