# 原子执行队列与跨工具接力棒：feat-verify-archive-cost

- 需求文档：requirements.md
- 设计文档：design.md
- 阶段：以 `bash scripts/ai-gate.sh status feat-verify-archive-cost` 为准，不在此复制阶段表。

## 0. 阶段门
按 AGENTS.md 的 G1~G7 执行；G4 仍需完整正式验证，G5 仍需独立 CR。

## 1. 上下文清单
- 必读：requirements.md、design.md、`docs/architecture/modules/template-mechanism.md`、`template/scripts/ai-gate.sh` 的 G6 和自检相应段落。
- 条件读：`template/docs/INTAKE.md`、建 Spec / 归档指南、`ai-state-id.sh` 的流程文件排除规则。
- 明确不读：无关归档 Spec 全文、全部自检日志。
- 注入知识：无相关卡片；项目当前无知识卡。
- 知识检索：`bash scripts/ai-knowledge.sh suggest template-mechanism` 无有效候选；已读模板机制活文档。
- 本次不变量：原 G6/G4/G5 检查不变；正式自检完整保留；入口只存一次处理决定和稳定 ID。

## 2. 原子任务序列
- [x] Task 1：剖析完整自检并试验 G6 顺序；实测总耗时无改善，撤回实现和新增测试，保留剖析结论。对应 AC-01。
- [x] Task 2：模板与本仓库入口用稳定 Spec ID，创建脚本拒绝重用已归档 ID；知识卡和路线图更新前移到最后一次正式 G4 之前，归档时只复核；正式验证拒绝以会变动的流程文件为目标；更新指南和活文档。对应 AC-03。
- [x] Task 3：完整自检、正式验证、兼容检查与结果记录。对应 AC-02、AC-04。

## 3. 发现但不碰
- 暂无。

## 4. Current WIP & Handoff Scratchpad
- 当前任务：正式验证已通过，等待独立审查最终结论和 G6 结果决定。
- 前置依赖 / 并行关系：性能试验已撤回，剩余工作为验证与独立审查。
- 已完成的小步：基线自检 121/121；第 3 段 64 秒。G6 顺序试验 123/123，第 3 段 61 秒但总耗时约 139 秒，已撤回。
- 正在编辑的文件：入口模板、项目入口、建 Spec 与归档指南、README 和活文档。
- 已排除的死胡同：提高 120 秒预算、删完整检查或仅前移 G6 拒绝顺序均未减少实际总耗时。
- 上次验证与未验证改动：最终正式验证 PASS，自检 126/126、失败 0、145 秒；无未验证的代码改动。
- 下一步立即执行的唯一动作：过 G4、完成独立审查与 G5，准备 G6 核验。
