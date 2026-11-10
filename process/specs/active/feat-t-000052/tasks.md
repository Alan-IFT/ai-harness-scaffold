# 任务与接力：feat-t-000052

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000052` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：`feat-t-000050` 去掉目标文件这个方向不变：一个目标文件代表不了一次改动，按它分派时查什么取决于挑了哪个文件。缺的是给「整项目检查跑不动」的项目留一条替代的路，并把升级时的风险讲准。替代的路只需要让检查命令知道当前是哪个 Spec：它自己去读该 Spec tasks.md 的全部「涉及文件」来分派。所以脚手架这边只导出一个变量、改几句话，不提供解析或分派的代码。逐项如下。
  - `template/scripts/ai-verify.sh`：第 11 行 `SPEC_NAME="$2"` 改成 `export SPEC_NAME="$2"`；头部用法注释（第 5 行）末尾加「（检查命令里可用 `$SPEC_NAME`）」。变量名不换：已有接入项目在 `verify.conf` 里靠 source 时展开用着这个名字，导出后两种写法都成立。
  - `template/scripts/harness-selftest.sh`：
    - 第 7 节在「g2 接受真实生成的摘要」之后加一条：把夹具换成 `CUSTOM_CHECK='test "$SPEC_NAME" = t-verify'`（单引号，source 时不展开），断言「检查命令能读到 Spec 名」通过。它是一次通过的验证，不影响后面连续失败计数的三条。
    - 开头 `set -u` 之后加一行 `export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false`，带一句注释。沙箱里的文件都是 LF；Git Bash 的系统配置是 `core.autocrlf=true`，所以两个沙箱仓库每个文件都报一行警告。用环境变量是因为它对自检起的所有 git 进程（包括被测脚本里的）都生效，一行管住第 1 节前的沙箱和第 9 节的仓库。真实的接入项目有 `.gitattributes` 的 `* text=auto eol=lf`，同样不做 CRLF 转换。
  - `template/harness/verify.conf`：第 1 行末尾的「写一条对整个项目生效的命令」改成「默认写一条对整个项目生效的命令」；其后加一行「# 整项目检查跑不动的，让命令按 $SPEC_NAME（当前 Spec 名）读该 Spec tasks.md 的「涉及文件」挑检查；没有对应检查的文件必须失败，不能放行。」
  - `template/.agents/skills/upgrade.md` 第 6 步：把 `feat-t-000050` 加的最后一句换成「`CUSTOM_CHECK`、它调用的项目脚本或 `verify.conf` 的注释里还有 `$TARGET_FILE` 的：新版不再提供这个变量，它是空的，按它分派的命令可能落到默认分支，什么都没查就通过。建议换成整项目命令；整项目检查跑不动的，改成按 `$SPEC_NAME` 读该 Spec「涉及文件」分派，没有对应检查的文件必须失败。连同建议交人决定，改好之前新版的正式验证不可信。」
  - `template/AGENTS.md`：第 32 行去掉「，对整个项目生效」；第 33 行「同一目标连续验证失败」改成「同一 Spec 连续验证失败」（脚本按 Spec 目录里的 `.attempts` 计数，README 第 118、213 行已经写「同一 Spec」）。行数不变。
  - `template/.agents/skills/code-review.md` 第 7 行：改成「`bash scripts/ai-verify.sh --spec <feat>`：运行 `harness/verify.conf` 的检查命令。」
  - `README.md` 第 215 行配置表：`CUSTOM_CHECK` 的作用改成「正式验证运行的命令，如 `npm test`；命令里可用 `$SPEC_NAME`（当前 Spec 名）；不配置时 g2 过不去」。
  - `docs/architecture/modules/template-mechanism.md`：把「为什么正式验证不带目标文件」一条换成「**为什么正式验证不带目标文件、却导出 `SPEC_NAME`**：一个目标文件代表不了一次改动。按 `$TARGET_FILE` 分派检查时，查什么取决于挑了哪个文件，挑一个容易过的也能拿到 PASS；当初要求目标写在「涉及文件」里只堵了一半。检查默认对整个项目生效，状态指纹也是全项目的。但核对过的三个接入项目都靠目标文件分派增量检查（整项目检查太慢，或要外部数据库），所以留一条替代的路：检查命令按 `$SPEC_NAME` 读该 Spec 的全部「涉及文件」来分派。」
- 改动文件：`template/scripts/ai-verify.sh`、`template/scripts/harness-selftest.sh`、`template/harness/verify.conf`、`template/.agents/skills/upgrade.md`、`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`。
- 影响与风险：
  - 依据（2026-11-10 只读核对本机三个接入项目的 `harness/verify.conf`，项目名不写进公开仓库）：
    - 项目甲：`CUSTOM_CHECK` 调一个项目脚本，参数是 Spec 名和目标文件，脚本按路径分派，并且已经在读该 Spec tasks.md 的「涉及文件」（维护者此前定的规则：改了后端代码的 Spec 不得选别的文件绕过）。目标为空时脚本报「缺验证目标」失败。
    - 项目乙：按文件类型分派，没有对应检查的类型明确失败。目标为空时失败。
    - 项目丙：8 个分支按模块分派，默认分支是跑脚手架自检。目标为空时落到默认分支，只跑脚手架自检就 PASS。
    - 三个都不是全项目检查，所以 `feat-t-000050` 的活文档里「检查命令和状态指纹都是全项目的，选哪个文件都不影响查什么」对它们不成立。按文件分派的做法有来历：`install-skill.md` 记着，脚手架去掉 CLI 时曾把选命令写成「能对单个文件跑的检查」。
  - `SPEC_NAME` 成为公开契约：以后改名或不再导出，就是和去掉 `$TARGET_FILE` 同类的破坏性变更。名字很通用，会盖住调用环境里同名的变量；`ai-verify.sh` 本来就给它赋值，只是没导出，脚本内部的行为不变。
  - 按「涉及文件」分派时，漏写涉及文件就漏查。这和原来「目标必须在涉及文件里」是同一层信任，由独立审查对照 diff 兜住（审查指南本来就要求每一行改动对应到需求）。不为它给审查指南加条目。
  - 悄悄通过的情形（项目丙那种）在脚手架这边没有机械的拦截，只靠升级第 6 步被执行、交人决定。可选的做法是 `ai-verify.sh` 发现 `CUSTOM_CHECK` 里还有 `TARGET_FILE` 就判未验证（两三行加一条断言），但那是迁移代码，与「升级写成说明」的约定冲突，所有项目升完之后就成了死代码；它也只认得出 `CUSTOM_CHECK` 字面里的 `TARGET_FILE`，经项目脚本间接读这个变量的拦不住（第 6 步因此要求连它调用的项目脚本一起查）。本条按约定不加，g3 时请维护者一并定。
  - 自检用环境变量改 Git 配置，要求 Git 2.31 以上；本机是 2.56，CI 的两个系统镜像都高于这个版本。旧版 Git 会忽略这些变量，结果只是警告还在，断言不受影响。调用方自己设了 `GIT_CONFIG_COUNT` 的话会被自检覆盖，只影响自检进程。
  - `template/AGENTS.md` 第 32 行去掉「对整个项目生效」后，规则不再描述检查的范围，范围写在 `verify.conf` 的注释里。
  - `verify.conf` 属项目状态，升级不动它，所以已接入项目看不到样例里新加的那行注释，只能从升级说明第 6 步读到这条路；第 6 步因此把做法写全，不只指向样例。
  - 自检断言从 75 项变成 76 项。
- 方案审查（2026-11-10，独立 subagent 上下文，只读，编码前）：结论是可以开工，没有「必须改」。
  - 三条建议都已采纳：README 里写「同一 Spec」的是第 118、213 行（原稿写成 211）；活文档的新文字保留「状态指纹也是全项目的」这半句，它仍然成立；风险里补上检测残留 `TARGET_FILE` 这个做法的局限。
  - 审查提醒：AC-04 那条 grep 同时给两个文件时，输出是每个文件一行「文件名:0」，核对时按每个文件的计数为 0 判。
  - 审查核对无误：方案引用的行号和现有文字（`ai-verify.sh` 第 5、11 行，source `verify.conf` 在第 29 行；`template/AGENTS.md` 第 32、33 行、共 39 行；`code-review.md` 第 7 行；`upgrade.md` 第 14 行）；连续失败按 Spec 目录里的 `.attempts` 计数（`ai-verify.sh` 第 44 行）；AC-02、AC-03、AC-05 的 grep 计数按方案的文字都对得上；`export SPEC_NAME="$2"` 在 `set -u`、`ai_config_load`、`bash -c` 子进程下没有副作用；单引号夹具能证明变量是运行时可见的；`README.en.md`、`skill/SKILL.md` 不用改；「需人决定：是」判得对；从三个项目的事实推出「要留替代的路、第 6 步要改」的逻辑成立。
  - 审查自己做的实验：带上 `GIT_CONFIG_COUNT` 那三个环境变量跑完整自检，「75 项断言，失败 0 项」，换行警告 0 行（不带时 25 行），第 9 节的指纹断言照常通过。
  - 对「不在 `ai-verify.sh` 里检测残留的 `TARGET_FILE`」，审查倾向不加：升完就是死代码，间接引用也拦不住。这件事仍由维护者在 g3 时决定。
  - 审查没有核对：三个接入项目的 `verify.conf`（要求它不去找）、CI、升级演练。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [ ] Task 1：导出 `SPEC_NAME`，自检加断言并关掉换行警告
  - 对应验收：AC-01、AC-06
  - 涉及文件：`template/scripts/ai-verify.sh`、`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh` 为 76 项、失败 0 项；AC-01 的变异检查；AC-06 的命令
- [ ] Task 2：配置样例、升级说明与规则
  - 对应验收：AC-02、AC-03、AC-04
  - 涉及文件：`template/harness/verify.conf`、`template/.agents/skills/upgrade.md`、`template/AGENTS.md`、`template/.agents/skills/code-review.md`
  - 验证：AC-02、AC-03、AC-04 的命令（AC-03 里「同一行」的三条用 `grep 'TARGET_FILE' template/.agents/skills/upgrade.md` 的输出再 grep）
- [ ] Task 3：README 与活文档
  - 对应验收：AC-05
  - 涉及文件：`README.md`、`docs/architecture/modules/template-mechanism.md`
  - 验证：AC-05 的命令
- [ ] Task 4：升级演练、CI 与正式验证
  - 对应验收：AC-07、AC-08
  - 涉及文件：`template/.agents/skills/upgrade.md`、`template/harness/verify.conf`（演练里发现说明不清楚才改）
  - 验证：按 AC-07 在系统临时目录演练；推送后等 CI，跑 AC-08 的命令

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/harness/redlines.conf` 第 8 行 / 注释写「同一目标连续验证失败上限」，本条把 `template/AGENTS.md` 改成「同一 Spec」后两处说法不一样 / 红线样例只允许人改，由维护者把「同一目标」改成「同一 Spec」
- 三个接入项目的 `.ai-harness/version` / 都指向历史重写前的提交，不是现在 main 的祖先，升级时基线取不到 / 各项目升级时按升级说明「取不到就当作改过」处理；对应关系只有一个项目有记录

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 1
- 已完成：需求与方案；方案审查通过，三条建议已写回方案
- 已排除的方案：恢复 `<file>` 与 `$TARGET_FILE`（维护者没选「撤回」；单个目标文件代表不了一次改动）；现在就照发 v2.2.0（维护者没选）；脚手架提供解析「涉及文件」的脚本（分派规则是项目自己的）；在 `ai-verify.sh` 里检测残留的 `TARGET_FILE`（迁移代码，见风险）
- 下一步：做 Task 1。g3 需要维护者的当次决定。归档、CI 通过后打 v2.2.0 标签并建 GitHub Release（维护者 2026-11-10 已授权）。
