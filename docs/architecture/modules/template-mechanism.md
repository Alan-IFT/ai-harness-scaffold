# 模板机制

- **职责**：`template/scripts/` 实现 G1~G7、Spec 新建、验证、接力与体积体检；`template/harness/` 存可移植配置，`template/docs/specs/_templates/` 存项目模板。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本通常以目标项目根目录为工作目录运行。
- **状态**：项目自己的 `docs/specs/`、`.knowledge/`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`bash scripts/harness-selftest.sh` 的正反例断言，以及实际目标项目的检查命令。
