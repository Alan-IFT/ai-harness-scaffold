# 审查：feat-t-000043

- 审查者：独立 subagent 上下文 / Claude Sonnet 5.5 / 新会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：9ce0c4b7e6ca490589ed65af4fcc241abb0bce50fc90bb9520dfa0c26a71538f
- 审查范围：v2.1.1...HEAD + 工作区（工作区干净，无未跟踪文件）

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不需要
- 决策来源：requirements.md 写明「需人决定：否」；改动只是升级说明的文字，不涉及数据、权限或不可逆操作，核对后判断成立

## 关键问题
无

## 改进建议
- `template/.agents/skills/upgrade.md:5`：「与这里不同时按它做」没说明只读一层。目标版本的说明里若再写同样的句子，AI 可能反复读取。建议加「只读一次」之类的限定，或记入「发现但不碰」。
- `template/.agents/skills/upgrade.md:12`：`git diff` 的基线提交取不到时（人点名版本且旧提交已不在仓库）命令会报错，tasks.md 已说明由 AI 告诉人，但 upgrade.md 本身没写这条出路。可以补半句「取不到就把两个版本的该文件全文列给人」。不阻塞。

## 证据
- 验证：verification.md 的 result 为 PASS，state 为 9ce0c4b7...71538f
- AC-01：grep 命中第 5 行所在的第 2 步，同行含「按它做」与「取不到」；临时克隆里 `git show v2.1.1:template/.agents/skills/upgrade.md` 取到说明首行（脚手架升级与降级）
- AC-02：grep 命中第 12 行，同行含 `git -C <脚手架仓库> diff` 与「列给人」；临时克隆里给模板 redlines.conf 加 `NEW_KEY=1` 并提交，diff 输出该行；模板未变时输出为空
- AC-03：grep 命中第 12 行，同行含 `.gitattributes` 与 `.gitignore`
- 范围：diff 只有 upgrade.md 三处文字、install-skill.md 一句活文档、任务文件与 Spec 文件，无超出需求的行为；`template/.gitattributes` 存在，第 5 步新增的规则与现有文档无冲突
- 活文档：install-skill.md 新增的说明与 MEMORY.md 无矛盾，并说明了「只对已带上它的项目生效」的限制
