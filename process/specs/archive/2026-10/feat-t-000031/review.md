# 审查：feat-t-000031

- 审查者：独立 subagent（Claude Sonnet 5.5，新会话，只读产物）
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：8041904969433ce27ff5f60d0c82c2a395746bb133e2adf5ef2af9e836df5586

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：不适用（需人决定：否）
- 决策来源：不适用

我没写过这段代码，只依据产物判断。

## 关键问题
无

## 改进建议
1. `template/AGENTS.md:31` 的「二者不一致以原文为准并告诉人」与 `template/AGENTS.md:22`「有歧义或冲突时停下，把两边说法讲清楚交给人决定」语义重叠。可只留「以原文为准」，删「并告诉人」以省字；不阻塞。
2. `template/harness/verify.conf:3` 举例写死 pytest 退出码 5，是单一工具经验；其他运行器（jest `--passWithNoTests` 等）行为不同。可改成不举具体工具，避免被读成通用结论。不阻塞。
3. `ai-gate.sh` g1 只查 `Task` 行（`template/scripts/ai-gate.sh:67`），「对应验收」纯靠自觉、无机械校验，符合「不加脚本」的需求，但 AC-01 的约束力仅限文字；接受即可，如反复漏写再考虑检查。

## 证据
- 验证：verification.md 的 result: PASS / state: 8041904969433ce27ff5f60d0c82c2a395746bb133e2adf5ef2af9e836df5586
- AC-01~05：diff 中 `template/process/specs/_templates/tasks.md:14`、`template/AGENTS.md:31,39`、`template/.agents/skills/new-spec.md:21`、`code-review.md:19,23`、`verify.conf:3` 均有对应改动，grep 可命中。
- AC-06：`git diff --stat` 共 5 文件 +8/-6；`template/AGENTS.md` 为 2 行修改、净增 0（≤2）；`bash scripts/harness-selftest.sh` 67 项断言失败 0。
- 无矛盾：README.md、skill/SKILL.md 未出现「对应验收」措辞；g1 仅匹配 `[ ] ...Task` 行，新增子项不影响；自检模板用例不受影响。
- 无超范围：未新增脚本、配置键、文件，`redlines.conf` 未改。
