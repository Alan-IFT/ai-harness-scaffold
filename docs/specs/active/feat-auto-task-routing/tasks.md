# 原子执行队列：feat-auto-task-routing

- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-auto-task-routing` 为准。

## 0. 阶段门
按 `AGENTS.md` 执行 G1~G7，不手改 .gates。

## 1. 上下文清单
- 必读：本 Spec、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`。
- 条件读：`template/scripts/ai-new-spec.sh`、`template/scripts/ai-resume.sh` 的公开调用方式。
- 明确不读：其他归档 Spec、完整验证日志。
- 注入知识：无相关卡片
- 知识检索：`bash scripts/ai-knowledge.sh suggest template-mechanism` 返回无有效候选；已读该模块活文档和任务池脚本，故不注入卡片。
- 本次不变量：一个项目至多一个活跃 Spec；原话保留；根目录脚本仅转发；next/list 不写入。

## 2. 原子任务序列
- [x] **Task 1: 默认 FIFO 与人工指定**
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-03、REQ-04、ERR-01 / AC-02、AC-03
  - 对应设计：design.md §1、§3
  - 完成判据：ID 顺序、一次性 NEXT、错误目标均有断言并通过。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-auto-task-routing template/scripts/ai-task-pool.sh`
- [x] **Task 2: 自动收录并启动**
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-01、REQ-02、ERR-02 / AC-01
  - 对应设计：design.md §1、§3
  - 完成判据：空池、有活跃 Spec、非空池及失败恢复均通过。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-auto-task-routing template/scripts/ai-task-pool.sh`
- [x] **Task 3: 自然语言入口和交付文档**
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/new-spec.md`、`template/docs/task-pool/README.md`、`template/docs/INTAKE.md`
  - 对应需求 / 验收：REQ-01、REQ-05 / AC-04
  - 对应设计：design.md §2、§4
  - 完成判据：AI 自动调用 intake/update/prefer，维护者无需运行命令。
  - 验证命令：`bash scripts/harness-selftest.sh`
- [x] **Task 4: 仓库文档与交付核对**
  - 涉及文件：`AGENTS.md`、`docs/task-pool/README.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`
  - 对应需求 / 验收：REQ-01~REQ-05 / AC-04
  - 对应设计：design.md §2、§4
  - 完成判据：仓库与模板口径一致，完成正式验证、独立审查。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-auto-task-routing template/scripts/ai-task-pool.sh`
- [x] **Task 5: 归档与任务路由同锁**
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`、`template/.agents/skills/archive-spec.md`
  - 对应需求 / 验收：REQ-02、ERR-02 / AC-01、AC-04
  - 对应设计：design.md §1、§2、§3
  - 完成判据：archive 和 start-next 同锁；锁冲突不移动 active；归档后可启动待办，旧 T-ID 按顺序。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-auto-task-routing template/scripts/ai-task-pool.sh`

## 3. 发现但不碰
- 记录：无。

## 4. Current WIP & Handoff Scratchpad
- 当前正在执行的任务：无；Task 1~4 已实现，准备正式 G4 验证。
- 前置依赖 / 并行关系：Task 2 依赖 Task 1；Task 3、4 依赖契约稳定。
- 已完成的小步进展：人工指定竞态与归档竞态均已实现修复；自检 210/210、正式验证 PASS、升级回归 PASS。
- 正在编辑的文件：无。
- 已排除的死胡同 / 错误方案：让维护者自行运行 add/next/start，不符合本次自然语言入口要求。
- 上次验证与未验证改动：归档协议 G3 已重过，正式验证 PASS，暂无未验证实现改动。
- 下一步立即执行的唯一动作：推进 G4 并请独立审查第三轮复核。
- knowledge_feedback：无。
