# 审查：feat-t-000029

- 审查者：独立 subagent g3 / Claude Sonnet 5.5 / 新会话（我没写过这段代码，只依据产物判断）
- 未参与实现：是
- CR 轮次：1 / 3
- 审查状态：e937288db7f488377102836e4e1761f146dde325aa639d176ff6ad6ee04f3396

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：不需要
- 决策来源：requirements.md「需人决定：否」

## 关键问题
无。（流程前置条件：提交后当前状态指纹为 e937288d…，与 verification.md 的 378ca3a8… 不一致，门禁报「验证已失效」；实现者需重跑 ai-verify.sh 后再过 g3，非代码缺陷。）

## 改进建议
1. template/AGENTS.md:24「与本文件其他条目重复或冲突时以它为准」范围过宽，字面上可压过 §2 红线/三道门与 §3 停下等人；建议限定为“编码行为条目”。
2. template/AGENTS.md:29 原文计划格式是三行 `1. [Step] → verify: [check]` 示例，译文只用一句描述，AC-01「计划格式」勉强满足；可补一行示例。
3. template/AGENTS.md:19 / :42-49 仍与正文重复（已记 tasks.md「发现但不碰」），非本需求范围。

## 证据
- 验证：verification.md result PASS，state 378ca3a8…（当前指纹已变，见上）
- AC-01 逐句对照 karpathy-CLAUDE.md：开头取舍说明(24)、四条标题句与全部要点(26-29)、自问句(27)、检验标准(28)、三个目标示例(29)、计划格式(29)、成功标准说明(29)、结尾生效标志(31)均有，译文忠实；“Merge with project-specific instructions”落为 :24 冲突规则。
- AC-02：AGENTS.md 无「范围纪律」「关键路径先测」「简单优先」旧条；停下等人保留(35)。
- AC-03：code-review.md:15 含「每一行改动都能直接对应到需求」；README.md:31 含出处与 MIT。
- 其余 skills（new-spec.md 等）未发现与四原则矛盾或重复。AC-04 未由我重跑。
