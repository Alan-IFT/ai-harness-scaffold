# 本仓库自用

- **范围**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/`、`process/`、`harness/`、`scripts/`（转发）、`tests/`。
- **为什么自用**：脚手架用自己的流程开发，问题最先在这里暴露。
- **验证**：`harness/verify.conf` 调用 `tests/verify-repo.sh`，先做双区 `git diff --check`，再跑模板自检。
- **红线**：根目录 `harness/redlines.conf` 只属于本仓库，不与模板样本强制同步。
