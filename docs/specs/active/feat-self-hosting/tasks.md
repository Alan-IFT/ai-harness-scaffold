# 执行队列与接力：feat-self-hosting

- 需求：docs/specs/active/feat-self-hosting/requirements.md
- 设计：docs/specs/active/feat-self-hosting/design.md
- 阶段：以 bash scripts/ai-gate.sh status feat-self-hosting 为准。

## 0. 阶段门
G1 需求 → G2 AC → G3 设计 → G4 实现验证 → G5 独立审查 → G6 人工验收 → G7 归档。

## 1. 上下文清单
- 必读：根目录 AGENTS.md、本 Spec、docs/architecture/00-INDEX.md、docs/architecture/modules/self-hosting.md。
- 条件读：template/scripts/ai-new-spec.sh、template/scripts/ai-gate.sh、bin/ai-harness。
- 注入知识：无相关卡片。
- 知识检索：已查 `.knowledge/INDEX.md`，当前为空；本任务无可注入卡片。
- 不变量：Git main、原 HEAD 与原有未提交改动保留；template/scripts/ 为机制唯一源码。

## 2. 原子任务
- [x] Task 1：确认仓库现有 Git 状态及源码边界。证据：main 已存在，HEAD 为 1a1027a，开始时已有上一轮未提交改动。
- [x] Task 2：建立根目录规则、架构文档、状态目录和薄入口；使新建 Spec 复用 template/ 的模板。涉及 AGENTS.md、scripts/、harness/、docs/、template/scripts/ai-new-spec.sh。
- [x] Task 3：G1~G3 已通过；根目录上下文体检、知识索引和接力快照正常；实际增量验证已跑通。目标：template/scripts/ai-new-spec.sh。验证命令：bash scripts/ai-verify.sh --spec feat-self-hosting template/scripts/ai-new-spec.sh。

## 3. 发现但不碰
- 上一轮脚手架通用改造仍有未提交文件。本任务不替它重写历史，也不把它冒充为本任务完成的代码。

## 4. Current WIP & Handoff Scratchpad
- 当前任务：用户调整 G6 分工，已回退 G1~G5；需求和设计已同步，待逐门重验及独立复审。
- 前置依赖 / 并行关系：Task 1、2 已完成；本任务独立执行。
- 已完成的小步：建立根目录状态、薄脚本、项目专属索引；G1~G3 通过；自用 verify 已生成 PASS 摘要。
- 正在编辑的文件：无；后续如改代码或项目文档，重新验证。
- 已排除的死胡同：不在根目录复制 template/scripts 实现；不重新初始化已有 Git 仓库。
- 上次验证与未验证改动：见 verification.md；新流程改造涉及 `ai-new-spec.sh` 后已重跑验证并回退 G4 再推进。任何后续代码或提交变化都须重新验证。
- 下一步立即执行的唯一动作：依次重过 G1~G3，再跑增量验证、G4 与独立审查。
- knowledge_feedback：无。
