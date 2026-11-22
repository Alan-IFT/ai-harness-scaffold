# 任务与接力：feat-t-000056

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000056` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：五条发现逐条处理，守住维护者说的「独立于宿主，功能好用且不臃肿」：不加文件、配置键和新命令，不写只对某个 AI 工具有效的办法。维护者 2026-11-21 对 Q1~Q3 答「都按推荐」。
  1. **先验证后提交导致重跑**（Q1-A）：`template/AGENTS.md` 的「验证」一条加半句。
     - 旧：「- **验证**：正式验证 `bash scripts/ai-verify.sh --spec <feat>`，检查命令配在 `harness/verify.conf`。……」
     - 新：「- **验证**：正式验证 `bash scripts/ai-verify.sh --spec <feat>`，先提交代码再跑（验证后再 `git add`，状态指纹会变，验证就过期）；检查命令配在 `harness/verify.conf`。……」省略号处不动。
     - 括号里写原因，是因为同一节上面一条写着「完成后先验证再勾选并提交」（说的是任务自己的验证）；不写原因，两句读起来像是打架。写「再 `git add`」而不是「再提交」：实测让指纹变的是暂存这一步，已暂存的内容提交前后指纹不变。
     - `T-000051` 继续暂缓，启用条件已出现和维护者这次的选择记进了它的「补充与变更」。
  2. **验证失败到上限没停**（Q2-A）：不改脚本，不改黄卡的话，理由见 requirements.md 的 Q2。
  3. **审查者不写 `review.md`**（Q3-A）：`template/.agents/skills/code-review.md` Step 4 第一条。
     - 旧：「- 只读：发现问题写报告，不顺手修。……」新：「- 除 `review.md` 外只读：发现问题写报告，不顺手修。……」
  4. **门禁状态把 Git 的换行警告显示成阻断原因**：`template/scripts/ai-state-id.sh` 的 `git diff --binary` 改成 `git -c core.safecrlf=false diff --binary`，从源头不出这条警告，调用它的各个脚本一起受益。自检第 9 节末尾加 1 条断言「CRLF 文件不让指纹脚本输出警告」：测试仓库里加 `.gitattributes`（`* text=auto eol=lf`），把一个已跟踪文件写成 CRLF，断言指纹脚本的错误输出为空。先加断言、看它失败，再改脚本。
     - 不选「在 `ai-gate.sh` 里丢掉校验的错误输出」：指纹算不出来时的真实报错也走那里，丢了就只剩一个空的阻断原因。
  5. **README 的表加一行**（放在「需求在转述中走样」一行后面）：「| 需求里没说定的地方被 AI 按常规默认自己拍板 | 会改变交付结果的点写进「待确认问题」交人定，AI 不自己写结论；回「按推荐」「你定」才算授权 |」。
  6. **`MEMORY.md`**「复现 AI 自己拍板」那条的证据栏删掉「没指定模型的格子起初都记成了 Fable 5.2，独立审查之后核对运行记录才发现全是 Sonnet 5.5；」，只留数字（feat-t-000055 第 2 轮审查的建议；通用结论已在结论栏）。
  7. **活文档**：`docs/architecture/modules/template-mechanism.md` 加一条为什么指纹脚本关掉换行提示。两处文字改动里留下来的，在 `docs/architecture/modules/guidance.md` 加一条为什么，带对照结果；都撤回就不加。
  8. **实测**（AC-02、AC-04，按 `MEMORY.md`「行为类结论先实测」；模型都显式指定，跑完按宿主落盘的运行记录核对）：
     - 沙箱同 feat-t-000055 的小项目。旧文字的基准装基准提交 `fc25ae4` 的模板，新文字的基准装本次改动后的模板（规则、指南、Spec 模板和脚本）。
     - AC-02：提示词与 feat-t-000055 里「清楚的需求」那格逐字相同，只换目录；Sonnet 5.5；旧新各 3 次。判定按运行记录里的命令输出：主 AI 或它起的审查者运行 `scripts/ai-gate.sh`、`scripts/ai-resume.sh`、`scripts/ai-verify.sh` 时，输出里出现「验证摘要已过期」「验证已失效」「verification.md 已过期」之一，这次流程就算出现了验证过期。只数这三个脚本的输出，免得把它读脚本源码时看到的同一句话算进去。
     - AC-04：待审样本用 feat-t-000055 的样本一（一次 AI 自答自勾的实现），分别重放在两个基准上并各自重新验证；提示词与 feat-t-000055 里给审查者的逐字相同，只换目录和基准提交；Sonnet 5.5；旧新各 3 个审查者。判定看样本目录里有没有它写的 `review.md`。
     - 判定规则写在 AC-02、AC-04 里，跑之前定死；没有增量的那处撤回，重新跑受影响的自检。
- 改动文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`（两处都可能在对照后撤回）、`template/scripts/ai-state-id.sh`、`template/scripts/harness-selftest.sh`、`README.md`、`MEMORY.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`（有留下的文字改动才改）
- 影响与风险：
  - 指纹脚本加的参数只关掉 Git 的换行提示，不改 `git diff` 的输出：2026-11-21 规划时在系统临时目录实测，同一个带 CRLF 文件的工作区，加参数前后指纹值相同，警告从 1 行变 0 行。实现后用真脚本再测一次（AC-05）。Git 的 `-c` 优先级高于环境变量和配置文件，项目自己把 `core.safecrlf` 设成 `true` 时，指纹脚本里这一条 `git diff` 也不会因换行不可逆而失败。
  - 脚本内容计入状态指纹：接入项目升级后在途的验证要重跑。任何一次带脚本改动的升级都是这样，升级说明第 1 步已要求先归档在途 Spec。
  - 「先提交代码再跑」可能被读成「任务自己的验证也要先提交」：括号里的原因是为了挡这个；对照时留意新文字下有没有 AI 不跑测试就提交。
  - 「除 `review.md` 外只读」让审查者写文件：它写的位置在 `process/` 下，不计入指纹，不会让验证过期。
  - 随下一个 tag 才到接入项目，本 Spec 不打 tag。
  - 同步面：`README.md` 的脚本表里 `ai-state-id.sh`、`ai-verify.sh` 的说明和参数不变；流程图和三道门的校验内容不变；`skill/SKILL.md`、`upgrade.md` 不涉及；`README.en.md` 是摘要，不涉及。自检断言数 76 变 77，仓库里没有别处写着这个数（已 grep）。
  - 「需人决定：否」的依据见 requirements.md；收尾的独立审查会复核这个判定。
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：改两处规则文字
  - 对应验收：AC-01、AC-03
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`
  - 验证：AC-01、AC-03 的命令；`bash scripts/ai-check-bloat.sh`
- [x] Task 2：指纹脚本关掉换行提示，自检加断言
  - 对应验收：AC-05
  - 涉及文件：`template/scripts/harness-selftest.sh`、`template/scripts/ai-state-id.sh`
  - 验证：先只加断言跑自检（应失败 1 项），再改脚本跑自检（Git Bash 与 WSL 都失败 0 项）；指纹值前后对比
- [x] Task 3：两处文字的新旧对照，定留不留
  - 对应验收：AC-02、AC-04
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`（无增量证据的撤回；对照在系统临时目录，结果记进 WIP 区）
  - 验证：AC-02、AC-04 的记录与结论；撤回的话跑 AC-01 或 AC-03 里对应的那条命令
