# 模板机制

- **任务池**：`template/scripts/ai-task-pool.sh` 管理 `process/task-pool/T-NNNNNN.md`。AI 用 `intake` 收录并路由新需求；`start-next` 在任务池锁内一次完成活跃检查、选取与启动；`archive` 持同一把锁移动活跃 Spec，归档完成后再领取下一项。活跃 Spec 优先，否则按一次性人工指定或 T-ID 升序启动。`prefer` 把指定写入 `process/task-pool/NEXT`，仅启动该任务时清除。原话和补充在单个文件；仅记录稳定 Spec ID，进行中/已归档由 Spec 目录派生。owner 接手调用只读 `next`。根目录入口只转发。

- **职责**：`template/scripts/` 实现三道门（g1 计划、g2 验证、g3 审查）、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/process/specs/_templates/` 存项目模板。接力命令 `ai-resume.sh` 只有 `owner [feat]` 与 `review <feat> <base-ref>`。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `process/specs/`、`MEMORY.md`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`ai-verify.sh --spec <feat> <file>` 只运行 `harness/verify.conf` 的 `CUSTOM_CHECK`，不自动探测工具链；`ai-state-id.sh` 全仓计算、只排除 `process/**`。2.0 删除了 `--quick`、worker 角色、手动 `start`、`--force` 与 `.violations`、`metrics` 子命令、优先级字段和旧布局检测：都是少用或可由 AI 直接完成的功能（ADR-0003）。`harness-selftest.sh` 串行覆盖正反例并输出各节耗时。
- **门禁只查骗不过的信号**（ADR-0003）：g1 查原话、「需人决定」以「是 / 否」开头、AC 表无空单元格、待确认清零、方案思路与任务存在；g2 查任务全勾、验证摘要 PASS、checks≥1 且指纹一致；g3 查审查者、未参与实现、关键问题 0、CR 轮次上限、审查状态与验证摘要一致，「需人决定：是」时还要人工决定与来源。不扫描措辞，不检查章节结构。
- **locale 无关**：宿主 shell 可能没有 UTF-8 locale，脚本不强制设置 `LC_ALL`。多字节字符不放进 `[]` 字符类；全角冒号与全角空格在取字段值前归一。自检用显式 `LC_ALL=C` 复跑字段与任务编号用例。
