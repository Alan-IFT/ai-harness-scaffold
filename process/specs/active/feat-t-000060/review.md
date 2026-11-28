# 审查：feat-t-000060

- 审查者：Claude Code 只读审查 subagent（独立上下文），模型 Fable 5.2（claude-fable-5-2）
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：5d71952fc7b76922a019389170854336af885029c6ec0a29e2c695b7459c63c1
- 审查范围：fa47d72...HEAD + 工作区

## 结论
- 关键问题：1
- 改进建议：7
- AC-01 到 AC-07 逐条核对都成立（证据见「我试过的场景」）；关键问题是新写法带进来的一处误报，不在验收标准的字面里。

下面是第 1 轮（2026-11-28）审查者报告的原文。

## 关键问题
1. `template/scripts/ai-task-pool.sh:35`：任务池的锁撞上时，有一部分被报成「任务池目录写不进去」。
   - 现象：建锁失败之后、`[ -d "$POOL/.lock" ]` 之前，持锁的进程刚好放了锁，就走到「写不进去」那一支。目录其实一直可写。
   - 证据（Git Bash）：1 个主工作区加 3 个工作区，各连续 `add` 15 次，跑 8 轮。撞锁 165 次，其中 12 次输出「❌ 任务池目录写不进去：<主工作区>/process/task-pool」。每轮成功数都等于任务文件数。
   - 证据（WSL，换成 GNU mkdir）：每个工作区 40 次，跑 6 轮。撞锁 560 次，其中 12 次误报。
   - 为什么算本次引入：`fa47d72` 撞锁时一律报「正被另一进程修改；稍后重试」，这条路径原来没有错。
   - 后果：只错在提示上，不丢数据。但这句提示没有「稍后重试」，并行会话里的 AI 会当成主工作区的任务池不可写，停下问人，或者绕开脚本手写任务文件。
   - 建议：锁不在时再建一次，建成了就继续，仍建不出来才报「写不进去」：
     `mkdir "$POOL/.lock" 2>/dev/null || { [ ! -d "$POOL/.lock" ] || die "…另一进程…"; mkdir "$POOL/.lock" 2>/dev/null || die "任务池目录写不进去：$POOL"; }`
   - 这个写法我在副本里试过：6 轮 130 次撞锁剩 1 次误报，自检仍是「125 项断言，失败 0 项」。要彻底消掉，可以改成在任务池里另建一个唯一名字的目录来判断可不可写。

## 改进建议
1. 自检没有「裸仓库目录就叫 `.git`」的用例，`template/scripts/ai-config.sh:24` 的 `bare` 条件没有断言守着。把 `wt_list` 改成只看第一项里有没有 `.git`，自检仍是 125 项全过。只留 `bare` 条件时失败 2 项（`--separate-git-dir` 那两条）。AC-03 只要求了两种布局，所以不算不符；建议补一条。
2. `template/.agents/skills/parallel.md:21` 和 `docs/architecture/modules/template-mechanism.md:16` 写「归档之后、删工作区之前 `status` 还会把已归档的 Spec 列在那个工作区下」，实测只在同名分支的工作区成立。按 Step 1 第 1、2 条开的工作区（分支名不同于 Spec 名），快进合入或合并提交合入后归档，主工作区的 `status` 不列它。建议加上「同名分支的工作区」这个限定。
3. 判定还漏两种布局，表现和 `fa47d72` 一样（任务文件写到不是工作区的目录），`c35b34c` 下是各管各的：
   - `--separate-git-dir` 指到一个名叫 `.git` 的目录（如 `store/.git`）：清单第一项是 `store`，里面有 `.git`，没有 `bare` 一行。别的工作区里 `add` 输出「已收集 T-000001：<…>/store/process/task-pool/T-000001.md」。
   - `core.worktree` 指到别处：同样写进 Git 目录的上层目录。
   - 都少见，不是本次引入。建议记进活文档「已知而不处理的」，或以后收紧判定。
4. 特殊布局下有几处说明没跟着改，都是无条件的说法：
   - `template/.agents/skills/upgrade.md:5`：「别的工作区共用主工作区的任务池，也不能在里面归档」「先确认它的任务文件在主工作区的任务池里」。本 Spec 明确不改这个文件，建议记进「发现但不碰」。
   - `README.md:73`、`README.md:125`、`README.en.md:67`：「任务池全仓库只有主工作区那一份」。「安全与局限」也没提这几种布局不支持并行。
   - `parallel.md:4` 写了「下面的步骤不适用」，没写这时不该等的需求怎么办（排队还是问人）。
5. `docs/architecture/modules/template-mechanism.md:14` 新加的「同一种 bash 里，活着的锁不会被别人换掉」，和同一条前面的「两个等待者同时清理同一把残留锁时，仍可能让一次验证相撞」对不上。那种情形下后一个等待者删掉的就是前一个刚拿到的活锁（`template/scripts/ai-verify.sh:25`），前一个退出时又会删掉后一个的。建议补上这个例外。
6. 范围外，改动前就有：WSL 的 Ubuntu 默认是 uutils coreutils 0.8.0，它的 `mkdir` 不排他，任务池的锁在那里不成立。
   - 8 个 `mkdir` 同时抢同一个目录名，300 轮里 50 到 78 轮成功了不止一个；同机的 GNU mkdir（`gnumkdir`）是 0 轮。
   - 4 个工作区并发 `add`：HEAD 一轮报成功 75 次，任务池里只有 70 个文件（同号覆盖，任务丢了）；`fa47d72` 是 59 对 57。输出里有「rmdir: failed to remove …/.lock」。
   - Git Bash 下每轮成功数都等于文件数，没有这个问题。建议另起任务：任务池的锁改用 `ai-verify.sh` 那种 `noclobber` 写文件，或在 README「安全与局限」写明。
