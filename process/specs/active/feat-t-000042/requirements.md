# 需求：feat-t-000042

- 创建时间：2026-11-05
- **需求来源**: `process/task-pool/T-000042.md`（原始需求与更新）
- 原始问题 / 原话：那就按照推荐来处理（维护者 2026-11-05 对公开化后续候选的答复；四项范围见任务文件）。
- 需人决定：否。只改自检、升级说明和接入说明，不涉及数据、权限或不可逆操作；发 v2.1.1 不在本需求内，发之前另外问维护者。

## 1. 要做什么
- 做什么：给私钥脱敏加自检断言；拆分 `upgrade.md` 第 2 步；升级时提示复议验证命令；`SKILL.md` 让 AI 读所选版本的 `upgrade.md`。
- 为谁做：接入和升级脚手架的 AI 工具，以及之后改脱敏规则的维护者。
- 不做：`README.en.md` 补无 tag 取 HEAD、1.x→2.0 删除清单、旧用户目录技能入口；不打 tag；不替项目改 `harness/verify.conf`。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 自检从 `ai-verify.sh` 的失败输出端到端断言私钥头被脱敏：输出含 `[PRIVATE KEY REDACTED]`，不含 `BEGIN`；规则失效时自检失败；模板里仍没有 PEM 头字面量 | 自检全部通过且断言数比 72 多；在临时副本里删掉 `redact` 的私钥规则后自检退出码非 0；`grep -rnE 'BEGIN (RSA \|DSA \|EC \|OPENSSH \|ENCRYPTED \|SSH2 ENCRYPTED \|PGP )?PRIVATE KEY' template` 无输出 |
| AC-02 | `upgrade.md` 的选目标版本、防降级各是独立的编号步骤，防降级步骤只讲停下条件 | `grep -nE '^[0-9]+\. .*is-ancestor' template/.agents/skills/upgrade.md` 命中一行，同行不含 `fetch --tags` 和 `机制文件` |
| AC-03 | `upgrade.md` 有一步要求核对 `CUSTOM_CHECK` 能否证明行为，不能的列给人决定，AI 不改 `harness/verify.conf` | `grep -n '能证明行为' template/.agents/skills/upgrade.md` 命中，同行含 `CUSTOM_CHECK` 与 `交人决定` |
| AC-04 | `SKILL.md` 让已接入项目读所选版本的 `upgrade.md`，新项目接入流程仍可用 | `grep -n 'show <版本>:template/.agents/skills/upgrade.md' skill/SKILL.md` 命中；按 `skill/SKILL.md` 在临时目录接入一次新项目，自检通过 |
| AC-05 | 正式验证通过 | `bash scripts/ai-verify.sh --spec feat-t-000042 template/scripts/harness-selftest.sh` 为 PASS |
