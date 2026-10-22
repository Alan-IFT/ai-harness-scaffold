# 原子执行队列：feat-t-000004

- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000004` 为准。

## 0. 阶段门

门禁状态由 .gates 管理，禁止手改。

## 1. 上下文清单

- 必读：`requirements.md`、`design.md`、本文件、`docs/architecture/modules/self-hosting.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`
- 条件读：`template/scripts/ai-verify.sh`、`template/scripts/harness-selftest.sh`、`tests/cli-upgrade.sh`
- 明确不读：其他归档 Spec 的内部报告与全量测试日志。
- 注入知识：无相关卡片
- 知识检索：`ai-knowledge.sh suggest self-hosting` 返回无有效候选；已核对活文档和真实配置。
- 本次不变量：正式 G4 保留自检和 CLI 回归；quick 不写 G4 摘要；根目录 scripts/ 保持转发。

## 2. 原子任务序列

- [x] **Task 1: 完整验证分段计时与双区 diff**
  - 涉及文件：`tests/verify-repo.sh`、`harness/verify.conf`
  - 对应需求 / 验收：REQ-01、REQ-02、ERR-01、ERR-02 / AC-01、AC-02
  - 对应设计：design.md §2 步骤 1、§3
  - 完成判据：阶段名称/耗时可见，失败即停，暂存区错误被拒。
  - 验证命令：`bash tests/verify-repo.sh`；隔离 Git 夹具。
- [x] **Task 2: 自检节耗时**
  - 涉及文件：`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01 / AC-01
  - 对应设计：design.md §2 步骤 1
  - 完成判据：13 节耗时可见，断言数与结果不变。
  - 验证命令：`bash scripts/harness-selftest.sh`
- [x] **Task 3: 相关 quick 检查**
  - 涉及文件：`tests/verify-repo-quick.sh`、`harness/verify.conf`
  - 对应需求 / 验收：REQ-02、REQ-03、ERR-02 / AC-02、AC-03
  - 对应设计：design.md §2 步骤 2、§3
  - 完成判据：Shell/CLI 语法、指南体积、双区 diff 按目标执行；quick 不写摘要。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000004 template/scripts/harness-selftest.sh`
- [x] **Task 4: G4 前核对指南与同步**
  - 涉及文件：`template/.agents/skills/new-spec.md`、`README.md`、`docs/architecture/modules/self-hosting.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`
  - 对应需求 / 验收：REQ-04 / AC-04
  - 对应设计：design.md §2 步骤 3
  - 完成判据：预检顺序清楚，说明与实现一致，正式验证通过。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000004 tests/verify-repo.sh`
  - 收尾动作：独立 G5 审查、G6 核验与归档。

## 3. 发现但不碰

- 暂无。

## 4. Current WIP & Handoff Scratchpad

- 当前正在执行的任务：无；准备正式 G4。
- 前置依赖 / 并行关系：顺序执行；任务 1 与任务 3 共用配置，修改时核对彼此。
- 已完成的小步进展：实现、指南和活文档已提交；quick、语法与隔离 Git 暂存错误夹具通过。
- 正在编辑的文件：无。
- 已排除的死胡同：自检共享沙箱不适合直接并行化。
- 上次验证与未验证改动：正式 G4 未运行。
- 下一步立即执行的唯一动作：运行正式验证并记录阶段耗时。
- knowledge_feedback：无。
