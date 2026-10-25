# 设计：feat-flow-closure

## 0. 模块关联
- 主模块：`docs/architecture/modules/template-mechanism.md`
- 涉及模块：`docs/architecture/modules/guidance.md`
- 契约入口：`template/scripts/ai-gate.sh`、`template/scripts/ai-knowledge.sh`、`template/AGENTS.md`
- 人工前置决策：决策人=本次用户；取舍=按上一轮推荐改造并保留项目文档跨 IDE；结论=实施轻量方案。

## 1. 架构变更与数据流
粗想法先记入项目内 `docs/INTAKE.md`，正式开发进入 Spec；象限决定门禁行为；知识卡按模块检索并按路径提示复核。G6 由 Agent 汇总证据并记录验收：①证据充分时自动推进，②③对话取得人的风险与结果判断后推进；G7 归档并补交付反馈。

## 2. 实现顺序、垂直切片与检查点
1. 补需求入口、象限说明、影响面和交付反馈模板，核对新项目复制结果。
2. 改 G1/G2/G3 路由与影响面校验，并补正反例自检。
- 检查点 1：脚本语法和门禁相关自检通过。
3. 扩展知识卡和 `ai-knowledge.sh` 推荐、影响提示及 G4 检查。
4. 更新指南、README 和度量，做完整自检与 CLI dry-run。
- 检查点 2：全套自检通过且既有项目文件未覆盖。
5. 调整 G6 校验、验收模板和指南：不再要求人填写文件、亲跑命令或勾选全部材料；补①自动与②③交互决定的正反例，再重验本 Spec 和 self-hosting。

## 3. 接口契约与数据结构变更
- ④通过 G1 分类后停止于人工移交；①允许单步设计；②③需要人的前置决策留痕。
- 知识卡新增可选关联路径；旧卡仍可读取，注入时检查有效期与状态。
- `acceptance.md` 区分「核验执行者 / 测试环境 / 客观证据 / 结论」与「人工决策人 / 人工决定 / 决策来源」。②③必须有明确人工决定；Agent 可在记录真实来源后执行 `pass g6`，门禁不把执行者冒充为决策人。①不要求人工决定。无云端身份认证时，本地文件只能防遗漏，不能证明发言者身份。
- 可交接状态指纹基于 Git 索引、未暂存补丁与未跟踪文件内容，不直接包含 HEAD；Spec 与 `docs/metrics.md` 属于流程记录，不参与代码指纹。代码内容变化仍使 G4 过期；相同内容从暂存到提交不改变指纹，使验证摘要能够在干净提交与归档记录后保持有效。暂存代码改变索引时需重新验证。

## 4. 影响面与涉及文件清单
- 新建：`template/docs/INTAKE.md`。
- 本仓库自用：新建 `docs/INTAKE.md` 与 `docs/metrics.md`，只存本项目事实与度量，不复制模板业务示例。
- 本仓库入口：同步根目录 `AGENTS.md` 与 `docs/architecture/modules/self-hosting.md` 的路径说明。
- 修改：`template/scripts/ai-gate.sh`、`template/scripts/ai-state-id.sh`、`template/scripts/ai-knowledge.sh`、`template/scripts/harness-selftest.sh`、`template/scripts/ai-new-spec.sh`、`template/AGENTS.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/knowledge-distill.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/gc-memory.md`、`template/.agents/skills/retrofit-legacy.md`、`template/docs/specs/_templates/requirements.md`、`template/docs/specs/_templates/design.md`、`template/docs/specs/_templates/tasks.md`、`template/docs/specs/_templates/knowledge-card.md`、`template/docs/specs/_templates/acceptance.md`、`template/docs/metrics.md`、`README.md`。
- 只读：`bin/ai-harness`、根目录 `scripts/`、架构索引。
- 知识索引说明：同步 `template/.knowledge/INDEX.md` 的检索与有效性口径。
- 安装向导说明：同步 `skill/SKILL.md` 的模板文件清单。
- 间接消费者 / 副作用：init、retrofit、已有 Spec、知识索引、G1~G7 自检。
- 检索依据：已核对门禁、知识脚本、归档流程、CLI 复制逻辑和模板引用；实现后复查。

## 5. 对抗自审
- 最可能错在旧 Spec 与新校验不兼容；保持旧知识卡可读，并用正反例验证。
- 不能从「审查没问题」推断人读过四类材料或执行过命令；Agent 的检查与人的决定分别留来源。
- 人工前置决策只能做留痕校验，真实审批需项目自己的权限机制。
- 不新增门编号和云端服务；新增字段均可短句填写。
- 自审结论：先落实机械路由，再同步指南。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- 风险：既有文档过新校验时需补字段。
- 回滚：按 Git 撤销本次模板与脚本改动。
