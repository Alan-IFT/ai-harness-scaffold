# 模板机制

- **职责**：`template/scripts/` 实现 G1~G7、Spec 新建、验证、接力与体积体检；`template/scripts/ai-config.sh` 统一读取并校验当前项目 `harness/redlines.conf` 的必要键。`template/harness/` 是新项目配置样本，`template/docs/specs/_templates/` 存项目模板。
- **边界**：根目录 `scripts/` 只转发，不复制机制；模板脚本以当前项目根目录为工作目录运行。阈值数值只在该项目 `harness/redlines.conf` 生效；配置缺失或无效时明确失败。
- **状态**：项目自己的 `docs/specs/`、`.knowledge/`、`harness/redlines.conf` 留在项目内并进入 Git，详细验证日志除外。
- **验证**：`ai-verify.sh --quick` 仅执行项目 `QUICK_CHECK`，不写 G4 摘要；正式调用仍运行配置的完整检查并写摘要。`ai-state-id.sh --spec` 在 design §4 显式确认验证依赖清单后，才从精确路径构建指纹；多路径条目、无可靠清单或有未归属改动时回退全仓。`harness-selftest.sh` 覆盖正反例，CI 另跑项目回归。
- **追溯与统计**：新 Spec 用追溯版本标记启用 G3 的 REQ/ERR/AC 覆盖矩阵检查与 G4 的任务设计章节检查；旧 Spec 保持原门禁。`ai-knowledge.sh usage` 只读扫描通过 G4 的 active/archive Spec 注入知识行，按 Spec 去重派生采用数。