7. `MEMORY.md` 新加的那条（AC-06）不在维护者点头的 8 条里。`process/specs/archive/2026-11/feat-t-000059/tasks.md` 原来写的是「够不够写进 `MEMORY.md` 请维护者定」，证据只有一次对照（条目里自己写明了）。记忆按规则由 AI 当场记，所以不算越权；交付时要让维护者看到这一条，他不认可就删。

## 我试过的场景
都在系统临时目录的沙箱里，脚本取自 `git archive` 导出的 HEAD、`fa47d72`、`c35b34c`；仓库 `git status` 始终干净。
- AC-01：裸仓库加工作区、裸仓库叫 `.git`、`--separate-git-dir`、子模块四种布局跑 tasks.md 那串命令，HEAD 与 `c35b34c` 逐字相同（各 110 行）；任务文件只在各工作区自己的 `process/task-pool/`，Git 目录里没有 `process`。`fa47d72` 与 `c35b34c` 差 62 到 63 行，任务文件在裸仓库目录或 Git 目录里。
- AC-02：普通布局、三个工作区，同一串命令 HEAD 与 `fa47d72` 逐字相同（155 行）。只有一个工作区的 28 次调用（含真跑 `ai-verify.sh`、过三道门、归档），HEAD、`fa47d72`、`c35b34c` 三者逐字相同（261 行）。
- AC-03：自检在 Git Bash 默认 locale、`LC_ALL=C`、WSL（Ubuntu，git 2.53）下都是「125 项断言，失败 0 项」。配 `fa47d72` 的两个脚本失败 8 项（任务池写不进去 1、裸仓库 5、`--separate-git-dir` 2）。另外两处单独改坏也各拦住 1 项：`status` 先列别的工作区；拒绝归档的提示去掉主工作区目录。
- AC-04：`parallel.md` 23 行，四处 `grep` 各命中 1 处，`template/AGENTS.md` 相对 `fa47d72` 无改动。
- AC-05：活文档和两份 README 的 `grep` 都命中。四种判错状态逐个复现，现象和恢复办法与活文档一致（主工作区切到更早的线、`--amend` 启动 Spec 的提交、压缩合并后主工作区 `status` 里出现 2 次、同名分支改名或游离）。
- AC-06：条目在，有触发条件、证据路径、复核日期；`ai-check-bloat.sh` 通过（`MEMORY.md` 32 行）。
- AC-07：除自检外新增 8 行、删改 4 行，净增 4 行；`harness/`、`template/harness/`、`template/process/`、`upgrade.md`、`skill/` 无改动；脚本清单与 `fa47d72` 相同。
- 当前状态指纹等于 verification.md 的 state。「需人决定：否」按 `new-spec.md` 的判据成立。维护者原话在归档的 `T-000059.md:21` 核对到。diff 和提交信息里没有本机路径和私人邮箱。
- `wt_list` 在各布局下的输出（Git Bash，git 2.56）：
  - 照常输出：普通布局单个或多个工作区、路径带空格和中文（默认 locale 与 `LC_ALL=C`）、还没有提交的新仓库、主工作区游离 HEAD、相对路径的工作区、分支名叫 `bare`、锁原因里带一行 `bare`。
  - 不输出，返回 0：上面四种特殊布局、`.bare` 加 `.git` 文件、裸仓库叫 `.git` 且 `core.bare` 挪进 `config.worktree`、不在 Git 仓库里、主工作区目录被移走或删掉。
  - 四种特殊布局、普通布局和带空格中文的路径在 WSL 里结果相同。
- `set -euo pipefail`：以上布局里 `add`、`intake`、`list`、`next`、`start-next`、`archive` 都没有意外退出；不在 Git 仓库里和新仓库里收录、列表正常。
- 进程替换那一行：30 个工作区、Spec 在第 2 个里，主工作区 `list` 连跑 30 次都显示「进行中」；`archive` 照常报「在别的工作区里」。`bash --posix` 和 `POSIXLY_CORRECT=1` 下进程替换可用，`ai-state-id.sh` 本来就在用。
- 任务池真的只读（WSL 里 `chmod a-w`）：主工作区和别的工作区的 `add`、`start-next` 都报「任务池目录写不进去：<目录>」，`list`、`next` 照常；真有锁时报「另一进程」。
- 归档后、删工作区前的 `status`、并发撞锁、uutils 的 `mkdir`：见关键问题和改进建议 2、6。
- 没试的：验证锁在 WSL 持锁、Git Bash 发起这个方向（活文档里已如实写了没测）；`ai-verify.sh` 本次没有改动。
