# 需求：feat-t-000053

- 创建时间：2026-11-12
- **需求来源**: `process/task-pool/T-000053.md`（原始需求与更新）
- 原始问题 / 原话：「那就把建议收成spec?」（维护者 2026-11-12 对博客评估结论的答复；「建议」指 AI 评估后提出的两处，评估请求的原话和两处的出处、证据见任务文件）
- 需人决定：是。改的是规则入口：模板里什么算记忆信号（随下个版本进所有接入项目），和本仓库改接入、升级说明后怎么验证；与 feat-t-000047 同属规则的取舍，g3 要维护者看过最终措辞和演练结果后当次决定。

## 1. 要做什么
- 做什么：按博客评估的两处建议改措辞。`template/AGENTS.md` 把「审查判出的关键问题」列为记忆信号；根 `AGENTS.md` 把「改完在临时目录照着做一遍」从接入说明扩到升级说明，并写明由没参与改动的上下文来做。两处的原因写进模块活文档。
- 为谁做：接入项目里照 `AGENTS.md` 干活的 AI，审查查出的问题能留给下一次；本仓库改升级说明的 AI 和维护者，说明里的含糊在发版前被照着做的上下文发现。
- 不做：
  - 不加文件、脚本、配置键；脚本一行不改；不改门禁与红线。
  - 评估里判为不取的做法（清单见任务文件）。
  - 不改 `README.md` 对记忆的概述和 `template/.agents/skills/archive-spec.md` 第 6 行，理由见方案的「影响与风险」。
  - 不补记 feat-t-000047 那条教训进本仓库 `MEMORY.md`，不补升级演练里还没补的两处含糊：记在「发现但不碰」，由维护者决定。
  - 不打 tag，不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `template/AGENTS.md` 的记忆信号在「用户纠正」之后多一项「审查判出的关键问题」，此外一字不改，文件仍是 39 行 | `diff <(git show 7445381:template/AGENTS.md) <(sed 's/审查判出的关键问题、//' template/AGENTS.md)` 无输出；`grep -c '用户纠正、审查判出的关键问题、反复尝试才解决的问题、用户告知的关键事实，当场写进' template/AGENTS.md` 输出 1；`wc -l < template/AGENTS.md` 输出 39 |
| AC-02 | 新文字在临时项目里起作用，并和旧文字对照后如实下结论：没参与本需求的上下文以实现者身份接手一个「独立审查第一轮判出 1 个关键问题」的 Spec，用改后的 `template/AGENTS.md` 时，修完后 `MEMORY.md` 多出记这次教训的条目。同一情形用改前的文字再跑一次：旧文字下没写，结论记「有增量」；旧文字下也写了，记「无增量证据」，g3 时照此告诉维护者，不写成新信号起了作用。每种情形只跑一次，结论只作参考 | 在系统临时目录按 `template/` 建两个只差这一句的临时项目，subagent 只拿到项目路径、「先读项目根目录的 `AGENTS.md`」和「接手并推进到可以复审」；结束后看 `git -C <临时项目> diff --stat <建好时的 HEAD> -- MEMORY.md`，新文字那个有输出。两次各自的结果、新增条目原文、所用模型、subagent 是否读了临时项目的 `AGENTS.md`（没读的那次作废重跑）、对照结论，记进 tasks.md 的 WIP 区 |
| AC-03 | 新的信号不让审查者越出只读：没参与本需求的上下文以审查者身份审同一个临时项目里带着那个缺陷的改动，判出关键问题，`MEMORY.md` 不变。审查者没判出关键问题的那次作废重跑，不算通过也不算失败 | 另建一个停在「验证通过、待独立审查」的同样的临时项目（用改后的文字），subagent 只拿到项目路径、「先读项目根目录的 `AGENTS.md`」、Spec ID 与基准提交；结束后该 Spec 的 `review.md` 里「关键问题」不为 0，`git -C <临时项目> diff --stat <建好时的 HEAD> -- MEMORY.md` 无输出；结果与它是否读了 `AGENTS.md` 记进 WIP 区 |
| AC-04 | 根 `AGENTS.md` 与活文档 `install-skill.md` 都写明：改 `skill/SKILL.md` 或升级说明后，让没参与改动的上下文按它在临时目录实际接入或升级一次 | `grep -c 'upgrade.md.*让没参与改动的上下文按它在临时目录实际接入或升级一次' AGENTS.md docs/architecture/modules/install-skill.md` 两个文件各输出 1；旧句 `grep -c '按它在临时目录实际接入一次新项目' AGENTS.md docs/architecture/modules/install-skill.md` 各输出 0 |
| AC-05 | 两处的原因写进模块活文档，各一条 | `grep -c '为什么审查判出的关键问题也算记忆信号' docs/architecture/modules/guidance.md` 输出 1；`grep -c '为什么改升级说明也要演练' docs/architecture/modules/install-skill.md` 输出 1 |
| AC-06 | 不新增文件，脚本不变；自检失败 0 项，体积检查通过，正式验证通过 | `git diff --name-status 7445381 -- . ':(exclude)process'` 只有 4 行且都以 `M` 开头；`git ls-files --others --exclude-standard -- . ':(exclude)process'` 无输出；`git diff --stat 7445381 -- template/scripts scripts` 无输出；`bash scripts/harness-selftest.sh` 末尾为「失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000053` 为 PASS |
