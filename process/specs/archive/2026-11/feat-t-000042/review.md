# 审查：feat-t-000042

- 审查者：独立审查上下文 / Claude Sonnet 5.5 / 子代理会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：5acd7225fa1f38124049b7d584af326e0296d6619ed63308fa109f6181bf1dce
- 审查范围：v2.1.0...HEAD + 工作区（工作区干净）

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不需要
- 决策来源：requirements.md「需人决定：否」；改动只涉及自检、升级说明与接入说明，不涉及数据、权限或不可逆操作，复核后认同

## 关键问题
无

## 改进建议
1. `template/scripts/harness-selftest.sh:250-251`：脱敏断言先在 249 行跑一次、250 行再跑一次 `ai-verify.sh` 取输出，两次都累计失败次数（`t-redact` 共 2 次，未到第 3 次黄卡，目前无影响）。可只跑一次，把输出同时用于两条断言；以后若有人给该 Spec 再加一次失败运行就会触发黄卡，干扰断言。不阻塞。
2. `skill/SKILL.md:15`：降级到没有 `upgrade.md` 的更早版本时，`git show <版本>:template/.agents/skills/upgrade.md` 会失败，文中没写失败时怎么办。现有 tag（v2.1.0）都含该文件，暂不触发；若要处理，加半句「取不到就用工作区的 upgrade.md 并告知人」即可。不阻塞。

## 证据
- 验证：verification.md 的 result: PASS，state 与上方一致（`.gates` 显示 g1、g2 已通过）。
- AC-01：`bash scripts/harness-selftest.sh` 为「74 项断言，失败 0 项」（多于 72）；在临时副本里删掉 `ai-verify.sh` 的私钥脱敏规则后自检退出码 1，失败 2 项（「失败输出脱敏私钥头」「失败输出残留私钥头」）；`grep -rnE 'BEGIN (RSA |DSA |EC |OPENSSH |ENCRYPTED |SSH2 ENCRYPTED |PGP )?PRIVATE KEY' template` 无输出。
- AC-02：`upgrade.md:6` 是编号的防降级步骤，命中 `is-ancestor`，同行不含 `fetch --tags` 与 `机制文件`；选版本在第 2 步，机制文件比对在第 4 步。
- AC-03：`upgrade.md:13` 同行含「能证明行为」「CUSTOM_CHECK」「交人决定」，并写明不要自己改；`verify.conf` 仍在第 5 步「不动项目状态」之列。
- AC-04：`skill/SKILL.md:15` 命中 `show <版本>:template/.agents/skills/upgrade.md`；按 SKILL.md 在系统临时目录按本提交模板接入新项目（写 `.ai-harness/version`、配置检查命令、提交）后，`ai-check-bloat.sh` 与 `ai-gate.sh status` 正常，`harness-selftest.sh` 为 74 项失败 0 项；临时目录已删除。
- AC-05：verification.md 为 PASS。
- 范围：diff 只涉及自检、`upgrade.md`、`SKILL.md`、`install-skill.md` 活文档、任务与 Spec 文件，无超出需求的行为；活文档新增两条理由与改动一致，未与 MEMORY.md 已记录的规则冲突。
