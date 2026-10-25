# 模板机制

- **任务池**：`template/scripts/ai-task-pool.sh` 管理 `process/task-pool/T-NNNNNN.md`。AI 用 `intake` 收录并路由新需求；`start-next` 在任务池锁内一次完成活跃检查、选取与启动；`archive` 持同一把锁移动活跃 Spec，归档完成后再领取下一项。活跃 Spec 优先，否则按一次性人工指定或 T-ID 升序启动。`prefer` 把指定写入 `process/task-pool/NEXT`，仅启动该任务时清除。旧优先级字段不影响顺序。原话和补充在单个文件；仅记录稳定 Spec ID，进行中/已归档由 Spec 目录派生。owner 接手调用只读 `next`。根目录入口只转发。

- **职责**：`template/scripts/` 实现 G1~G7、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/process/specs/_templates/` 存项目模板。接力命令 `ai-resume.sh` 使用必选 `owner [feat]`、`worker <feat> <task-id>`、`review <feat> <base-ref>` 子命令；旧式调用报迁移提示。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `process/specs/`、`MEMORY.md`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`ai-verify.sh --quick` 仅执行项目 `QUICK_CHECK`，不写 G4 摘要；正式调用仍运行配置的完整检查并写摘要。`ai-state-id.sh` 只有全仓模式，排除 `process/**`（`--spec` 为兼容保留、不影响结果）；局部清单模式已在 2.0 删除，因为它依赖人工确认验证依赖，且每新增流程文件都要补排除清单。流程记录不能作正式验证目标。脚本不检测旧布局：兼容逻辑会持续膨胀，跨版本布局变化写成说明由项目 AI 手动迁移（维护者 2026-10-25 决定）。`harness-selftest.sh` 串行覆盖正反例并输出各节耗时，CI 另跑项目回归。
- **追溯与统计**：新 Spec 用追溯版本标记启用 G3 的 REQ/ERR/AC 覆盖矩阵检查与 G4 的任务设计章节检查；旧 Spec 保持原门禁。
- **可选 CI 指标**：覆盖率和变异测试配置仅供目标项目 CI 选择接线；项目应核对报告与低于阈值时的失败路径，未接线不能视为通过。
- **门禁只查结构**（ADR-0002）：G1 查四项必答、原话、待确认、象限与分级依据；G2 查 AC 表编号、不通过条件与空单元格，不扫描措辞；G6 的冒烟、AC 汇总与逐条 AC 只认字段值开头的「通过」（其后须为行尾、空白或标点，「通过率」「不通过」不算），证据文本不扫描。含糊措辞与证据和结论矛盾由 `code-review.md` 的两项检查承接。G3 记录第 5 列为保留列（恒为 `none`），G5 按 5 列格式绑定审查状态。
- **locale 无关**：宿主 shell 可能没有 UTF-8 locale，脚本不强制设置 `LC_ALL`。多字节字符不放进 `[]` 字符类，改用字面量交替或 index/substr；全角空格在空白判断前归一为半角。象限无法识别时 G3 拒绝。自检用显式 `LC_ALL=C` 复跑象限、字段、G6 结构化结论、任务编号与指纹范围用例。
