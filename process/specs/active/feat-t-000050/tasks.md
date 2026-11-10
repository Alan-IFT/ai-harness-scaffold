# 任务与接力：feat-t-000050

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000050` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 所属规划：同一句答复拆出的三个 Spec 里的第二个。前置 `feat-t-000049`（状态指纹只在 Git 仓库里算）已归档；`T-000051`（状态指纹只按文件内容算）暂缓。本条归档、CI 通过后发 v2.2.0（公开标签由维护者自己打），接入项目跳过 v2.1.4 直接升到这一版。
- 思路：检查命令和状态指纹本来就是全项目的，`<file>` 只在指纹后面再追加这一个文件的哈希，不改变查什么；所以把参数、`$TARGET_FILE` 和 g2 的目标检查一起删掉，不留兼容。逐项如下（行号是 `feat-t-000049` 归档后的，2026-11-10 开工时重新核对过）。
  - `template/scripts/ai-verify.sh`：头部注释和用法提示改成不带文件（第 5、10 行）；参数检查改成「第一个参数是 `--spec` 且一共两个参数」，否则打印用法退出；删掉 `TARGET_FILE` 的赋值、文件存在检查、相对路径与 `process/` 检查和 `export`（第 11、15~21 行）；未配置检查的提示去掉「（可用 `$TARGET_FILE`）」（第 39 行）；指纹调用不带参数（第 62 行）；`verification.md` 去掉 `- target:` 行，`- command:` 行不带文件（第 66、69 行）。
  - `template/scripts/ai-state-id.sh`：删掉取参数、检查文件存在、追加目标哈希共 4 行（第 8、9、24、25 行）。
  - `template/scripts/ai-gate.sh` 的 `ck_g2`：删掉 `target` 变量和两条目标检查（第 80、85、89、90 行）；指纹调用不带参数（第 91 行）；缺摘要的提示里去掉 `<file>`（第 84 行）。
  - `template/scripts/ai-resume.sh`：review 与 owner 两处不再读 `target`（第 41、43、83、86 行）；owner 显示摘要时不再列 `target`（第 82 行）；过期判断的条件只留「有保存的指纹」（第 85 行）。
  - `template/scripts/harness-selftest.sh`：`make_summary` 不写 `- target:`、指纹调用不带参数（第 63、65 行）；第 3 节删掉 `t-offtask`、`t-wiponly` 两个夹具连同断言（第 174~180 行）；第 7 节所有 `ai-verify.sh` 调用去掉文件参数（第 243~258 行），「必须指定 Spec」改成不带任何参数调用，「拒绝流程文件作正式目标」换成「拒绝旧用法多带的参数」，夹具命令 `test -f "$TARGET_FILE"` 换成 `test -f src/export/service.ts`；第 9 节 `fp()` 不带参数（第 272 行），断言名「非目标文件变化计入指纹」改成「任一文件变化计入指纹」（第 275 行），`nogit()` 去掉 `redlines.fixture` 参数（第 286 行，前一个 Spec 新加的），夹具摘要去掉 `- target:`（第 292 行）。
  - 规则与文档的写法：
    - `template/AGENTS.md` 第 32 行：「**验证**：正式验证 `bash scripts/ai-verify.sh --spec <feat>`，检查命令配在 `harness/verify.conf`，对整个项目生效。`process/` 只放流程记录，不计入状态指纹，代码不得引用。」
    - `template/.agents/skills/code-review.md` 第 7 行：「`bash scripts/ai-verify.sh --spec <feat>`：运行 `harness/verify.conf` 的检查命令，对整个项目生效。」
    - `template/harness/verify.conf` 第 1 行：「# ai-verify.sh 运行的项目检查：用 `bash -c "$CUSTOM_CHECK"` 执行，写一条对整个项目生效的命令。」
    - `template/.agents/skills/upgrade.md` 第 6 步末尾加：「`CUSTOM_CHECK` 或文件注释里还有 `$TARGET_FILE` 的（新版不再提供，正式验证只跑整项目的检查），连同建议的命令交人决定。」
    - `README.md` 第 113 行去掉「验证目标在本次「涉及文件」里；」；第 198 行用法栏改成 `--spec <feat>`；第 199 行用法栏改成「无参数」。
    - 根 `AGENTS.md` 第 14 行：去掉 `<file>`。
    - `docs/architecture/modules/template-mechanism.md`：删掉「为什么 g2 要求验证目标在「涉及文件」里」（第 9 行），新增「**为什么正式验证不带目标文件**：检查命令和状态指纹都是全项目的，选哪个文件都不影响查什么。按 `$TARGET_FILE` 逐个文件检查反而留下口子：挑一个无关、必过的文件也能拿到 PASS，当初要求目标写在「涉及文件」里就是为了堵它。不再提供这个变量，口子和补丁规则一起去掉。」
- 改动文件：`template/scripts/ai-verify.sh`、`template/scripts/ai-state-id.sh`、`template/scripts/ai-gate.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`template/harness/verify.conf`、`template/.agents/skills/upgrade.md`、`README.md`、`AGENTS.md`、`docs/architecture/modules/template-mechanism.md`。
- 影响与风险：
  - 依据（2026-11-10 核对）：本仓库的 `harness/verify.conf` 没用 `$TARGET_FILE`，模板 `verify.conf` 的三个示例（`npm test`、`python -m pytest -q`、`go vet ./...`）也没用。18 个归档 Spec 里选得最多的目标是 `template/AGENTS.md`（5 次）。活文档写明，g2 要求目标在「涉及文件」里，是为了堵「选一个无关、必过的文件也能拿到 PASS」；这个口子只在检查命令按 `$TARGET_FILE` 逐个文件检查时才有。
  - 要改的位置开工时重新 grep 过：`<file>`、`TARGET_FILE`、`验证目标`、`目标选` 在 `README.md`、`README.en.md`、根 `AGENTS.md`、`skill/`、`template/`、`docs/architecture/`、`MEMORY.md` 里只出现在上面列的位置；`skill/SKILL.md`、`README.en.md`、ADR 没提目标文件。「涉及文件」只有 `ai-gate.sh` 第 90 行在读，删掉后它只供审查者对照方案。
  - 旧用法直接报用法提示是有意的：静默接受多余的文件参数，会让人以为目标还在起作用。升级时脚本和 `AGENTS.md` 一起换，不会出现规则说旧用法、脚本只认新用法的中间状态。本仓库里四个任务都提交之后再推送，公开的 main 上不出现这种中间状态。
  - `CUSTOM_CHECK` 用了 `$TARGET_FILE` 的项目，升级后这个变量是空的：多数会直接失败（如 `eslint ""`），少数会悄悄变成别的意思（没加引号的 `pytest $TARGET_FILE` 会变成跑全部测试；`grep -q x $TARGET_FILE` 会等标准输入）。所以要在升级第 6 步就找出来，不写兼容代码。
  - 归档里的 `verification.md` 保留着 `- target:` 行，之后没有脚本再读它们。
  - 自检断言从 77 项变成 75 项。
  - 必须排在 `feat-t-000049` 之后（已满足）：非 Git 目录里指纹原来只靠目标文件，先去掉目标的话那里的指纹就恒定不变了。
  - 未知：某接入项目的 `harness/verify.conf` 有没有用 `$TARGET_FILE`。它不影响本条怎么做，只影响那个项目升级时要不要改一行，由升级说明第 6 步兜住。
