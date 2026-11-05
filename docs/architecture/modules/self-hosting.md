# 本仓库自用

- **范围**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/`、`process/`、`harness/`、`scripts/`（转发）。
- **为什么自用**：脚手架用自己的流程开发，问题最先在这里暴露。
- **验证**：`harness/verify.conf` 一行命令：先做双区 `git diff --check`，再跑模板自检。
- **红线**：根目录 `harness/redlines.conf` 只属于本仓库，不与模板样本强制同步。
- **为什么删掉旧归档**：G1~G7 时期的 199 个归档 Spec 与 32 个已完成任务描述的是已删除的机制，结论已写进 ADR-0003，原文在 Git 历史里（2026-10-25 删除）。新任务编号从现存最大编号继续。
- **为什么 `process/` 里有查不到的提交号**：2026-11-05 公开时为清除隐私信息重写过 Git 历史，所有提交号都变了。现行文档已更新，`process/` 归档保留原样，其中早于这次重写的提交号已失效。
- **CI**：`.github/workflows/selftest.yml` 在 `windows-latest` 上跑模板自检，与支持的平台一致。
