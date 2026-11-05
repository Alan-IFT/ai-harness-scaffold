# 需求：feat-t-000044

- 创建时间：2026-11-05
- **需求来源**: `process/task-pool/T-000044.md`（原始需求与更新）
- 原始问题 / 原话：这样会不会太麻烦，最好的就是，我直接给AI一句话，让AI升级到最新版，最好readme里也有这么一句话，方便用户复制粘贴使用
- 需人决定：否。只改接入与升级的说明和 README，不涉及数据、权限或不可逆操作；发新版本不在本需求内，发之前另外问维护者。

## 1. 要做什么
- 做什么：README 放一句可复制的话，新项目、老项目、升级都用它，用户不用手动克隆；AI 自己把脚手架克隆到临时目录，用完删除；已接入项目的 `upgrade.md` 写上仓库地址，之后只说「把脚手架升级到最新版」也能升级。
- 为谁做：第一次接入和以后升级脚手架的用户。
- 不做：CLI 或安装脚本；在公开仓库记录旧提交号的对应关系；改接入项目；不打 tag。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `README.md` 与 `README.en.md` 各有一个可复制的代码块，内容是一句话，含克隆地址和 `skill/SKILL.md`；不再要求用户手动克隆或提供路径才能开始 | 两个文件的「开始」小节代码块只有这一句，都含 `https://github.com/Alan-IFT/ai-harness-scaffold.git` 与 `skill/SKILL.md`；`README.md` 不再含 `必须用` 与 `D:\code`，`README.en.md` 不再含 `A ZIP download` |
| AC-02 | `skill/SKILL.md` 要求脚手架是完整克隆，浅克隆先补全；为本次临时克隆的脚手架结束后删除 | `grep -n 'is-shallow-repository' skill/SKILL.md` 与 `grep -n '临时克隆' skill/SKILL.md` 都命中 |
| AC-03 | `upgrade.md` 写明脚手架仓库的地址：人给了本机路径就用它，否则完整克隆到临时目录，用完删除 | `grep -n 'github.com/Alan-IFT/ai-harness-scaffold.git' template/.agents/skills/upgrade.md` 命中，同行含 `临时目录` |
| AC-04 | 没看过本需求讨论的 AI 只拿到 README 这句话，能给空目录接入脚手架 | 独立审查者在临时目录实测：`.ai-harness/version` 为最新 tag 的提交，自检通过，临时克隆已删除 |
| AC-05 | 没看过讨论的 AI 拿到这句话，能升级带定制的老项目 | 临时项目升到最新 tag，定制保留，状态文件没动，自检通过，临时克隆已删除 |
| AC-06 | 没看过讨论的 AI 在已带新版说明的项目里只听到「把脚手架升级到最新版」，能完成升级 | 临时项目升到最新 tag，自检通过，临时克隆已删除 |
| AC-07 | 正式验证通过 | `bash scripts/ai-verify.sh --spec feat-t-000044 skill/SKILL.md` 为 PASS |
