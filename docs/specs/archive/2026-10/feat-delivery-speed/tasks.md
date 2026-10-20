# 原子执行队列与跨工具接力棒：feat-delivery-speed

- 需求文档：requirements.md（本归档目录）
- 设计文档：design.md（本归档目录）
- 阶段：只以 bash scripts/ai-gate.sh status feat-delivery-speed 为准；不要在此维护副本。

## 0. 阶段门
按根 AGENTS.md 的 G1~G7 执行；G4 只认正式 full 摘要，G5 保留独立 CR，G6 按风险和明确授权判断。

## 1. 上下文清单
- 必读：requirements.md、design.md、docs/architecture/modules/template-mechanism.md、template/scripts/ai-verify.sh、ai-state-id.sh、ai-gate.sh。
- 条件读：template/AGENTS.md、模板文档、harness/verify.conf 与安装脚本。
- 明确不读：无关归档 Spec 的全部内容、全量测试输出。
- 注入知识：无相关卡片；现有卡片与本次验证/门禁机制无直接复用关系。
- 知识检索：`bash scripts/ai-knowledge.sh suggest template-mechanism` 返回「无有效候选」；已读模板机制活文档，故不注入卡片。
- 本次不变量：根脚本薄转发；full 与旧单参数指纹兼容；未验证不算通过。

## 2. 原子任务序列
- [x] Task 1：quick 真检查且不覆盖 G4 摘要；本仓库配置 quick/full，已加正反例。对应 AC-01。
- [x] Task 2：G3 边界样本和 G6 条件委托门禁、模板及正反例。对应 AC-02、AC-05。
- [x] Task 3：精确清单 scope 指纹、G3 基准提交与保守回退；Git 沙箱覆盖范围内外改动和旧 Spec。对应 AC-03、AC-06。
- [x] Task 4：从 .gates 派生阶段与度量，简化①记录，更新跨 IDE 指南与活文档。对应 AC-04、AC-06。

G4 后收尾：正式验证、独立 CR、G6 核验与归档；不作为 G4 的实现任务复述。

## 3. 发现但不碰
- 完整自检已扩大到 121 项；正式检查耗时 137 秒，超过当前 120 秒提醒线。分层 quick 缩短开发循环，完整检查的运行耗时留待取得更多大仓库样本后单独优化。
- 归档时更新 `docs/INTAKE.md` 链接使原 G4 指纹过期，本次额外正式验证 137 秒。后续应把此类流程链接更新前移至最后一次正式验证，或单独设计流程文档的指纹边界。

## 4. Current WIP & Handoff Scratchpad
- 当前任务：G1~G7 已记录，交付结果由 维护者 决定通过；归档状态已重新正式验证。
- 前置依赖 / 并行关系：按顺序处理共享门禁脚本。
- 已完成的小步：G1~G3 已按审查后的需求和设计重过；quick 与安装样本已通过；独立审查指出的指纹漏依赖、清单多路径和委托边界已补反例。
- 正在编辑的文件：无；源码已提交，归档记录待最后提交。
- 已排除的死胡同：无。
- 上次验证与未验证改动：归档后正式验证 PASS、1 项检查、完整自检 121/121、137 秒；G4 对最终状态复核通过，以 verification.md 的新 state 为准。
- 下一步立即执行的唯一动作：提交归档记录。
