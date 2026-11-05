# 审查：feat-t-000044

- 审查者：独立审查子代理 / Claude Sonnet 5.5 / 全新上下文
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：2e22eb5183e6481709aa2659cc31407e7849908c9b001fa77cd7d660c51c9555
- 审查范围：v2.1.2...HEAD + 工作区

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不需要
- 决策来源：requirements.md「需人决定：否」；改动只涉及说明与 README，不涉及数据、权限、发布或不可逆操作，审查者同意该判断

## 关键问题
无

## 改进建议
1. `README.en.md:20-23`：中文版 `README.md:19-21` 有「以后升级 / 降级或指定版本 / 不能访问 GitHub」三条补充，英文版只保留了「v2.1.3 起可直接说升级」一句，缺降级与无法访问 GitHub 时的做法，两份 README 信息不一致。建议英文版补两句对应说明，或两边统一精简。
2. `README.md:19`、`README.en.md:23`：写死「v2.1.3 起」，而该版本尚未发布（现有最新 tag 为 v2.1.2）。若下个版本号不是 v2.1.3 或晚发，用户会被误导。建议发版时核对这一处。

## 证据
- 验证：verification.md 的 result 为 PASS，state 为 2e22eb51...3c9555（未重跑，按任务要求）
- AC-01 亲跑：两份 README 的「开始」小节代码块各只有一句，均含克隆地址与 `skill/SKILL.md`；`README.md` 无 `必须用`、`D:\code`；`README.en.md` 无 `A ZIP download`。通过。
- AC-02 亲跑：`skill/SKILL.md:11` 命中 `is-shallow-repository`，`skill/SKILL.md:32` 命中 `临时克隆`。通过。
- AC-03 亲跑：`template/.agents/skills/upgrade.md:4` 含地址与「临时目录」。通过。
- AC-04 亲测（空临时目录当项目，克隆放另一临时目录，未读用户目录与已装技能）：按 README 句子克隆后 `is-shallow-repository` 为 false，最新 tag 为 v2.1.2；按 SKILL.md 第 1 节装入 25 个模板文件，`.ai-harness/version` 为 `commit=ae72c0d3...`，等于 v2.1.2 解析后的提交；`harness-selftest.sh` 74 项断言失败 0，`ai-check-bloat.sh` 与 `ai-gate.sh status` 正常；因没有技术栈，`CUSTOM_CHECK` 留空（文件里仍是模板示例注释），如实记录；临时克隆与项目目录均已删除。通过。注意：审查者此前已读过本仓库文件，不是完全「没看过」的上下文，但实测步骤只用了 README 句子与克隆内的 `skill/SKILL.md`。
- AC-05、AC-06：临时项目已删除，无法复现；采信 tasks.md WIP 区的实测记录（升到 v2.1.2、定制与状态文件保留、自检 74 项 0 失败、临时克隆已删除；AC-06 首次因读了用户目录技能入口作废，重测合规）。这两条是采信记录，不是审查者亲测。
- 外部用户角度：README 那句话自洽，包含地址、完整克隆、临时目录、新旧项目与升级三种情况，复制即用；前置条件已加「能访问 GitHub」，无法访问的退路在中文版有写。没有引入对已删除内容（手动克隆、ZIP）的残留引用，`install-skill.md` 的新条目与 `upgrade.md` 写死地址的取舍一致。
- 范围：diff 未超出 requirements 所列文件，未改脚本、未打 tag。
