# 审查：feat-t-000053

- 审查者：独立审查上下文 / Claude Sonnet 5.5 / 新会话（只读）
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：74e74554e344e3c70a212d25fb3ea44102dd02342eacdbde6f51da805eaf5db5
- 审查范围：7445381...HEAD + 工作区（工作区干净，无未跟踪文件）

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：<待维护者当次决定>
- 决策来源：<待维护者当次决定>

需求里「需人决定：是」，我同意这个判断（改的是随版本进所有接入项目的规则入口）。请维护者重点看两件事：
1. AC-02 的对照结论是「无增量证据」：旧文字下这个模型也自己写了 `MEMORY.md`。模板那 10 个字没有被证明起了作用，只证明它没有害处（审查者没越界）。tasks.md 里起草者自己也倾向撤掉这一处。留或撤由人定。
2. 演练约定变重：以后改 `upgrade.md` 或 `skill/SKILL.md` 一字之改也要换上下文演练，成本是否接受由人定。

## 关键问题
无。

## 改进建议
1. `docs/architecture/modules/install-skill.md` 新增条目写「feat-t-000050、feat-t-000052 的升级演练暴露的 5 处含糊，都是没参与的 subagent 照着做时才显出来的」。我只在 feat-t-000052 的 tasks.md 第 85 行核到演练暴露的 2 处；feat-t-000050 的 tasks.md 第 33 行是审查指出的一处，不是演练暴露的。「5」与「都是 subagent 演练」我没能从归档里凑齐，建议核对或把数字写成可查的说法（活文档是给后人看的，写错来源会误导）。
2. `docs/architecture/modules/guidance.md` 新条目写「实现者的盲区只能等下次审查再撞上」，并把 feat-t-000047 一例作依据；而本次演练对照显示旧文字下模型也会自己记。这条「为什么」没提这一反证。若保留这一处，建议补半句「演练中旧文字下也写了，增量未证实」，免得活文档把推断写成定论。
3. 模板新增的 10 个字没有写明由谁写（实现者在修复时记）。演练中审查者没越界，但只有一次、一个模型。若后续出现审查者自己改 `MEMORY.md` 的情况，按 tasks.md 方案里留的第一条路（句子里写明由实现者修复时记）处理。不阻塞。

## 证据
- 验证：verification.md 的 result PASS / state 74e74554...（与上方一致）；`ai-gate.sh status` 显示 g1、g2 已过，g3 待审。我没重跑 `ai-verify.sh`（按约束不得运行），状态指纹未重算。
- AC-01：`diff <(git show 7445381:template/AGENTS.md) <(sed 's/审查判出的关键问题、//' template/AGENTS.md)` 无输出；目标句 grep 为 1；`wc -l` 为 39。通过。
- AC-04：新句在 `AGENTS.md:11` 与 `install-skill.md` 各 1 处，旧句各 0 处。通过。
- AC-05：两条「为什么」标题各存在（见 diff：`guidance.md` 第 10 行、`install-skill.md` 倒数第二行）。通过。
- AC-06：`git diff --name-status 7445381 -- . ':(exclude)process'` 只有 4 行 M（`AGENTS.md`、`guidance.md`、`install-skill.md`、`template/AGENTS.md`）；未跟踪文件无；`template/scripts`、`scripts` 无改动。自检与体积检查我没重跑（会写文件的风险未评估，按约束不跑），采信 tasks.md 记录。
- 范围：完整 diff 只含上述 4 个文件和 process 记录，没有超出需求的行为。`README.md`、`archive-spec.md` 不改的理由成立（摘要性文字，没有与新句矛盾）。`MEMORY.md` 与 `code-review.md` 第 53 行「审查者只读」与新句不矛盾。
- AC-02（系统临时目录里的演练项目，只读核对）：
  - 新旧两个实现者项目的 `AGENTS.md` 只差这 10 个字；新文字项目的 `AGENTS.md` 与当前 `template/AGENTS.md` 完全一致。
  - 新文字项目：`git diff --stat <初始提交> -- MEMORY.md` 为 1 行新增，条目原文与 tasks.md 记录一致，在修复提交之后有 g2 重跑提交。
  - 旧文字项目：同命令为 1 增 1 删，确有一条 BOM 条目。「无增量证据」的结论与实物一致，没有被写成「有增量」。
  - 局限：各一次、同一模型；两个项目的初始提交哈希各异，我是用各自第一个提交作基准核对的。我无法核实 subagent 是否真的读了 `AGENTS.md`，只能采信其自述；条目措辞「按 AGENTS.md 要求」与读过一致。
- AC-03（系统临时目录里的审查项目）：`review.md` 的「关键问题」为 1（BOM 缺陷，`bin/count.sh:6` 输出 4，期望 3），改进建议 2；`git status` 只多出 `review.md` 一个未跟踪文件，`MEMORY.md` 相对初始提交无差异，没有新提交。通过。这条的区分度有限（审查者本来就该只读），方案已承认。
