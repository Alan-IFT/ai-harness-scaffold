# 模板机制

- **任务池**：`template/scripts/ai-task-pool.sh` 管理 `docs/task-pool/T-NNNNNN.md`。AI 用 `intake` 收录并路由新需求；`start-next` 在任务池锁内一次完成活跃检查、选取与启动；`archive` 持同一把锁移动活跃 Spec，归档完成后再领取下一项。活跃 Spec 优先，否则按一次性人工指定或 T-ID 升序启动。`prefer` 把指定写入 `docs/task-pool/NEXT`，仅启动该任务时清除。旧优先级字段不影响顺序。原话和补充在单个文件；仅记录稳定 Spec ID，进行中/已归档由 Spec 目录派生。owner 接手调用只读 `next`。根目录入口只转发。

- **职责**：`template/scripts/` 实现 G1~G7、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/docs/specs/_templates/` 存项目模板。接力命令 `ai-resume.sh` 使用必选 `owner [feat]`、`worker <feat> <task-id>`、`review <feat> <base-ref>` 子命令；旧式调用报迁移提示。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `docs/specs/`、`.knowledge/`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`ai-verify.sh --quick` 仅执行项目 `QUICK_CHECK`，不写 G4 摘要；正式调用仍运行配置的完整检查并写摘要。`ai-state-id.sh --spec` 在 design §4 显式确认验证依赖清单后，才从精确路径构建指纹；多路径条目、无可靠清单或有未归属改动时回退全仓。`harness-selftest.sh` 串行覆盖正反例并输出各节耗时，CI 另跑项目回归。
- **追溯与统计**：新 Spec 用追溯版本标记启用 G3 的 REQ/ERR/AC 覆盖矩阵检查与 G4 的任务设计章节检查；旧 Spec 保持原门禁。`ai-knowledge.sh usage` 只读扫描通过 G4 的 active/archive Spec 注入知识行，按 Spec 去重派生采用数。
- **评分与可选 CI 指标**：G1 校验七维固定权重、加权分、单项得分大于 3 及 `FEASIBILITY_MIN`；模板解释该规则，不新增旧 Spec 的门禁。覆盖率和变异测试配置仅供目标项目 CI 选择接线；项目应核对报告与低于阈值时的失败路径，未接线不能视为通过。
- **AC 含糊词**：G2 在空单元格检查后扫描 §3 的 AC 行，命中内置含糊词表即拒绝并输出命中词。用 index/substr 成对剥离「」『』与反引号内的被测原文，字节 locale 下不拆多字节字符；英文转小写后按词边界匹配（字母、数字、下划线算词内字符，标识符片段不拦；etc 须带句点，句点后同样判词边界），不依赖 gawk 扩展；中文长词在前，命中「大概率」时报完整词并给出改写示例；awk 执行失败按未通过处理。G2 只在 check/pass g2 运行，已过 G2 的 Spec 不受影响。
- **locale 无关**：宿主 shell 可能没有 UTF-8 locale，脚本不强制设置 `LC_ALL`。多字节字符不放进 `[]` 字符类，改用字面量交替或 index/substr；全角空格在空白判断前归一为半角。象限无法识别时 G3 拒绝。自检用显式 `LC_ALL=C` 复跑象限、字段、任务编号与指纹范围用例。
