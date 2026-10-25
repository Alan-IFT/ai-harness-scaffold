# 模板机制

- **任务池**：`template/scripts/ai-task-pool.sh` 管理 `process/task-pool/T-NNNNNN.md`。AI 用 `intake` 收录并路由新需求；`start-next` 在任务池锁内一次完成活跃检查、选取与启动；`archive` 持同一把锁移动活跃 Spec，归档完成后再领取下一项。活跃 Spec 优先，否则按一次性人工指定或 T-ID 升序启动。`prefer` 把指定写入 `process/task-pool/NEXT`，仅启动该任务时清除。旧优先级字段不影响顺序。原话和补充在单个文件；仅记录稳定 Spec ID，进行中/已归档由 Spec 目录派生。owner 接手调用只读 `next`。根目录入口只转发。

- **职责**：`template/scripts/` 实现三道门（g1 计划、g2 验证、g3 审查）、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/process/specs/_templates/` 存项目模板。接力命令 `ai-resume.sh` 使用必选 `owner [feat]`、`worker <feat> <task-id>`、`review <feat> <base-ref>` 子命令；旧式调用报迁移提示。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `process/specs/`、`MEMORY.md`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`ai-verify.sh --quick` 仅执行项目 `QUICK_CHECK`，不写验证摘要；正式调用仍运行配置的完整检查并写摘要。`ai-state-id.sh` 只有全仓模式，排除 `process/**`（`--spec` 为兼容保留、不影响结果）；局部清单模式已在 2.0 删除，因为它依赖人工确认验证依赖，且每新增流程文件都要补排除清单。流程记录不能作正式验证目标。脚本不检测旧布局：兼容逻辑会持续膨胀，跨版本布局变化写成说明由项目 AI 手动迁移（维护者 2026-10-25 决定）。`harness-selftest.sh` 串行覆盖正反例并输出各节耗时，CI 另跑项目回归。
- **可选 CI 指标**：覆盖率和变异测试配置仅供目标项目 CI 选择接线；项目应核对报告与低于阈值时的失败路径，未接线不能视为通过。
- **门禁只查骗不过的信号**（ADR-0003）：g1 查原话、「需人决定」以「是 / 否」开头、AC 表无空单元格、待确认清零、方案思路与任务存在；g2 查任务全勾、验证摘要 PASS、checks≥1 且指纹一致；g3 查审查者、未参与实现、关键问题 0、CR 轮次上限、审查状态与验证摘要一致，「需人决定：是」时还要人工决定与来源。不扫描措辞，不检查章节结构。
- **locale 无关**：宿主 shell 可能没有 UTF-8 locale，脚本不强制设置 `LC_ALL`。多字节字符不放进 `[]` 字符类；全角冒号与全角空格在取字段值前归一。自检用显式 `LC_ALL=C` 复跑字段与任务编号用例。
