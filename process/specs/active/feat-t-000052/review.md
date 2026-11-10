# 审查：feat-t-000052

- 审查者：独立审查上下文（subagent，未参与实现），模型 Sonnet 5.5
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：d220ca5e7a49dbdfb469313aeec6a921206ad4c006439cd76ec4c9a5664a3bde
- 审查范围：ad944f8...HEAD + 工作区（代码变更都在 7d7a5a9 及之前，之后只动 `process/`）

## 结论
- 总评：通过
- 关键问题：0
- 改进建议：3
- 人工决定：通过
- 决策来源：对话（2026-11-10）。实现者把结果（自检 76 项、CI 两个任务成功、正式验证 PASS、升级演练走通、独立审查关键问题 0）和风险（按文件分派的依据挪到 tasks.md 的「涉及文件」，漏写就漏查；空变量悄悄通过的情形只靠升级第 6 步拦；`SPEC_NAME` 成为公开契约；红线样例第 8 行要维护者自己改）讲给维护者，并问要不要在 `ai-verify.sh` 里加检测残留 `TARGET_FILE` 的代码。维护者选的是「通过，不加检测」。这两行由实现者按维护者的原话填写，其余内容是审查者写的。

## 关键问题
无

## 改进建议
1. `template/harness/verify.conf:2` 只说「读涉及文件挑检查」，没说取法（tasks.md 里「涉及文件」行的反引号路径）；这层只写在 `upgrade.md:14`。新接入项目不走升级说明，可能各猜各的。补半句即可。
2. `template/harness/redlines.conf:8` 仍是「同一目标」，与规则、README 的「同一 Spec」不一致；需求已明确留给维护者，只是提醒别漏。
3. 升级说明第 6 步一句话塞了三层意思（找残留、两条路、不可信），偏长；可读性问题，不必改。

## 证据

### 验收标准逐条（我自己重跑）
- AC-01：`ai-verify.sh:11` 为 `export SPEC_NAME="$2"`；夹具 `harness-selftest.sh:243` 用 `printf "...'test \"\$SPEC_NAME\" = t-verify'..."`，落盘是单引号 `$SPEC_NAME`，source 时不展开，只有运行时环境里有该变量才成立；变量缺失时 `test "" = t-verify` 为假，所以是真断言。变异检查（去掉 export 只失败这一条）我没重跑，未能核实，只按机理判断成立。
- AC-02：`grep -c SPEC_NAME template/harness/verify.conf` 输出 1；`grep -c 必须失败` 输出 2。
- AC-03：`grep -c TARGET_FILE template/.agents/skills/upgrade.md` 输出 1（第 14 行）；该行含 SPEC_NAME、默认分支、它调用的项目脚本；「文件注释」已无。
- AC-04：`wc -l < template/AGENTS.md` 输出 39；「对整个项目生效」在 AGENTS.md、code-review.md 里已无；全仓搜「同一目标」只剩 `redlines.conf:8`（见建议 2）。
- AC-05：README 的 SPEC_NAME 计数 1；活文档 `template-mechanism.md:9` 换成新标题，旧句已无。
- AC-06、AC-08：我跑 `bash scripts/harness-selftest.sh`，末尾「76 项断言，失败 0 项」，输出里 `LF will be replaced` 为 0，以 warning 开头的行为 0。`ai-check-bloat.sh` 通过。`gh run view 42849798560`：`headSha` 为 7d7a5a9，两个任务 success，日志里「76 项断言」2 处、换行警告 0 处。
- AC-07（升级演练）：未能核实，已做完且在系统临时目录，我没有复现。我对说明文字本身的判断：`upgrade.md:14` 现在点名了三处残留位置、默认分支悄悄通过的后果、两条建议、`$SPEC_NAME` 的来源与取法、「必须失败」和交人决定，自洽，足以让没有上下文的人照做。tasks.md 记录的细节（旧版下选 `docs/notes.md` 通过、新版空变量落默认分支）与说明的因果链一致。

### 特别留意项
- 导出变量的安全与副作用：`export` 在第 11 行，校验在第 12 行，非法名会 `exit 1`，检查命令跑起来时值只含 `[A-Za-z0-9._-]`，无注入面；`template/scripts/` 里没有别处读环境里的 `SPEC_NAME`（grep 只有 ai-verify.sh 自己和自检）。唯一副作用是覆盖调用环境或子进程里同名变量，方案已写。检查命令之外的误用：导出后检查命令启动的任何子进程都能看到，这是预期。
- 自检里的 Git 配置那行（`harness-selftest.sh:9`）：只设 `core.autocrlf=false`。自检里没有任何断言涉及换行、`autocrlf` 或 CRLF（grep 无命中），沙箱文件全是 LF，所以没有改变断言的含义，只去掉警告。局限：覆盖调用方自己设的 `GIT_CONFIG_COUNT`，只影响自检进程；Git 低于 2.31 时警告回来，断言不受影响，方案已写。
- 新断言：真断言（见 AC-01）；它放在「g2 接受真实生成的摘要」之后、连续失败三条之前，且随后 `CUSTOM_CHECK='false'` 重写夹具，不污染失败计数。
- 实现与方案的差异：第 6 步比方案多了「`ai-verify.sh` 导出的当前 Spec 名」括注和「tasks.md 里…行的反引号路径」，tasks.md WIP 区写明了原因（演练暴露），已交代清楚。
- 漏改检查：`README.en.md`、`skill/SKILL.md`、`MEMORY.md`、`docs/architecture/decisions/` 里没有 `TARGET_FILE` 或「目标文件」的残留表述；`00-INDEX.md` 指向的活文档只有 `template-mechanism.md` 受影响且已改。没有互相矛盾的句子。

### 「需人决定：是」的判定
判对。依据 `new-spec.md` Step 1 第 3 点：新增公开变量 `SPEC_NAME` 是架构与契约取舍（以后改名就是破坏性变更），并改变升级时交人决定的内容；这不是纯内部实现。

### 给维护者的风险提示
最该知道的：这次是把「按文件分派」的口子从目标文件挪到 tasks.md 的「涉及文件」。实现者自己写这一栏，漏写就漏查，兜底只有独立审查对照 diff 和「没有对应检查必须失败」这条写在样例里的约定，脚手架没有机械拦截。其次，升级后悄悄通过的情形（空变量落默认分支）仍只靠升级第 6 步被执行；已升级但还没人读第 6 步的项目，在发 v2.2.0 之后会一直 PASS 而什么都没测。

### 对「不在 `ai-verify.sh` 里检测残留 `TARGET_FILE`」的看法
同意不加。依据：一是与本仓库「升级写成说明、不写迁移代码」的约定一致，升完全部项目就成死代码；二是只认得出 `CUSTOM_CHECK` 字面里的名字，经项目脚本间接读取的拦不住（方案已说明），给人以已有保护的错觉。若想降低发版风险，更合适的办法是在 v2.2.0 发布说明里把这条升级动作点名，而不是改脚本。最终由维护者决定。

### 未能核实
- AC-01 的变异检查与 AC-07 的升级演练（均为已完成的临时目录操作，未重做）。
- 三个接入项目的现状（不在本仓库，按要求没找）。
