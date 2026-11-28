# 任务与接力：feat-t-000059

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000059` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：不加「并行」这个新功能，只把「同一时间只做一个 Spec」这条规矩的范围，从整个仓库改成一个工作区。六轮讨论里试过并放弃的做法（脚本零改动、只靠分支名约定、脚本代建工作区、改 g3 判定）和各自的实测，见任务文件「需求讨论」。实现以第六轮的原型为底（原型只在临时目录里，不在仓库里），逻辑如下：
  1. **认主工作区**。`ai-config.sh` 加三个小函数。`worktrees` 列出本仓库所有工作区的目录（`git worktree list --porcelain`，第一项是主工作区）。`main_wt` 在别的工作区里输出主工作区的目录，在主工作区或不在 Git 仓库里时没有输出；判据是 `git rev-parse --git-dir` 与 `--git-common-dir` 是否相同，两边都由 Git 给出，不拿路径字符串比较。`own_specs` 列出当前工作区自己的活跃 Spec 目录。
  2. **`own_specs` 的三条判据**，按顺序：
     - Spec 名等于当前分支名：是自己的（把已经启动的 Spec 挪到同名分支的工作区去做，维护者 2026-11-27 定的）。
     - 本仓库有工作区检出了和 Spec 同名的分支（那就不是当前这个）：不是自己的。
     - 当前在别的工作区，而它和主工作区的分叉点提交里已经有这个 Spec 目录（`git merge-base` 加 `git cat-file -e`）：是从主线带过来的副本，不是自己的。
     - 其余都是自己的。只有一个工作区时三条都不成立，结果和现在的 `process/specs/active/*/` 一样。
  3. **任务池全仓库一份**。`ai-task-pool.sh` 加载 `ai-config.sh`，在别的工作区里把 `POOL` 指到主工作区的 `process/task-pool`，编号扫描的归档和活跃目录也看主工作区的。锁、编号、认领因此只有一处。`start-next` 写进 requirements.md 的「需求来源」固定用仓库内的相对路径。`next` 和 `start-next` 的排队保护改用 `own_specs`。`list` 的「进行中」改成「任何一个工作区里有这个 Spec 目录」。
  4. **`status` 和接手快照**。`ai-gate.sh status` 不带参数时先列 `own_specs`，再逐个进别的工作区列它们各自的 `own_specs`，前面加一行写明目录。`ai-resume.sh owner` 的「活跃 Spec 与断点」改用 `own_specs`；在别的工作区里，开头加一行写明主工作区在哪、任务池和被忽略的本地文件在那里。
  5. **归档只在主工作区做**。`archive` 在别的工作区里直接拒绝并给出主工作区目录。在主工作区里，Spec 目录不在本地而在别的工作区时，提示先把它的分支合进来。归档原有的 g3 复核不动，它在主线的实际状态上判，是合入之后的最后一道检查。
  6. **正式验证的锁**。`ai-verify.sh` 在仓库有多个工作区时，跑检查前先拿 `<公共 Git 目录>/ai-verify.lock`（用 `noclobber` 写入自己的进程号）；拿不到就等，提示一次；锁里记的进程已经不存在就删掉重拿；退出时删锁。只有一个工作区时这段不执行。等锁不算验证失败。
  7. **`status` 不说假话**。`render_spec` 在三道门都有记录、且 Spec 在 `active/` 下时，再跑一次 g3 的校验；不通过就显示原因，不显示「可归档」。
  8. **指南和入口**。新增 `template/.agents/skills/parallel.md`，以任务文件里实测用的第三稿为底，按第 4 条判据补一句「把已经启动的 Spec 挪出去做时，分支起成 Spec 名」。`template/AGENTS.md` 改两处指向它。
- 改动文件：`template/scripts/ai-config.sh`、`template/scripts/ai-task-pool.sh`、`template/scripts/ai-gate.sh`、`template/scripts/ai-resume.sh`、`template/scripts/ai-verify.sh`、`template/scripts/harness-selftest.sh`、`template/.agents/skills/parallel.md`（新增）、`template/AGENTS.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`template/.agents/skills/upgrade.md`。
- 影响与风险：
  - **行为变化**：凡是 `git worktree` 建出来的工作区，都共用主工作区的任务池，也不能在里面归档。维护者已接受（Q1）。本机三个接入项目只读核对过，没有会被它伤到的用法；其中一个项目在途的同名分支线由判据第一条覆盖（Q2、Q3）。写进升级说明。
  - **加载顺序**：`ai-task-pool.sh` 是 `set -euo pipefail`，新加载的函数在不是 Git 仓库、没有提交、没有共同祖先时都不能让脚本退出；管道里不用会提前关掉输入的 `head`。已有调用关系不变：`ai-resume.sh` 调 `ai-gate.sh status` 和 `ai-task-pool.sh next`，本仓库根目录的 `scripts/` 只转发。
  - **Git Bash**：路径带空格；`kill -0` 探测别的 bash 进程和被强杀的进程（2026-11-27 在本机实测可行）；`git worktree list` 给的是 `D:/…` 形式的路径，只和 Git 自己给的路径比较。
  - **已知而不处理的**（都写进活文档或升级说明）：主工作区有没提交的代码改动时合入，会出现「快进成功、归档被拒」；别的工作区里收录、领取留下的任务池改动在主工作区，等那里提交；用 `git rebase` 同步的那段时间里，主工作区对那条线的显示会暂时不对（指南用 merge）；验证锁只管 `ai-verify.sh`。
  - **自己用自己**：这个 Spec 就在另一个工作区里做，而本仓库的 `scripts/` 转发到正在改的 `template/scripts/`。脚本改到一半时，不在这个工作区里运行会写任务池的命令；先在临时沙箱里跑通自检。
  - **和 `feat-t-000058` 的先后**：它在主工作区已过验证、等维护者的 g3 决定。本 Spec 合入会让它的验证和审查过期。本 Spec「需人决定：是」，本来就要停在 g3 等维护者，先后届时由维护者定。
- 真的 AI 会话怎么判（AC-10；写在这里，跑之前不改）。沙箱用本 Spec 最终的 `template/` 生成，是一个 Node 小服务：检查要读不入库的 `.env`，并把服务起在固定端口上跑几秒；每个沙箱用不同的端口。会话是宿主起的 subagent，模型指定 Sonnet 5.5，提示里只给项目目录、维护者的一句原话和「接下来没人在线」；判定只看落盘状态和提交记录，不看自述。四种情形各跑一次：
  - S1 两个互不知情的会话同时各接一个需求（改的文件不相交）。通过条件：两条任务的编号不同；两个 Spec 都归档在主工作区；主工作区里检查命令通过；主工作区此刻的状态指纹等于最后归档那个 Spec 的 `verification.md` 里的 state；没有残留的活跃 Spec。
  - S2 一个会话同时接两个互不相干的需求，原话要求同时做。通过条件：两个需求各有自己的 Spec，至少一个是在别的工作区里做的；两个 Spec 都归档，或者没归档的那个三道门记录齐全、停在合入之前，且会话的报告指出了要人定的具体的点；主工作区里检查命令通过。
  - S3 会话断了之后接手：别的工作区里有一条过了 g1、代码已提交的线，任务池里还排着一条。通过条件：那条线合入并归档；排着的那条归档，或停在规则写明要人定的点上；主工作区里检查命令通过；没有残留的活跃 Spec。
  - S4 主工作区在途的 Spec 已过验证在等人，原话要求新需求别等它。通过条件：新需求在别的工作区里做完并归档在主工作区，或只因为它自己判成「需人决定：是」而停在 g3；主工作区那个在途 Spec 的目录和它的代码文件相对开始时没有改动；会话的报告说明了那个 Spec 的验证因此过期。
  - 基线不重跑：原样脚本、原样指南下 S4 的结果已记在任务文件（AI 手工绕过排队保护，在同一个工作区建第二个 Spec，先提交代码后过 g1）。S1 到 S3 在原样脚本下没有可比的做法。四种情形都只跑一次，只说明走得通。
- 方案审查结论：（「需人决定：是」，编码前由没写过方案的上下文只读审一遍，结论记在这里）
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [ ] Task 1：脚本认得多个工作区（任务池一份、Spec 归属、`status`、归档、验证锁）
  - 对应验收：AC-02、AC-03、AC-04、AC-05、AC-06、AC-07、AC-08、AC-12
  - 涉及文件：`template/scripts/ai-config.sh`、`template/scripts/ai-task-pool.sh`、`template/scripts/ai-gate.sh`、`template/scripts/ai-resume.sh`、`template/scripts/ai-verify.sh`
  - 验证：现有自检全过；临时沙箱里把并行场景走一遍
- [ ] Task 2：自检加多工作区用例；做改前、改后的单线程输出对照
  - 对应验收：AC-01、AC-02、AC-03、AC-04、AC-05、AC-06、AC-07、AC-08
  - 涉及文件：`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh`，再用 `LC_ALL=C` 复跑；对照的 `diff` 为空
- [ ] Task 3：并行指南和规则入口
  - 对应验收：AC-09
  - 涉及文件：`template/.agents/skills/parallel.md`、`template/AGENTS.md`
  - 验证：`wc -l`、`grep -c`、`bash scripts/ai-check-bloat.sh`
- [ ] Task 4：说明同步
  - 对应验收：AC-11
  - 涉及文件：`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`template/.agents/skills/upgrade.md`
  - 验证：`grep` 各处新增内容；核对 `skill/SKILL.md`、`README.en.md` 有没有要跟着改的句子
- [ ] Task 5：沙箱里真的 AI 会话四种情形；升级演练
  - 对应验收：AC-10、AC-11、AC-12
  - 涉及文件：`process/specs/active/feat-t-000059/tasks.md`
  - 验证：按方案里写定的判据逐条核对落盘状态；演练后的沙箱自检通过；`git diff --numstat` 核对体积

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/scripts/ai-gate.sh` 的 `cmd_pass`：同一道门可以重复 `pass`，`.gates` 里会多出一行同名记录（实测里一个会话同步后重新验证，没有先 `reset` 就又过了一次 g2）。不影响校验结果。建议归属：模板机制，另起任务。
- `template/scripts/ai-task-pool.sh` 的任务池锁：撞锁就挡回、提示稍后重试。四个工作区同一瞬间收录 12 次时 7 次被挡回。真的 AI 会话里还没因此出过问题。建议归属：任务文件里已记触发条件。

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：方案审查（编码前），然后过 g1。
- 这个 Spec 在哪做：不在主工作区。主工作区里 `feat-t-000058` 在等维护者的 g3 决定，不能动非流程文件。本 Spec 在主工作区旁边另开的工作区里做，分支是 `feat-t-000059`；用 `git worktree list` 找目录。本仓库现在的脚本还是原样的：主工作区的 `list` 会把 T-000059 显示成「关联异常」，这个工作区的 `status` 会同时列出 058 的旧副本，都是预期的。
- 已完成：需求收录和六轮讨论（任务文件）；维护者定了范围（Q1）、让查接入项目（Q2）、同名分支的判据（Q3）；requirements.md 和本方案。
- 原型在哪：系统临时目录里，重启可能被清掉，不要依赖它。逻辑都写在上面的方案里；指南第三稿全文在任务文件「目前的方向」一节。
- 已排除的方案：见任务文件「需求讨论」和各轮提交历史。
- 下一步：起一个没参与的上下文只读审 requirements.md 和本文件，结论写回方案；过 g1；Task 1。
