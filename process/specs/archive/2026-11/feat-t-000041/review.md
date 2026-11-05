# 审查：feat-t-000041

- 审查者：独立 subagent（未参与实现）/ Claude Sonnet 5.5 / 单次审查会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：62c05f11e222a465f1dfd5084d1a55b55a39405354c210c7f4d057215fdeeb82
- 审查范围：93f5933...HEAD + 工作区（工作区干净）

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：通过
- 决策来源：对话，维护者 2026-11-05 当次选择「通过」，并选定「归档后打 v2.1.0」

## 关键问题
无

## 改进建议
1. `README.en.md:23`：写「It installs the latest tag」，但仓库目前没有 tag，实际会取 HEAD；中文版 `README.md` 已写明「没有 tag 时取 HEAD」，英文版缺这半句。打首个 tag 后即成立，打 tag 前读者会被误导。
2. `skill/SKILL.md:12`：「已接入」一行让 AI 按工作区里的 `template/.agents/skills/upgrade.md` 升级，而该文件可能比所选版本更新；与「按所选版本读文件」不完全一致。影响小，可在升级说明里补一句「以目标版本的 upgrade.md 为准」。
3. `template/.agents/skills/upgrade.md:5`：第 2 步一条里塞了版本选择、防降级判断和机制文件清单，句子很长，外部 AI 容易漏看 `is-ancestor` 的停下条件。建议拆成子项。

## 证据
- 验证：verification.md 的 result 为 PASS，state 为 62c05f11e222a465f1dfd5084d1a55b55a39405354c210c7f4d057215fdeeb82；`ai-gate.sh status` 显示 g1、g2 已过。
- AC-01：`gh repo view --json licenseInfo` 返回 key 为 `mit`。
- AC-02：`git ls-files template` 含 `template/.ai-harness/LICENSE.md`，不含 `template/LICENSE`；该文件含 forrestchang、MIT，并写明上游没有 LICENSE 文件、不写上游版权行；`upgrade.md:5` 机制文件列表含 `.ai-harness/LICENSE.md`。
- AC-03、AC-04：逐条 grep 全部命中；私密漏洞报告已启用（`gh api` 返回 enabled 为 true），Issues 已开启，仓库可见性为 PUBLIC。
- AC-05：在系统临时目录新克隆里按 `skill/SKILL.md` 实测，已删除。有 v1.9、v1.10、v1.2 三个 tag 时 `fetch --tags` 成功，`tag --sort=-v:refname` 取 v1.10，`commit=` 为其解析后的完整提交号，装入内容来自该 tag，自检 72 项失败 0；删除全部 tag 后取 HEAD，`commit=` 等于 HEAD 完整提交号，自检 72 项失败 0。`grep -n is-ancestor upgrade.md` 命中（升级路径未实测，按需求约定）。
- AC-06：跟踪文件里没有本机绝对路径、邮箱（仅测试用的 `example.invalid`）或外部私有项目名；`D:\code\...` 是示例路径；提交作者邮箱为 noreply；`grep -c dsh .gitignore` 为 0；根 `AGENTS.md:15` 命中「公开」。词表本身未复现。
- AC-07：`self-hosting.md:8` 命中「历史」说明；映射表未复现。
- AC-08：`selftest.yml` 含 `contents: read` 和 40 位 SHA；`gh run list --workflow selftest.yml --limit 1` 为 completed / success。
- AC-09：见上，按约定未重跑。
- 需人决定：需求写「是」，判据成立（许可证选择与对外发布），无异议；首个公开 tag 在人决定后再打。
