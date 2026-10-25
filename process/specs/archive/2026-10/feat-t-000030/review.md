# 审查：feat-t-000030

- 审查者：独立 subagent（g3，Sonnet 5.5，新上下文，只读产物）
- 未参与实现：是
- CR 轮次：1 / 3
- 审查状态：e685659e496b0fc3ce8efea392f23425c86a02a9ec57ee3d50896cfd9682dae1

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：不需要
- 决策来源：requirements.md「需人决定：否」；维护者原话授权删重复、歧义交人

## 关键问题
无

## 改进建议
1. `template/AGENTS.md:33` 起 §4 与 `template/.agents/skills/archive-spec.md` 的 ai-check-bloat、start-next、reset 说明有少量重复（AGENTS 一句话、指南展开），可考虑只留指南处；不阻塞。
2. `template/AGENTS.md:9` §1.2 的 task-pool 子命令清单是唯一一份（new-spec.md 已改为引用），但 `archive-spec.md` 仍提 start-next，建议同样改为引用 §1。
3. `template/AGENTS.md:17` 的 `reset <feat> <gate> --reason` 只写子命令，字面 `ai-gate.sh reset` 仅在 archive-spec.md；可达，无需处理。
- 无遗失：`ai-new-spec`（new-spec.md）、`ai-resume.sh review`（code-review.md）、`harness-selftest`（upgrade.md、skill/SKILL.md）、`ai-check-bloat`、`ai-verify.sh`、`ai-gate.sh status`（AGENTS §2）均仍可达；§1.4 升级降级并入末行指向 upgrade.md；「门只查骗不过的信号」README:16 与 ai-gate.sh:4 仍有。
- 无矛盾：§3「与本文件其他条目重复处以它为准；有歧义或冲突时停下交人」与红线（人类才能改）、门禁、人的决定一致，歧义一律交人，不会压过红线。
- 无悬空引用：全仓无 §5、§1.4、命令速查 的引用。

## 证据
- 验证：verification.md 的 result PASS / state e685659e…
- AC-01~04：`grep -n "重复处"` 命中第 22 行；`验证：[检查]` 命中第 27 行；`grep -c "命令速查\|骗不过"` 为 0；new-spec.md Step 0 改为引用 §1。
- AC-05：未复跑自检（verification.md 记录 PASS，只读审查）。
