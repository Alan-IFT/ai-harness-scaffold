# 交付核验记录 (Acceptance): feat-t-000032

> Agent 执行核验、收集证据并填写本文件；不得把 Agent 运行的命令写成人类执行，也不得推断人读过未确认的材料。
> 象限①由 Agent 根据验证证据收尾；②③由 Agent 向人呈现需要判断的风险、结果和遗留，记录人的明确决定及来源后推进 G6。用户无需编辑 Markdown 或运行冒烟命令。
> ②③每次都需要当次人的结果决定，不使用预先授权。
> 本地门禁只能检查记录完整，不能认证对话中的人；需要强制审批时使用项目自己的权限机制。

- 核验执行者：Claude Code（Opus 5.5，Git Bash；命令输出与 Spec 摘要）
- 核验时间：2026-10-24
- 测试环境：本仓库 Windows 工作区 `<本仓库>`，环境变量中无 LANG / LC_*
- 冒烟或 E2E 证据：通过；`ai-verify.sh --spec feat-t-000032 template/scripts/ai-gate.sh` PASS，耗时 403 秒（模板自检 264 秒、215 项、失败 0 项；CLI 回归 138 秒 PASS）；`retrofit --dry-run` 冒烟只读；G5 审查者独立复跑自检与 CLI 回归均通过。

## 1. 核验摘要
- 对照 AC 的检查结果：通过；AC-01~AC-06 逐项核对如下，AC-05 中的耗时按约定只记录，不作判据。
- AC-01：通过；`grep -rn 'G6_SCAN_AWK\|FEASIBILITY_MIN\|delegation_fields\|ai-knowledge\|KNOWLEDGE_TTL_DAYS\|--by human' template bin scripts README.md skill tests` 无输出。
- AC-02：通过；自检 `harness-selftest.sh:265`（含「尽量」的 AC 通过 G2，LC_ALL=C）；`:404-428` 共 11 个样本在两种 locale 下 22 次判断符合期望：「通过；…失败 0 项」放行，「通过率」「不通过」等拒绝。
- AC-03：通过；保留项断言仍在（四项必答、象限、追溯、审查状态绑定、CR 轮次、红线漂移、连续失败计数、任务池），自检 215 项全绿。
- AC-04：通过；`tests/cli-upgrade.sh` 覆盖以下情形：未改动的删除；改动过的保留、非零退出且二次不再报告；`--accept-custom` 定制的保留；dry-run 前后快照一致；manifest 缺失不删除；伪造非托管路径不删除。
- AC-05：通过；`ai-gate.sh` 821→636 行，`harness-selftest.sh` 1161→917 行。正式验证耗时 403 秒，比 R1 前的 363 秒多 40 秒：模板自检由 301 秒降到 264 秒，CLI 回归因新增 6 个升级场景由约 62 秒增到 138 秒。
- AC-06：通过；`template/AGENTS.md`、各 skill、README、模块活文档已不描述已删除的机制；`code-review.md` 第 1 维新增「AC 措辞」「验收证据与结论」两项检查。
- 需人判断的风险 / 遗留：
  - ① 正式验证总耗时没有下降（403 秒，超过 120 秒提醒线）：自检变快了，但 CLI 回归新增了用例。R2（T-000033）删除局部指纹模式后，自检会再缩小。
  - ② 下游门禁放宽：AC 含糊词、验收证据与结论矛盾不再由机器拦截，改由 G5 清单与人工把关。
  - ③ 下游升级须先归档在途 Spec，或按新格式重写其 acceptance.md。本地改过的旧知识卡脚本或指南会被保留并报告。
  - ④ 根目录 `harness/redlines.conf` 中的 `FEASIBILITY_MIN`、`KNOWLEDGE_TTL_DAYS` 已无脚本读取，这个文件只允许你修改，请择机删除后在交互终端运行 `bash scripts/ai-gate.sh baseline`。
  - ⑤ 本次不发布：按 ADR-0002，R2 完成后统一升级版本并发布。

## 2. 决策与结论
- 验收方式：当次人工决定
- 人工决策人：本会话维护者
- 人工决定：通过
- 决策来源：2026-10-24 对「G6：接受 T-000032（R1 删除）并归档，随后放行并启动 T-000033 吗？」选择「接受并归档，启动 R2」
- 结论：通过
- 遗留 / 后续：见上方风险 ①~⑤

## 3. 交付与回访（可在发布后补记）
- 交付形态：待发布（R2 后统一发布）
- 发布或交接证据：本仓库 refactor(harness) 提交 894c5f9
- 回滚状态：预案已确认（git revert；下游重新 upgrade 恢复模板文件）
- 实际结果：待观察——下游升级后 Agent 是否不再被措辞误拦
- 后续动作：归档后把 T-000033（R2）改为待办并 prefer
