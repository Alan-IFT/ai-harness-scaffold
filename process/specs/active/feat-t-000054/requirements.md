# 需求：feat-t-000054

- 创建时间：2026-11-13
- **需求来源**: `process/task-pool/T-000054.md`（原始需求与更新）
- 原始问题 / 原话：「做」（维护者 2026-11-13 对 AI 的候选处理建议的答复；此前的提问是「你推荐怎么做？什么时候做？」。建议的内容见任务文件，其中归本 Spec 的是：补升级说明第 4 步的两处含糊，并把 `install-skill.md` 里演练依据的证据强度写准）
- 需人决定：否。只给升级说明的两句各补半句，写的是已有步骤里原本就要做的判断，不改步骤、不改脚本、不涉及数据、权限和不可逆操作；不发版、不打 tag。维护者已在答复前看过这两处的依据和局限。

## 1. 要做什么
- 做什么：`template/.agents/skills/upgrade.md` 第 4 步补两处：与基线比对时只差换行符的算没改过；「已退役文件」指模板历史里出现过、目标版本的 `template/` 里已经没有、项目里还在的文件。`docs/architecture/modules/install-skill.md` 里「为什么改升级说明也要演练」那条补半句：那 5 处含糊 subagent 都靠推断补上了，没有因此做错的记录。
- 为谁做：照升级说明做升级的项目 AI，不用再自己推断这两处；本仓库的维护者，这两处不用再一次次记进「发现但不碰」。
- 不做：
  - 不改升级步骤的顺序和其他句子，不加文件、脚本、配置键，脚本一行不改。
  - 不改根 `AGENTS.md` 的「接入或升级一次」（没有人读错过）。
  - 不声称这两处补上后能减少升级出错：此前两次演练里 subagent 都推对了。新旧文字各演练一次，结论按 AC-04 的写法如实记录。
  - 不打 tag、不发版，不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 升级说明第 4 步写明：只差换行符的算没改过；已退役文件的判据 | `grep -c '只差换行符的算没改过' template/.agents/skills/upgrade.md` 输出 1；`grep -c '已退役文件（历史里出现过、目标版本的 .template/. 里已经没有、项目里还在的）' template/.agents/skills/upgrade.md` 输出 1；`git diff --stat 15f3dff -- template/.agents/skills/upgrade.md` 为 2 行新增、2 行删除；文件仍是 15 行 |
| AC-02 | 活文档写准演练依据的证据强度 | `grep -c '才显出来的（它们靠推断补上了，没有因此做错的记录）' docs/architecture/modules/install-skill.md` 输出 1 |
| AC-03 | 按本仓库的约定演练：没参与改动的上下文照新版升级说明，在系统临时目录把一个装着 v2.1.4 的项目升级到含本次改动的提交，自检通过 | 演练项目里 `bash scripts/harness-selftest.sh` 末尾为「失败 0 项」；`.ai-harness/version` 是目标提交；我复核 `AGENTS.md`、`CLAUDE.md`、`.ai-harness/LICENSE.md`、`scripts/*.sh`、`.agents/skills/*.md`、`process/specs/_templates/*.md` 与 `git show <目标提交>:template/<文件>` 逐个 `cmp` 一致；演练前后本仓库 `git status --short` 不变 |
| AC-04 | 新旧文字各演练一次并如实下结论。两个演练项目内容相同，都预先放好：两个只把换行改成 CRLF、内容没改的机制文件（一个在基线与目标之间有变化，一个没有）；两个已退役文件；一个模板历史里从没有过的项目自有文件。旧文字的目标是基准提交 `15f3dff`，新文字的目标是含本次改动的提交 | tasks.md 的 WIP 区记下两次演练各自：两个 CRLF 文件判成改过还是没改过；交人决定的已退役清单；报告里列为「说明没写清」的地方。结论写法：旧文字下做错（把 CRLF 文件判成改过，或已退役清单多列、漏列、自行删除）或把这两处报为没写清，而新文字下没有，才记「有增量」；否则记「无增量证据」。新文字下做错的，停下改措辞重演练。结论写进给维护者的汇报 |
| AC-05 | 不新增文件，脚本不变；自检失败 0 项，体积检查通过，正式验证通过 | `git diff --name-status 15f3dff -- . ':(exclude)process'` 只有 2 行且都以 `M` 开头（`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`）；`git ls-files --others --exclude-standard -- . ':(exclude)process'` 无输出；`git diff --stat 15f3dff -- template/scripts scripts` 无输出；`bash scripts/harness-selftest.sh` 末尾为「失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000054` 为 PASS |