- 方案审查（2026-11-10，独立 subagent 上下文，只读，规划时三个 Spec 一起审；原文在 `T-000050.md` 的「方案审查」）：
  - 两条「必须改」，都已采纳：要改的位置漏了自检里改断言名的那一行（现第 275 行），两个不再使用的夹具也没写明要删；AC-09 的「77 减 3 加 1」容易看错，已改成「删 2 条、换 1 条」。
  - 审查指出红线样例第 8 行的「同一目标」会变得含糊。那个文件只允许人改，记在「发现但不碰」。
  - 审查核对无误：四个脚本的行号、`template/AGENTS.md` 是 39 行、当时的断言数；「需人决定：是」判得对；必须排在 `feat-t-000049` 之后这一点属实，反方向没有依赖；本条单独做完，脚本、自检、规则和文档自洽。
  - 审查没有核对：AC-08 的升级演练、CI 的运行情况。
  - 开工时相对审过的方案只有两处变化，都来自 `feat-t-000049` 的改动：`ai-state-id.sh` 与自检的行号后移；自检新加的 `nogit()` 调用带了一个文件参数，要一并去掉。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：四个脚本与自检去掉目标文件
  - 对应验收：AC-01、AC-02、AC-03
  - 涉及文件：`template/scripts/ai-verify.sh`、`template/scripts/ai-state-id.sh`、`template/scripts/ai-gate.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh` 为 75 项、失败 0 项；AC-02 的 grep（`verification.md` 那两条留到 Task 4 正式验证后核对）
