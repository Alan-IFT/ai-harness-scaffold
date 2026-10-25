# 交付核验记录 (Acceptance): feat-t-000033

> Agent 执行核验、收集证据并填写本文件；不得把 Agent 运行的命令写成人类执行，也不得推断人读过未确认的材料。
> 象限①由 Agent 根据验证证据收尾；②③由 Agent 向人呈现需要判断的风险、结果和遗留，记录人的明确决定及来源后推进 G6。用户无需编辑 Markdown 或运行冒烟命令。
> ②③每次都需要当次人的结果决定，不使用预先授权。
> 本地门禁只能检查记录完整，不能认证对话中的人；需要强制审批时使用项目自己的权限机制。

- 核验执行者：Agent（Claude Code，Claude Opus 5.5）
- 核验时间：2026-10-25
- 测试环境：本机 Windows 11 + Git Bash，本仓库工作区与临时目录沙箱
- 冒烟或 E2E 证据：通过；Agent 执行 `bash bin/ai-harness retrofit <空临时目录> --dry-run`，退出码 0，目录仍为空（只读）；`tests/cli-upgrade.sh` 在沙箱中实跑 init→构造 1.x 旧布局→upgrade 迁移，输出 `cli-upgrade: PASS`

## 1. 核验摘要
- 对照 AC 的检查结果：通过；AC-01~AC-06 逐项核对均满足通过条件
- AC-01：通过；Agent 执行 `grep -rln 'docs/specs\|docs/metrics\|docs/task-pool' template scripts skill README.md AGENTS.md`，命中仅 `template/.agents/skills/retrofit-legacy.md`（升级说明）、`template/scripts/ai-config.sh`（旧布局守卫）、`template/scripts/harness-selftest.sh`（守卫自检用例），均属 AC-01 允许的迁移相关命中
- AC-02：通过；`wc -l template/scripts/ai-state-id.sh` 为 34（< 145），`grep -c 'manifest\|scope'` 为 0；自检含 `process/note.md` 不变指纹、`process-x/` 与 `processes.md` 改变指纹、`--spec` 与无参数相同的断言，214 项断言 0 失败
- AC-03：通过；`tests/cli-upgrade.sh` 覆盖迁移成功且归档、任务、度量内容哈希不变，活跃 Spec 拒绝且快照不变，已有 `process/` 拒绝且快照不变，`--dry-run` 快照不变，迁移后再次 upgrade「0 个冲突」且不重复迁移；另含 Git 重命名暂存、中断自愈、项目自有 `docs/specs/*.md` 用例，输出 `cli-upgrade: PASS`
- AC-04：通过；自检第 14 节断言旧布局下 `ai-gate.sh status`、`ai-task-pool.sh next` 与 `ai-new-spec.sh` 返回非零且输出含「upgrade」，不创建 `process/`；与 `process/` 并存时提示「并存」
- AC-05：通过；`ls -d` 显示 `process/specs`、`process/task-pool`、`process/metrics.md` 存在，`docs/specs`、`docs/task-pool`、`docs/metrics.md` 均不存在；`ai-gate.sh status feat-t-000033` 与 `ai-task-pool.sh list` 正常输出；`bin/ai-harness` 中 `VERSION="2.0.0"`
- AC-06：通过；自检 214/0，`cli-upgrade: PASS`，`verification.md` 正式验证 PASS（state 与当前代码一致，G4 已过），`review.md` 独立审查关键问题 0（G5 已过）
- 需人判断的风险 / 遗留：
  1. G2 后修改了 AC-01 措辞：原文要求旧路径零命中，与 ERR-02（必须识别旧布局）冲突，改为允许守卫、自检与升级说明中的迁移相关命中。
  2. 2.0.0 为破坏性升级：下游升级时 Spec、任务池、度量整体迁到 `process/`；有在途 Spec 时拒绝，需先归档；不提供反向命令，回滚为 `retrofit-legacy.md` 中的手动步骤。
  3. 下游 `harness/redlines.conf` 的 `ALLOWED_WRITE_DIRS` 不自动改，只输出提示；本仓库根 `harness/redlines.conf` 按需求未改（`git diff` 为空），其 `ALLOWED_WRITE_DIRS` 仍无 `process/`，当前无脚本读取该项。
  4. 审查非阻塞建议 4 条待办：中途落盘失败时提示「重跑 upgrade」；POSIX 下 `mktemp`+`mv` 会把 manifest/ignore 权限变为 0600；requirements ERR-01 补「隐藏临时目录除外」；`ai-config.sh` 与 `bin/ai-harness` 两处旧布局判据加一致性自检。

## 2. 决策与结论
- 验收方式：当次人工决定
- 人工决策人：维护者（维护者）
- 人工决定：通过
- 决策来源：对话 2026-10-25，维护者对 G6 三项风险（AC-01 措辞调整、2.0.0 破坏性迁移、redlines 只提示）选择「通过」
- 结论：通过
- 遗留 / 后续：审查非阻塞建议 4 条（见上）

## 3. 交付与回访（可在发布后补记）
- 交付形态：待发布（2.0.0，本仓库提交后由下游执行 upgrade）
- 发布或交接证据：待发布
- 回滚状态：预案已确认（`git revert`；下游按 `retrofit-legacy.md` 手动回迁）
- 实际结果：待观察首个下游项目执行 2.0 upgrade 的结果
- 后续动作：候选——上述 4 条非阻塞建议，是否入任务池由人决定
