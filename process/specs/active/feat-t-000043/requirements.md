# 需求：feat-t-000043

- 创建时间：2026-11-05
- **需求来源**: `process/task-pool/T-000043.md`（原始需求与更新）
- 原始问题 / 原话：开始（维护者 2026-11-05 对升级流程后续建议的答复；三条范围见任务文件）。
- 需人决定：否。只改升级说明的文字，不涉及数据、权限或不可逆操作；发 v2.1.2 不在本需求内，发之前另外问维护者。

## 1. 要做什么
- 做什么：在 `upgrade.md` 加三句：选定目标版本后先读该版本的说明；用 `git diff` 查 redlines 模板的新键新值；`.gitattributes` 只补缺的行。
- 为谁做：在已接入项目里照项目那份说明升级脚手架的 AI 工具。
- 不做：自检里失败命令跑两次、`SKILL.md` 降级到没有 `upgrade.md` 的版本；不打 tag；不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 第 2 步要求选定目标版本后读该版本的说明，有差异时按它做，取不到时按本文件继续 | `grep -nE '^2\. .*show <目标提交>:template/.agents/skills/upgrade.md' template/.agents/skills/upgrade.md` 命中，同行含 `按它做` 与 `取不到`；在临时克隆里运行该 `git show` 取到 `v2.1.1` 的说明 |
| AC-02 | 第 5 步写明用 `git diff` 比较 `.ai-harness/version` 的提交和目标提交的 `template/harness/redlines.conf`，有差异就列给人 | `grep -n 'template/harness/redlines.conf' template/.agents/skills/upgrade.md` 命中，同行含 `git -C <脚手架仓库> diff` 与 `列给人`；在临时克隆里给该模板加一个新键并提交，该命令输出这个新键 |
| AC-03 | 第 5 步写明 `.gitattributes` 与 `.gitignore` 都只补缺的行 | `grep -n '只补缺的行' template/.agents/skills/upgrade.md` 命中，同行含 `.gitattributes` 与 `.gitignore` |
| AC-04 | 正式验证通过 | `bash scripts/ai-verify.sh --spec feat-t-000043 template/.agents/skills/upgrade.md` 为 PASS |