- [x] Task 2：规则、指南、配置样例与升级说明
  - 对应验收：AC-04、AC-05、AC-07
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`template/harness/verify.conf`、`template/.agents/skills/upgrade.md`
  - 验证：AC-05、AC-07 的命令；AC-04 的命令在 Task 3 做完后一起跑
- [x] Task 3：README、根 `AGENTS.md` 与活文档
  - 对应验收：AC-04、AC-06
  - 涉及文件：`README.md`、`AGENTS.md`、`docs/architecture/modules/template-mechanism.md`
  - 验证：AC-04、AC-06 的命令
- [x] Task 4：升级演练、CI 与正式验证
  - 对应验收：AC-08、AC-09
  - 涉及文件：`template/.agents/skills/upgrade.md`（演练里发现说明不清楚才改）
  - 验证：按 AC-08 在系统临时目录演练；推送后等 CI，跑 AC-09 的命令；正式验证后核对 AC-02 里 `verification.md` 的两条

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/harness/redlines.conf` 第 8 行与 `template/AGENTS.md` 第 33 行 / 都写「同一目标连续验证失败」，这里的「目标」指同一件要做成的事，失败次数本来就按 Spec 计；去掉目标文件后，这个词可能被读成文件 / 红线样例只允许人改，是否换个说法由维护者决定
- `template/.agents/skills/upgrade.md` 第 4 步 / 没说与基线比对时换行符怎么处理，演练里的 subagent 自己把 CRLF 去掉再比 / 演练中的观察，不是本条引入的；是否补半句由维护者决定
- `template/.agents/skills/upgrade.md` 第 6 步新加的那句 / 「文件注释」没点名是哪个文件，演练里的 subagent 按上下文理解成 `harness/verify.conf` 的注释，理解对了 / 演练中的观察；真有人理解错再改

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无（四个任务都已完成，等独立审查和维护者的决定）
- 已完成：需求与方案（规划时写在 `T-000050.md`，开工时搬进 Spec 并按 `feat-t-000049` 归档后的代码核对了行号）
- 已完成：Task 1（2026-11-10，Git Bash）。
  - AC-01、AC-03：`bash scripts/harness-selftest.sh` 输出「75 项断言，失败 0 项」，用时 58 秒。第 3 节剩「拒绝未完成任务」「拒绝失败摘要」「拒绝代码变化后的过期摘要」三条；第 7 节「正式验证生成摘要」的命令是 `bash scripts/ai-verify.sh --spec t-verify`，新断言「拒绝旧用法多带的参数」通过。变异检查：临时去掉 `ai-verify.sh` 第 10 行的 `&& [ "$#" -eq 2 ]` 重跑，75 项里只有「拒绝旧用法多带的参数」失败（多带的参数被静默接受，走到了「未配置检查」），恢复后文件的 SHA-256 与去掉前相同。在本仓库直接运行 `bash scripts/ai-verify.sh --spec feat-t-000050 README.md` 与不带参数的 `bash scripts/ai-verify.sh`，都只打印「👉 用法: bash scripts/ai-verify.sh --spec <feature>」并以 1 退出，没有跑检查命令。
  - AC-02（脚本部分）：`grep -ci 'target' template/scripts/ai-verify.sh template/scripts/ai-state-id.sh template/scripts/ai-gate.sh template/scripts/ai-resume.sh` 四个都输出 0。`verification.md` 的两条留到 Task 4。
- 已完成：Task 2。四个文件各改一行，写法与方案一致。AC-05：`wc -l < template/AGENTS.md` 输出 39。AC-07：`grep -c 'TARGET_FILE' template/.agents/skills/upgrade.md` 输出 1。`skill/SKILL.md` 提到 `harness/verify.conf` 的两处（第 19、25 行）没说目标文件，不用改。AC-04 的命令等 Task 3 做完一起跑。
- 已完成：Task 3。
  - AC-04：`grep -rl 'TARGET_FILE' template skill README.md README.en.md AGENTS.md docs/architecture` 只输出 `template/.agents/skills/upgrade.md` 与 `docs/architecture/modules/template-mechanism.md`；`grep -c '<file>' README.md template/AGENTS.md template/.agents/skills/code-review.md AGENTS.md` 四个都输出 0；`grep -c '验证目标' README.md` 输出 0。另外 grep 过 `目标文件`、`目标选`、`file_path`、`待验证文件`，只剩活文档新增的那一条标题。
  - AC-06：`grep -c '为什么 g2 要求验证目标' docs/architecture/modules/template-mechanism.md` 输出 0；`grep -c '为什么正式验证不带目标文件' docs/architecture/modules/template-mechanism.md` 输出 1。
- 已完成：Task 4（2026-11-10）。升级说明没有再改。
  - AC-08 升级演练（系统临时目录，Git Bash）：
    - 装旧版：按 v2.1.4 的 `skill/SKILL.md` 第 1、3 节装一个新项目（`git init -b main`，用 `git show v2.1.4:template/<文件>` 写出全部模板文件，`.ai-harness/version` 写 `commit=d0149b4e…`），加 `src/app.sh` 和 `tests/run.sh`，`harness/verify.conf` 末尾写 `CUSTOM_CHECK='bash -n "$TARGET_FILE" && bash tests/run.sh'`。旧版自检「76 项断言，失败 0 项」，旧用法 `bash scripts/ai-verify.sh --spec drill-old src/app.sh` 通过。
    - 升级：交给一个没有上下文的 subagent 充当项目里的 AI，只告诉它「把脚手架升级到提交 4da97f8…，脚手架仓库在本机某路径」，没有提 `$TARGET_FILE`。它按项目里的升级说明第 2 步读了目标版本的说明并照新版做：覆盖 8 个有变化的机制文件，`.ai-harness/version` 改成目标提交，自检「75 项断言，失败 0 项」，提交。第 6 步它原样列出 `verify.conf` 第 1 行的注释和第 7 行的 `CUSTOM_CHECK`，建议换成 `bash -n src/app.sh && bash tests/run.sh`，没有自己改。
    - 我的复核：演练项目里的机制文件与 `git show 4da97f8:template/<文件>` 逐个 `cmp` 一致；本机脚手架仓库没有被改动。换命令之前先用新用法跑了一次 `bash scripts/ai-verify.sh --spec drill`，失败，输出 `bash: : No such file or directory`（变量为空）；把 `CUSTOM_CHECK` 换成建议的整项目命令后同一条命令通过，`verification.md` 只有 `result`、`state`、`command`、`verified_at_utc` 四行，没有 `- target:`；旧用法 `bash scripts/ai-verify.sh --spec drill src/app.sh` 打印用法并以 1 退出。
    - subagent 说没有需要靠猜的地方，提了两点措辞，记在「发现但不碰」。
  - AC-09：自检 75 项见 Task 1。提交 4da97f8 推送后的 CI 运行 42827693413：`gh run view 42827693413 --json jobs --jq '.jobs[].name, .jobs[].conclusion'` 输出 `selftest (ubuntu-latest)`、`selftest (windows-latest)`、`success`、`success`；`--log` 里两个任务各有一行「75 项断言，失败 0 项」，也各有「✅ 拒绝旧用法多带的参数」。4da97f8 之后的提交只动 `process/`。`bash scripts/ai-check-bloat.sh` 输出体积正常；`bash scripts/ai-verify.sh --spec feat-t-000050` 为 PASS，用时 81 秒。
  - AC-02（`verification.md` 部分）：本 Spec 的 `verification.md` 上 `grep -c '^- target:'` 输出 0，`grep -c '^- command: bash scripts/ai-verify.sh --spec feat-t-000050$'` 输出 1。
- 已排除的方案：兼容旧用法、静默忽略多余的文件参数（会让人以为目标还在起作用）；保留 `$TARGET_FILE` 作可选变量（口子和补丁规则都得留着）
- 下一步：过 g2，独立审查。g3 需要维护者的当次决定：审查通过后把风险和结果讲给维护者，由他说「通过」或「不通过」。
