# 代码审查报告 (Code Review): feat-t-000012

我没写过这段代码，只依据下面产物判断。

- **审查者**：Claude Code G5 独立审查 subagent（Opus 5.5，新上下文，只读）
- **未参与实现**：是
- **审查时间**：2026-10-23（第 1 轮；第 2 轮增量复审同日）
- **审查范围**：`git diff 2800a1e...HEAD`（`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh` 与本 Spec 文档）；工作区与暂存区无改动；对应 design.md §4 文件清单
- **CR 轮次**：2 / 4
- 审查状态：8d4fefda3fa031b704ec91b39a8e270b386dbd2d226e36cbf4e13a6aa74df017

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：第 1 轮 3 条已处理；第 2 轮新增 1 条
- 判定：通过（第 2 轮复审）

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无

## 改进建议（非阻塞，"改善即批准"）
1. `template/scripts/ai-gate.sh:86` 注释说「直接读文件、不走上面两层的入口各自归一」只列了会自己归一的三处（247、431、472 行），这三处都列对了。但它没提到另一些直接读文件、也完全不做归一的入口：`quadrant()`（50 行）、`trace_requirement_ids`（242 行）、G6 的 `ac_ids`（487 行），以及 ck_g5 里直接对 `$f` 的 grep。读者可能误以为直接读文件的入口都已覆盖。建议补一句「其余直接读文件的匹配未归一」，或者把这几处记进任务池。
2. AC-03 的实际现象和实现方的说法不同。我在沙箱里删掉 `field_ok` 第 110 行的 `s/　/ /g` 后，新用例的场景不是「改报下一项缺失」，而是 G1 整体通过（exit 0）。用例仍会以「本应被拒，实际 exit 0」报出，所以守护有效。只是任何地方引用这个结论时都应改成实际现象。
3. `tasks.md` §4 WIP 的「下一步立即执行的唯一动作：在 section_body 与 field_ok 处加注释」已经过时，注释已经加上了。另外 requirements §1 和 design §4 引用的「第 150、158、163 行」是基线 2800a1e 的行号，加注释后变成 157、165、170 行。归档时应同步修正。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地门禁脚本，无用户身份 |
| 鉴权中间件 | 不适用 | 无路由 |
| SQL 参数化 | 不适用 | 无查询 |
| 无敏感信息硬编码 | ✅ | diff 只有注释和一条自检用例 |
| 入参边界校验 | 不适用 | 判定代码未改，见 `git diff` 中非注释行为 0 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01 / AC-01 对应 `ai-gate.sh:81-86` 和 `:108`。我用 `grep -n "s/　/ /g\|gsub(\"　\""` 查到 7 处归一（76、94、110、119、247、431、472 行），与注释对得上。`field_ok` / `field_value` 全部调用点中，接收原文的是 157、165、170 行，对应注释写的「原始问题、象限行、分级依据」；其余调用点传的是 section_body 输出，或已归一的 nv（454、517 行）。76 行的委托字段经 section_body，又自己再归一一次，属于冗余但无害。ERR-01 / AC-02 对应 `harness-selftest.sh:348-349`。AC-03 已在沙箱复核：原脚本下拒绝；删掉第 110 行归一后 G1 exit 0，用例因此报出。AC-04：ai-gate.sh 的 diff 里非注释行为 0；`ai-gate.sh check feat-t-000012 g4` 通过。t-noorigin 只在 345-349 行使用，用例追加的行在文件末尾，不影响后续用例。没有发现超纲实现。
- 知识检索：`.knowledge/INDEX.md` 中 K-0001（全角空格先归一，不强制 LC_ALL）与本变更一致，已采用。没有发现与代码矛盾的卡片。
- AI 协作文件审查：本次 diff 只改了门禁脚本 `template/scripts/ai-gate.sh`（仅注释）和自检脚本。没有改 AGENTS.md、Skill 或知识卡；注释里没有私有调试信息。
- 审查范围限制：没有跑全量自检，只在沙箱里用自检夹具复现了 t-noorigin 场景（原脚本与删掉归一的变体）。全量自检的结果以实现方的 verification 为准。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000012 template/scripts/ai-gate.sh` → result PASS / checks 1 / state 7994d969…；`ai-gate.sh check feat-t-000012 g4` 通过，摘要未过期
- 沙箱（selftest 前 261 行夹具 + mk_spec）：原脚本 `LC_ALL=C` G1 → rc=1「原始问题 / 原话未填」；删掉 `ai-gate.sh:110` 的 `s/　/ /g` 后 → rc=0（G1 通过），新用例会报 NG

knowledge_feedback: 无

## 第 2 轮增量复审（范围：`git show 1babd0f` + 工作区 `.gates` / `verification.md`）
- 上轮建议 1：已处理。`git show HEAD -- template/scripts/ai-gate.sh` 只改了第 85~87 行的注释；`git diff 2800a1e...HEAD -- template/scripts/ai-gate.sh` 里非注释行为 0，判定代码未动。
- 上轮建议 2：可以接受。两种夹具下现象不同（最小夹具没有象限行，改报象限缺失；完整夹具下 G1 exit 0），但用例都会报出。acceptance.md 如实写明两种现象即可。
- 上轮建议 3：已处理。requirements §1、design §4、tasks §4 的固定行号已改成按调用描述，WIP 已更新。
- 增量其他内容：`.violations` 记录了 g4 reset，原因写明是 G5 第 1 轮；之后重新做了正式验证，`ai-gate.sh check feat-t-000012 g4` 通过，state 8d4fefda… 与 verification.md 一致。第 1 轮 review.md 被一并提交，正文没有被改动。
- 新增改进建议 4（非阻塞）：`ai-gate.sh:86-87` 说 quadrant、trace_requirement_ids、ac_ids「不做空白判断，无需归一」，这个说法不严谨。这三处的正则或 trim 都依赖 `[[:space:]]` / `[ \t]`。我在沙箱里复核：把列表符后的空格换成全角空格后，`quadrant()` 取不到象限，REQ 行和表格单元格里的 AC 编号也会被漏掉。端到端看，② 夹具 G1 能通过，但 G3 会报「需求象限无效」，属于误拒、不放行；trace 和 G6 的 ac_ids 漏掉部分编号时，校验会变松。这些都是基线已有的行为，不是本次 diff 引入的。建议把注释改成「这些入口目前未归一，列表符或单元格边界用全角空格会漏匹配；象限漏匹配时误拒，编号漏匹配时校验变松」，并把它收进任务池，不在本 Spec 扩范围。
- 第 2 轮结论：关键问题 0，判定通过。
