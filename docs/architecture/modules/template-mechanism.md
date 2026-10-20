# 模板机制

- **职责**：`template/scripts/` 实现 G1~G7、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/docs/specs/_templates/` 存项目模板。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `docs/specs/`、`.knowledge/`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`bash scripts/harness-selftest.sh` 的正反例断言，以及实际目标项目的检查命令。
