# 交付核验记录 (Acceptance): feat-self-hosting

> 本记录由 Codex Agent 根据实际命令、仓库产物与 维护者 的对话决定整理。维护者 未声称亲自运行命令或逐篇阅读所有材料；下列机械检查均由 Agent 执行。

- 核验执行者：Codex Agent
- 核验时间：2026-10-20
- 测试环境：Windows，本地 Git Bash UCRT64，`<本仓库>`，`main`
- 冒烟或 E2E 证据：Agent 运行 `bash scripts/ai-verify.sh --spec feat-self-hosting template/scripts/ai-new-spec.sh` → PASS / checks 1；其日志中 `harness-selftest.sh` 91/91 项断言通过，`git diff --check` 通过。摘要见 `verification.md`，详细日志见本机 `reports/verify-20261020-080447-37573.log`。

## 1. 核验摘要
- 对照 AC 的检查结果：AC-01~05 按现存证据逐项通过；AC-01 的原始 dirty 状态证据限制单列如下。
- AC-01：通过（可核实范围）；`main` 和原 HEAD `1a1027a8de2000c949a1a5e095fc88833840059d` 保留在历史中，未重新 `git init`，既有 retrofit CLI 改动已单独提交。接入前未保存逐文件 `git status` 快照，不能事后逐项证明所有旧未提交内容均未丢。
- AC-02：通过；根目录 8 个 `scripts/*.sh` 只转发同名 `template/scripts/*.sh`，`ai-new-spec.sh` 仅额外指定模板目录。
- AC-03：通过；根目录 Spec 新建、门禁状态、接力与自检命令已实际运行；增量验证 PASS / checks 1。
- AC-04：通过；根目录 `AGENTS.md`、本 Spec 的 `tasks.md`、`verification.md` 与 Git 保存接力状态，`CLAUDE.md` 仅导入规则入口。
- AC-05：通过；Agent 实际运行核验并写本记录；维护者 只承担关键风险与结果决定，无亲测或逐篇已读声明。
- 需人判断的风险 / 遗留：AC-01 缺接入前逐文件状态快照，完整原始 dirty 状态无法独立证明；维护者 已明确接受该证据限制。

## 2. 决策与结论
- 人工决策人：维护者
- 人工决定：通过
- 决策来源：维护者 于本会话先表示「我已经审查完毕了，没问题」，后对 AC-01 证据限制的定向询问明确回复「接受，两个 Spec 通过」。
- 结论：通过
- 遗留 / 后续：未来老项目接入前保存 branch、HEAD 与 dirty 文件清单；本次不补造历史快照。

## 3. 交付与回访
- 交付形态：已在本仓库提交并归档；无线上部署。
- 发布或交接证据：Git 提交 `bd33366`；归档路径 `docs/specs/archive/2026-10/feat-self-hosting/`。
- 回滚状态：可通过 Git 撤销本轮变更，原有历史已保留。
- 实际结果：本仓库自用入口可运行；长期接力效果待观察。
- 后续动作：单一事实来源改造在当前两个 Spec 完成后启动。
