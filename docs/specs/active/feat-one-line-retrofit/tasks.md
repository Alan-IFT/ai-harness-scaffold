# 原子执行队列与跨工具接力棒：feat-one-line-retrofit

- 需求文档：requirements.md
- 设计文档：design.md
- 阶段：以 `bash scripts/ai-gate.sh status feat-one-line-retrofit` 为准，不复制阶段表。

## 0. 阶段门
按 AGENTS.md 的 G1～G7 执行；G4 需正式验证，G5 需独立审查。

## 1. 上下文清单
- 必读：requirements.md、design.md、`docs/architecture/modules/cli.md`、`docs/architecture/modules/guidance.md`、`bin/ai-harness` 的 install/retrofit 分支。
- 条件读：`template/.agents/skills/retrofit-legacy.md`、官方宿主技能路径说明。
- 明确不读：无关历史 Spec、业务实现代码。
- 注入知识：无相关卡片；知识库当前无卡。
- 知识检索：`bash scripts/ai-knowledge.sh suggest cli` 无有效候选；已读 CLI 活文档。
- 本次不变量：一份流程正文；旧 DSH 命令可用；目标项目已有文件和 Git 不被覆盖。

## 2. 原子任务序列
- [x] Task 1：精简共享技能与 README 的一句话入口。对应 AC-01。
- [x] Task 2：为 Codex/Claude 安装薄入口，验证幂等与冲突拒绝。对应 AC-01、AC-02。
- [x] Task 3：修复 retrofit 的 Git 归属识别，并用临时仓库样本验证。对应 AC-03。
- [x] Task 4：正式全量验证与本机技能安装结果记录。对应 AC-04；独立审查由 G5 门记录。

## 3. 发现但不碰
- 暂无。

## 4. Current WIP & Handoff Scratchpad
- 当前任务：实现和正式验证已完成；等待独立审查结论与 G4/G5 门记录。
- 前置依赖 / 并行关系：先稳定共享入口，再实现安装器，最后做兼容测试。
- 已完成的小步：G1～G3 通过；Codex/Claude 本机入口安装并检查源指针；重复安装、跨宿主/异源/旧标记拒绝、写失败、DSH 兼容、dry-run、父仓库、worktree、异常 Git 归属及全新仓库临时样本均通过；正式自检 126/126。
- 正在编辑的文件：仅 Spec 审查与验收记录。
- 已排除的死胡同：为每个 IDE 复制完整模板流程。
- 上次验证与未验证改动：`bash -n bin/ai-harness`、临时行为样本、正式验证 126/126 通过；`verification.md` 已暂存，后续仅更新流程记录。
- 下一步立即执行的唯一动作：拿到独立复审结果后记录 G4/G5。