- [x] Task 4：README 加一行，记忆删经过，活文档写为什么
  - 对应验收：AC-06、AC-07
  - 涉及文件：`README.md`、`MEMORY.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`
  - 验证：AC-06 的命令，AC-07 里活文档那条
- [ ] Task 5：整体验收
  - 对应验收：AC-07
  - 涉及文件：无新增
  - 验证：AC-07 的其余命令

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `docs/architecture/modules/guidance.md`「为什么「待确认问题」按后果划线」一条 / 写着「清楚的需求没有多问」和「新文字 3 次拦住 2 次」，都是 feat-t-000055 当时的记录；本 Spec 的 Task 3 多跑了几次之后：同一句清楚的需求 7 次里 2 次被多问，同一份样本上 Sonnet 5.5 审查者带着那半句 8 次里只拦了 2 次 / 本 Spec 的对照中看到的，不在五条发现之内；我建议在那一条里补上这两个数，由维护者决定
- `template/AGENTS.md` 的「待确认问题」一条 / 清楚的需求被多问的两次，问的是「只输出 1.0.0 还是带程序名」「要不要加 -V」，原话其实已经定了前者，后者属于需求以外的功能 / 同上；先用用看，多问多了再收紧，由维护者决定
- `template/scripts/ai-verify.sh` 的失败上限 / 到上限的 4 次流程里 2 次停下等同意、2 次直接再跑，4 次都是测试里的转义笔误，没有反复硬闯 / 维护者已在 Q2 选了不改；这组数留给以后再议时参考

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 5。g1 已过。
- 已完成：需求收录；五条发现各自的成因查清并复现（见下）；维护者 2026-11-21 对 Q1~Q3 答「都按推荐」，原话记进了任务文件，需求、验收和方案按它定稿。
- 已排除的方案：维护者没选的见 requirements.md 的 Q1~Q3；在 `ai-gate.sh` 里丢掉错误输出，见方案第 4 条。
- 已完成：Task 1（2026-11-21）。AC-01：`grep -c` 输出 1，`git diff --numstat fc25ae4 -- template/AGENTS.md` 为 `1 1`，文件 40 行。AC-03：`grep -c` 输出 1，`git diff --numstat` 为 `1 1`。体积检查通过。两处留不留看 Task 3。
- 已完成：Task 2（2026-11-21）。
  - 先只加断言、不改脚本：自检「77 项断言，失败 1 项」，失败的就是新断言，带出的输出是 `warning: in the working copy of 'source.txt', CRLF will be replaced by LF the next time Git touches it`。
  - 改脚本后：Git Bash（git 2.56）与 WSL（Ubuntu，git 2.53）下自检都是「77 项断言，失败 0 项」。`grep -c 'git -c core.safecrlf=false diff --binary' template/scripts/ai-state-id.sh` 输出 1。
  - 指纹值不变：系统临时目录的沙箱里，同一个带 CRLF 文件的工作区，基准提交 `fc25ae4` 的脚本和改后的脚本算出同一个值（`37da611a…f1a2`），错误输出从 1 行变 0 行；没有 CRLF 文件的干净工作区，两个脚本的值也相同。
  - Linux 那边不改也有这条警告：在 WSL 的临时仓库里，`git diff --binary` 的错误输出 1 行，加 `-c core.safecrlf=false` 后 0 行，所以这条断言在 CI 的 Linux 任务上也是真的在检查。
