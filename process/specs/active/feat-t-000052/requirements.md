# 需求：feat-t-000052

- 创建时间：2026-11-10
- **需求来源**: `process/task-pool/T-000052.md`（原始需求与更新）
- 原始问题 / 原话：先补小 Spec 再发（维护者 2026-11-10 在「发版怎么走」里选的。背景：维护者授权打 v2.2.0 标签并让查接入项目的 `harness/verify.conf`；查出几个接入项目的 `CUSTOM_CHECK` 都靠 `$TARGET_FILE` 分派增量检查，其中一个升级后会落到默认分支、只跑脚手架自检就 PASS。选项的原文是：导出 `SPEC_NAME` 让检查脚本按 Spec 的「涉及文件」分派；`verify.conf` 样例和升级说明第 6 步写明两条迁移路并点名默认分支悄悄放行的情形；改正活文档；顺带并入第 6 步措辞、「同一 Spec」、自检的 CRLF 警告。做完再打 v2.2.0）
- 需人决定：是。给检查命令新增一个公开的变量 `SPEC_NAME`（契约），并改升级指引里交人决定的内容。

## 1. 要做什么
- 做什么：`ai-verify.sh` 把 `SPEC_NAME` 导出给检查命令；`verify.conf` 样例和升级说明第 6 步写明去掉 `$TARGET_FILE` 之后的两条路（整项目命令，或按 Spec 的「涉及文件」分派）和「按空变量分派会悄悄通过」的风险；改正活文档里「选哪个文件都不影响查什么」这句不成立的话；规则里不再说检查一定对整个项目生效，「同一目标」改成「同一 Spec」；自检在 Git Bash 下不再打印 CRLF 警告。
- 为谁做：已接入、靠 `$TARGET_FILE` 分派增量检查的项目，和替它们升级的 AI。`feat-t-000050` 去掉了这个变量，规划时把「接入项目有没有用它」记成未知，按「升级时改一行」估的。2026-11-10 核对到的三个接入项目都在用，而且是拿它决定跑哪些检查：整项目检查对它们太慢，或要外部数据库。升级后变量为空，两个会明着失败，一个会落到默认分支、只跑脚手架自检就通过。
- 不做：
  - 不在 `ai-verify.sh` 里检测 `CUSTOM_CHECK` 是否还含 `TARGET_FILE`：这是迁移代码，本仓库的约定是升级写成说明、不写兼容或迁移代码。代价是悄悄通过这种情形只靠升级第 6 步拦，写在方案的风险里，由维护者在 g3 时一并决定。
  - 不提供解析「涉及文件」的公共脚本：怎么分派是各项目自己的规则。
  - 不恢复 `<file>` 参数和 `$TARGET_FILE`。
  - 不改 `skill/SKILL.md`：新接入默认仍是一条整项目命令，替代做法写在 `verify.conf` 样例的注释里。
  - 不改 `template/harness/redlines.conf`（只允许人改）：第 8 行注释里的「同一目标」留给维护者。
  - 不动任何接入项目。
  - 两轮审查里其余的改进建议不做：指纹守卫在 `.git` 目录内部放行、临时目录在 Git 工作区里时断言误报、提醒升级后重跑验证、升级第 4 步的换行符。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 检查命令运行时能读到 `SPEC_NAME`，值是当前 Spec 名 | 自检新增断言「检查命令能读到 Spec 名」通过：夹具是单引号写的 `CUSTOM_CHECK='test "$SPEC_NAME" = t-verify'`，只有运行时环境里有这个变量才成立；变异检查：临时去掉 `ai-verify.sh` 里的 `export` 重跑，只有这一条失败，然后恢复，结果记进 tasks.md 的 WIP 区 |
| AC-02 | `verify.conf` 样例写明：默认是一条整项目命令；整项目检查跑不动的，按 `$SPEC_NAME` 读该 Spec 的「涉及文件」挑检查，没有对应检查的文件必须失败 | `grep -c 'SPEC_NAME' template/harness/verify.conf` 输出 1；`grep -c '必须失败' template/harness/verify.conf` 输出 2（原有「零用例时必须失败」一处，新增一处） |
| AC-03 | 升级说明第 6 步写明：`CUSTOM_CHECK`、它调用的项目脚本或 `verify.conf` 的注释里还有 `$TARGET_FILE` 的，变量为空时可能落到默认分支、什么都没查就通过；两条建议（整项目命令，或按 `$SPEC_NAME` 读「涉及文件」分派）；交人决定 | `grep -c 'TARGET_FILE' template/.agents/skills/upgrade.md` 输出 1；同一行里 `grep -c 'SPEC_NAME'`、`grep -c '默认分支'`、`grep -c '它调用的项目脚本'` 各输出 1；`grep -c '文件注释' template/.agents/skills/upgrade.md` 输出 0 |
| AC-04 | 规则不再说检查一定对整个项目生效；连续失败按 Spec 计的说法与脚本、README 一致；`template/AGENTS.md` 行数不变 | `grep -c '对整个项目生效' template/AGENTS.md template/.agents/skills/code-review.md` 两个都输出 0；`grep -c '同一目标' template/AGENTS.md` 输出 0，`grep -c '同一 Spec 连续验证失败' template/AGENTS.md` 输出 1；`wc -l < template/AGENTS.md` 输出 39 |
| AC-05 | README 的配置表写明检查命令可用 `$SPEC_NAME`；活文档不再说「选哪个文件都不影响查什么」，写明为什么去掉目标文件的同时导出 `SPEC_NAME` | `grep -c 'SPEC_NAME' README.md` 输出 1；`grep -c '选哪个文件都不影响查什么' docs/architecture/modules/template-mechanism.md` 输出 0；`grep -c '为什么正式验证不带目标文件、却导出' docs/architecture/modules/template-mechanism.md` 输出 1 |
| AC-06 | 自检在 Git Bash 下不再打印换行转换的警告（改动前一次运行有 25 行） | `bash scripts/harness-selftest.sh 2>&1` 的输出里 `grep -c 'LF will be replaced by CRLF'` 输出 0 |
| AC-07 | 升级演练走得通：在系统临时目录按 v2.1.4 装一个项目，`CUSTOM_CHECK` 按 `$TARGET_FILE` 分派、默认分支直接成功；让没有上下文的 subagent 只凭升级说明升到本 Spec 的提交。它在第 6 步列出这一行，说明变量为空时会走到默认分支通过，给出建议并且自己不改。再按 `verify.conf` 样例的说法把检查改成按 `$SPEC_NAME` 读「涉及文件」分派：涉及文件都有对应检查的 Spec 正式验证 PASS，涉及文件里有一个没有对应检查的文件时 FAIL | 演练的命令、subagent 交出的原话摘要和两次正式验证的结果记进 tasks.md 的 WIP 区 |
| AC-08 | 自检 76 项断言、失败 0 项（现在 75 项，加 AC-01 的 1 项）；推送后 CI 两个任务成功；体积检查通过；正式验证为 PASS | `bash scripts/harness-selftest.sh` 末尾输出「76 项断言，失败 0 项」；`gh run view <run-id> --json jobs --jq '.jobs[].name, .jobs[].conclusion'` 输出两个任务名和两个 `success`，`--log` 里两处「76 项断言，失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000052` 为 PASS |
