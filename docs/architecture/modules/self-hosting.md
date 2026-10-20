# 本仓库自用状态

- **职责**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/`、`harness/` 与 `.knowledge/` 记录这个源码仓库的开发状态。
- **需求与度量**：`docs/INTAKE.md` 保留原始问题及处理决定；`docs/metrics.md` 只记录本项目交付事实。
- **边界**：根目录 `scripts/` 是薄转发入口；脚手架机制仍只在 `template/scripts/` 维护。根目录 `harness/redlines.conf` 是本仓库自己的阈值事实，不与分发样本强制同步。当前工作区已有 Git 仓库，不能重新创建历史或覆盖未提交改动。
- **验证**：本仓库 `harness/verify.conf` 使用模板自检和 `git diff --check`；Agent 执行 G6 核验，象限②③的风险与结果由人决定。