- 已完成：Task 3，两处文字的新旧对照（2026-11-21，系统临时目录；12 次都显式指定 Sonnet 5.5，宿主落盘的运行记录里模型字段都是 `claude-sonnet-5-5`）。**两处都是「无增量证据」，都已撤回**：`git diff --stat fc25ae4 -- template/AGENTS.md` 和 `git diff --stat fc25ae4 -- template/.agents/skills/code-review.md` 都无输出。
  - AC-04，审查者写不写 `review.md`（样本和提示词相同，两边只差 Step 4 那一行）：旧文字 3 个审查者 2 个写了文件，新文字 3 个里 1 个写了。写了文件的次数新文字不多于旧文字，记「无增量证据」。新文字下没写的两个审查者里，一个在回复里说写 `review.md`、过 g3「是你们的步骤」。
  - AC-02，先提交再验证（同一句清楚的需求，旧新各 3 次）：按事先定的指标，6 次流程里「验证过期」的提示都是 0 处，新文字不少于旧文字，记「无增量证据」。6 次都走到了归档。
    - 指标之外看到的先后顺序（按运行记录里的命令排，供维护者判断，不改上面的结论）：新文字 3 次都是先提交代码再跑正式验证，其中 2 次全程只跑了 1 次正式验证。旧文字 3 次分别跑了 5、7、5 次正式验证：它们都先碰上了自己测试里的转义笔误，连续失败 2~3 次，改一次提交一次，最后通过的那次恰好排在提交之后，所以没有出现过期提示；其中 1 次验证通过后提交，紧接着又验证了一遍。
    - 也就是说，这次旧文字那边没有出现要比的那件事（feat-t-000055 里是 7 次流程 4 次），样本没有分辨力。按规则仍记「无增量证据」并撤回；要不要换一个更直接的指标（第一次正式验证之前有没有先提交代码）再比一次，由维护者决定。
  - 顺带看到、与本 Spec 的改动无关的三件事（都记进了「发现但不碰」）：
    - 清楚的需求也会被多问。「加 --version」这句话在 feat-t-000055 的规则下 4 次里 1 次停在 g1 问输出格式（本次旧文字 3 次加 feat-t-000055 的 1 次）；本次新文字 3 次里 1 次问了输出格式和要不要 `-V`。feat-t-000055 写的「清楚的需求没有多问」只有 1 次的依据。
    - feat-t-000055 的审查半句没有当时看起来那么管用。这 6 个 Sonnet 5.5 审查者的指南里都有那半句，样本是同一份自答自勾的实现，只有 1 个判成关键问题；连同 feat-t-000055 的 2 次，同一份样本上是 8 次里 2 次。
    - 验证失败到上限：这批又有 3 次流程连续失败到上限，都是测试里的换行转义写错，2 次停下来等同意，1 次直接跑了第 4 次。连同 feat-t-000055 的 1 次，是 4 次里 2 次停、2 次没停。
  - 局限：每边 3 次，同一个模型，同一句需求或同一份样本；AC-02 里有 3 次流程中途收到过「维护者」的一句答复（2 次「按推荐」、2 次「同意」，其中 1 次流程两句都收到），两边都有。
