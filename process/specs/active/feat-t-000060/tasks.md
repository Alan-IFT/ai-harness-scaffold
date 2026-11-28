# 任务与接力：feat-t-000060

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000060` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：8 条建议逐条定处理办法，能用一句说明解决的不改脚本。
  1. 主工作区不是工作区的布局（建议：裸仓库布局）。`template/scripts/ai-config.sh` 加一个 `wt_list`，输出 Git 的工作区清单；清单里有 `bare` 一行，或第一项的目录里没有 `.git`，就什么都不输出。`worktrees` 和 `branch_wt` 改成从它读。这样认主工作区、归属的两条判据、任务池放哪、跨工作区的状态显示、归档限制会一起关掉，脚本表现得和只有一个工作区时一样。
     - 为什么要两个条件（2026-11-28 实测，Git 2.56）：

       | 布局 | 清单第一项 | 第一项里有 `.git` | 有 `bare` 一行 |
       | :-- | :-- | :-- | :-- |
       | 普通 | 主工作区 | 有 | 没有 |
       | 裸仓库加工作区 | 裸仓库目录 | 没有 | 有 |
       | 裸仓库放在 `.bare`，再用 `.git` 文件指过去 | `.bare` 目录 | 没有 | 有 |
       | 裸仓库目录就叫 `.git` | 它的上层目录 | 有（就是那个裸仓库） | 有 |
       | `--separate-git-dir` | Git 目录 | 没有 | 没有 |
       | 项目是子模块 | 上层仓库的 `.git/modules/<名字>` | 没有 | 没有 |

     - 现在的脚本在后五种布局下的表现（同一天实测）：别的工作区里收录的任务文件写进了清单第一项那个目录（裸仓库目录、Git 目录），不在任何工作区里。
     - 为什么是「不认」而不是「把检出主线的那个工作区当主工作区」：维护者定的是退回原来的行为；这些布局里没有哪个工作区天然是主的，要支持就得另定规则。
     - 为什么关在清单这一层：只在 `main_wt` 里判，`branch_wt` 那条判据和跨工作区的状态显示还开着，同一个 Spec 会在几个工作区里各列一次。
  2. 归属的前提（建议：归属前提没写）。写进 `parallel.md` 的「原则」和活文档。前提三条：主工作区留在主线上；线分出去以后不改写主线上已有的提交；挪出去做的工作区留在同名分支上。判错的四种状态和怎么恢复，2026-11-28 用原型脚本在临时沙箱里各试了一遍，结果在 WIP 区。
  3. 验证锁（建议：锁跨 bash 不成立、退出时不核对主人）。只写说明：`README.md` 脚本表和「安全与局限」、`README.en.md`、活文档。退出时不核对锁的主人，理由在 requirements.md「不做」。活文档同一条里补上审查时定下的行为：拿不到锁时不加锁、照常验证，也不提示。
  4. `git branch -d`（第 1 轮建议 1）。`parallel.md` 第 3 步第 5 条改成：没合入的分支用 `-D`。
  5. `elsewhere`（第 1 轮建议 3）。`template/scripts/ai-task-pool.sh` 里改成从进程替换里读，不经管道，行数不变。审查者在 150 个工作区下没复现出误判；改它不花行数，顺手去掉「读的一端提前退出、写的一端被信号打断、`pipefail` 把整条算成失败」这种可能。
  6. 任务池写不进去（建议：提示与原因不符）。`lock_pool` 里建锁失败时先看锁在不在：不在就报「任务池目录写不进去」，在才报「正被另一进程修改」。同一行里改。
  7. 归档后、删工作区前的显示（建议：`status` 仍列出已归档的 Spec）。`parallel.md` 第 3 步第 5 条加半句；活文档记成已知。
  8. 自检缺的断言（建议 7 剩下的）。`status` 的先后顺序、拒绝归档提示里的主工作区目录、「合入后归主工作区」那条的后半句换成会失败的；另加这次改动的用例（见 AC-03）。
  - 另记一条经验进 `MEMORY.md`（AC-06）。feat-t-000059 的 tasks.md 里写的是「够不够写进去请维护者定」，那是当时不想回退验证门；按规则这类经验由 AI 当场记，这里补上，交付时告诉维护者，他不认可就删。
- AC-01、AC-02 用的那串命令（对照脚本在系统临时目录里，重启可能被清掉，所以列在这里）。主线所在的工作区记作「主」，后开的记作「另」和「同名」：
  1. 主：`ai-task-pool.sh intake "主线上的需求"`，提交；然后从主线开工作区「另」（分支 `lane`，带着主线 Spec 的副本）
  2. 另：`ai-task-pool.sh intake "另一条线上的需求"`
  3. 另、主：`ai-task-pool.sh list`
  4. 另、主：`ai-task-pool.sh next`
  5. 另、主：`ai-gate.sh status`
  6. 另：`ai-resume.sh owner`
  7. 另：`ai-task-pool.sh archive feat-t-000001`
  8. 另：`ai-task-pool.sh add "第三条"`；然后从主线开工作区「同名」（分支 `feat-t-000001`）
  9. 同名、主：`ai-task-pool.sh next`
  10. 主：`ai-gate.sh status`
  11. 列出所有任务文件的位置
  - 输出里的沙箱路径、提交哈希先换成占位符再比。
- 改动文件：`template/scripts/ai-config.sh`、`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`、`template/.agents/skills/parallel.md`、`docs/architecture/modules/template-mechanism.md`、`README.md`、`README.en.md`、`MEMORY.md`。
- 影响与风险：
  - 调用方（`grep -n 'worktrees\b\|branch_wt\|main_wt\|own_specs\|git worktree' template/scripts/*.sh`）：`git worktree list` 只在 `ai-config.sh` 里调用两处；`worktrees` 的调用方是 `main_wt`、`ai-task-pool.sh` 的 `elsewhere`、`ai-gate.sh` 的 `cmd_status`；`branch_wt` 只有 `own_specs` 调。都经过 `wt_list`，所以一处判定管住全部。
  - `ai-task-pool.sh` 开着 `set -euo pipefail`：`wt_list` 任何情况下都返回 0，否则 `MAIN=$(main_wt)` 那一行会让脚本直接退出。原型里四种布局、不在 Git 仓库里都跑过，没有退出。
  - 普通布局：只有一个工作区、有多个工作区两种情形，原型的输出都与改动前逐字相同（AC-02 的两份对照，原型阶段已跑过一遍，实现后重跑）。
  - 性能：`wt_list` 用变量展开取第一行，不多起进程。
  - 验证锁不受影响：它用的是 Git 的公共目录，这些布局下几个工作区仍共用一把锁。
  - 不兼容的地方：上一版（feat-t-000059，还没推送、没发版）在这些布局下会把任务文件写进 Git 目录；没有项目用过那一版，所以不写迁移。
  - `parallel.md` 和 README 改了说明：按本仓库 `AGENTS.md` 同步检查 `skill/SKILL.md` 和自检里对这些文件的断言；`upgrade.md` 不改，所以不用重做升级演练。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：脚本两处（清单那一层不认特殊布局；任务池的报错和 `elsewhere`）
  - 对应验收：AC-01、AC-02、AC-07
  - 涉及文件：`template/scripts/ai-config.sh`、`template/scripts/ai-task-pool.sh`
  - 验证：`bash -n`；四种特殊布局加普通布局的对照；28 次调用的对照；现有自检全过；净增行数
- [x] Task 2：自检补用例
  - 对应验收：AC-03
  - 涉及文件：`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh` 和 `LC_ALL=C` 复跑都是 0 失败；同一份自检配 `fa47d72` 的脚本跑，记下失败的断言
- [x] Task 3：指南、活文档、README
  - 对应验收：AC-04、AC-05
  - 涉及文件：`template/.agents/skills/parallel.md`、`docs/architecture/modules/template-mechanism.md`、`README.md`、`README.en.md`
  - 验证：两张验收表里的 `wc -l` 和 `grep`；`skill/SKILL.md` 核对有没有要跟着改的句子；自检仍全过
- [x] Task 4：记忆和整体验收
  - 对应验收：AC-06、AC-07
  - 涉及文件：`MEMORY.md`
  - 验证：`grep`、`bash scripts/ai-check-bloat.sh`、AC-07 的三条命令

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `process/specs/archive/2026-11/feat-t-000058/review.md` 第 2 轮的两条建议（活文档 `docs/architecture/modules/guidance.md` 里「范围内的点」写成「它们认为在范围内的点」更准；关系到人要定的取舍的建议，当场改算不算 `MEMORY.md` 第 1 条的例外）/ 维护者 2026-11-28 定 058 时没有问到这两条 / 候选，告诉维护者，他确认了再收录

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：四个任务都做完并提交了；还没做正式验证和独立审查（2026-11-28 会话的用量额度用完，停在这里）。
- 已完成：收录（T-000060，2026-11-28）；requirements.md 和本方案；g1。
- 已完成：Task 1 到 Task 4（2026-11-28，代码和说明已提交，起点是 `fa47d72`）。
  - AC-01：四种特殊布局下，实现后的脚本与 `c35b34c` 的输出逐字相同（各 109 行）；任务文件只在各工作区自己的 `process/task-pool/` 里。改动前的脚本（`fa47d72`）在这四种布局下差 61 到 62 行。
  - AC-02：普通布局、有多个工作区，实现后与 `fa47d72` 逐字相同（154 行）；只有一个工作区的 28 次调用与 `c35b34c` 逐字相同。此前的并行场景 54 项、归属边角 23 项、锁与状态 19 项、边角 14 项实验都仍然通过。
  - AC-03：自检打印「125 项断言，失败 0 项」，`LC_ALL=C` 相同（改动前 116 项）。新自检配 `fa47d72` 的 `ai-config.sh` 和 `ai-task-pool.sh` 跑，失败 8 项：任务池写不进去 1 项、裸仓库布局 5 项、`--separate-git-dir` 2 项。另把「带过来的副本不算自己的」那条判据在副本里关掉再跑，改写过的「合入主线后归主工作区」那条会失败（共失败 17 项）。
  - AC-04：`parallel.md` 仍是 23 行，四处 `grep` 各命中 1 处；`template/AGENTS.md` 没动。新加的几句没有用真的 AI 会话对照过，效果是推断。
  - AC-05：活文档和两份 README 的 `grep` 都命中。活文档里四种判错状态与上面「原型和实测」一致；「分支名改回去后恢复」另外实测过。验证锁在 Git Bash 和 WSL 之间只有审查测过的那个方向（Git Bash 持锁、WSL 发起），反方向没测，活文档里照实写了。
  - AC-06：`MEMORY.md` 加了一条，体积检查通过。
  - AC-07：脚本除自检外新增 8 行、删改 4 行，净增 4 行（相对 `c35b34c` 累计 58 行）；`harness/`、`template/harness/`、`template/process/`、`upgrade.md`、`skill/` 没有改动；脚本清单没变。`skill/SKILL.md` 核对过，没有要跟着改的句子。
- 原型和实测（2026-11-28，都在系统临时目录里，重启可能被清掉；逻辑以上面的方案为准）：
  - 六种布局下 Git 的工作区清单长什么样：见方案里的表。
  - 四种特殊布局各跑一遍上面那串命令，三套脚本对照。原型的输出与 `c35b34c` 的逐字相同（各 109 行）。现在的脚本（`fa47d72`）与 `c35b34c` 差 61 到 62 行，任务文件的位置分别是：裸仓库目录下的 `process/task-pool/`；裸仓库叫 `.git` 时是它的上层目录；`--separate-git-dir` 时是那个 Git 目录；子模块时是上层仓库的 `.git/modules/<名字>/`。
  - 普通布局、有多个工作区：原型的输出与 `fa47d72` 的逐字相同（154 行）。
  - 归属判错的四种状态（原型脚本，普通布局）：
    - 主工作区切到更早的一条线：另一个工作区把带过来的副本也算成自己的，`next` 指向主线的 Spec；主工作区切回主线就恢复。
    - 主工作区改写了启动 Spec 的那次提交（`git commit --amend`）：同上；另一个工作区同步一次主线后恢复。
    - 压缩合并进主线：主工作区和原工作区都认这个 Spec，主工作区的 `status` 里它出现 2 次；删掉原工作区后恢复成 1 次。
    - 挪到同名分支的工作区后，那个分支改了名或变成游离 HEAD：Spec 回到主工作区，那个工作区自己的变成空的；分支名改回去就恢复。
- 已排除的方案：只在 `main_wt` 里判特殊布局（另两处判据和跨工作区显示还开着，会重复列出）；只看有没有 `bare` 一行（漏掉 `--separate-git-dir` 和子模块）；只看第一项里有没有 `.git`（裸仓库目录叫 `.git` 时会误判成有）；退出时核对锁的主人、`status` 跳过已归档的 Spec（理由在 requirements.md「不做」）。
- 下一步：`bash scripts/ai-verify.sh --spec feat-t-000060` 过 g2 并提交；起独立审查（按 `MEMORY.md` 新加的那条，指定当前最强的模型，只读，基准提交 `fa47d72`）；「需人决定：否」，关键问题清零后过 g3、归档。交付时告诉维护者三件事：`MEMORY.md` 那条经验是 AI 自己补记的，不认可就删；058 留下的两条候选建议（见「发现但不碰」）；本地主线没有推送，推送要他点头，不打 tag。