- 已完成：Task 4（2026-11-21）。AC-06：README 那一行 `grep -c` 输出 1；`MEMORY.md` 里「起初都记成了」0 次、「复现「AI 自己拍板」」1 次；`git diff --stat fc25ae4 -- template/scripts/ai-verify.sh template/scripts/ai-gate.sh` 无输出；任务池里 `T-000051` 仍是「暂缓」，它的任务文件里有 1 处提到 `feat-t-000056`。AC-07 的活文档一条：`grep -c 'core.safecrlf' docs/architecture/modules/template-mechanism.md` 输出 1。两处文字改动都撤回了，所以 `docs/architecture/modules/guidance.md` 没有改。README 的脚本表、流程和配置表核对过，不用改。体积检查通过。
- 下一步：Task 5 整体验收，正式验证，独立审查，归档。归档后要不要推送，问维护者（上次的「推送」说的是 feat-t-000055）。

### 成因与依据（2026-11-21；写「实测」的在系统临时目录的沙箱里跑过，其余是读代码的结论）
1. 先验证后提交。实测：同一个工作区，没暂存时、`git add` 之后、提交之后的指纹分别是甲、乙、乙。验证后再 `git add` 会过期；先暂存或提交再验证，之后提交仍有效。`template/scripts/ai-state-id.sh` 把索引条目、没暂存的 diff、没跟踪的文件分开算，所以暂存这个动作本身就改变指纹。`template/AGENTS.md:31` 写的「完成后先验证再勾选并提交」说的是任务自己的验证，只有一个任务的 Spec 里，AI 把它当成了正式验证的顺序。出现次数：feat-t-000055 的沙箱里走到正式验证的 7 次流程中 4 次。`T-000051` 的规划里写着暂缓期间的替代办法是「在指南里加一句先提交再验证」。
2. 验证失败到上限。`template/scripts/ai-verify.sh:43-50`：失败计数到 `VERIFY_MAX_ATTEMPTS` 时打印黄卡，不拦下一次；通过后清零。出现 1 次：那次在归档的 tasks.md 里写着「前三次失败是我测试里字符串转义笔误，已修」。
3. 审查者不写 `review.md`。`template/.agents/skills/code-review.md` Step 3 的标题是「写 `review.md`」，Step 4 第一条是「只读：发现问题写报告，不顺手修」。feat-t-000055 的沙箱里，Sonnet 5.5 审查者 8 次有 2 次写了文件，Fable 5.2 审查者 3 次都写了；我给它们的提示词相同，里面有一句「你的最终回复会原样转给实现者和项目维护者」。
4. 换行警告。实测：工作区有一个 CRLF 文件（仓库按 `.gitattributes` 统一成 LF）时，`ai-state-id.sh` 里的 `git diff` 往错误输出写一行 `warning: in the working copy of ... CRLF will be replaced by LF`；`template/scripts/ai-gate.sh` 的 `render_spec` 用 `2>&1` 收集校验输出，这行就排在真正的阻断原因前面。加 `-c core.safecrlf=false` 后警告消失，指纹值不变。
5. README 的表：现有 6 行，没有「需求里没说定的地方被 AI 自己拍板」这一行；`README.md` 的「日常使用」和停下清单已在 feat-t-000055 里同步过。
