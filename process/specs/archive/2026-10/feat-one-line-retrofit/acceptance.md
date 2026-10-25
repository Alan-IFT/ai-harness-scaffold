# 交付核验记录 (Acceptance): feat-one-line-retrofit

- 核验执行者：Codex Agent（实现上下文）；独立复审 `/root/one_line_retrofit_review`
- 核验时间：2026-10-20
- 测试环境：Windows，Git Bash；源码位于 `<本仓库>`
- 冒烟或 E2E 证据：Agent 运行 `bash -n bin/ai-harness`、Git Bash 临时目录脚本及 `bash scripts/ai-verify.sh --spec feat-one-line-retrofit bin/ai-harness`；正式自检 126/126 全部通过、134 秒，报告在本地 `reports/verify-20261020-111225-896.log`。

## 1. 核验摘要
- 对照 AC 的检查结果：AC-01～AC-04 逐项通过。
- AC-01：通过。临时安装样本为 Codex 与 Claude 生成合法薄 SKILL.md，均指向本仓库共享 `skill/SKILL.md`；README 提供一句话和显式调用；本机两个用户级入口已安装并核对指针。
- AC-02：通过。同源 DSH 重装可用；跨宿主、异源、无归属记录、入口类型异常均拒绝且不改原文件；异常写入返回非零。
- AC-03：通过。父仓库子目录、worktree `.git` 文件和损坏 `.git` 标记样本未生成嵌套仓库；真正无 Git 的新目录正常初始化。
- AC-04：通过。旧 DSH 安装与 retrofit CLI 冒烟通过；正式验证 PASS、完整门禁自检 126/126；独立审查 0 阻塞。
- 需人判断的风险 / 遗留：用户级薄入口保存本仓库绝对路径，移动仓库需重新安装；旧 DSH 空标记因来源不可证明会拒绝自动覆盖。正式验证 134 秒超过 120 秒提醒线但通过。审查另提两项非阻塞改进：非法 `--dest` 参数提示和在单份摘要中增加行为样本。

## 2. 决策与结论
- 验收方式：当次人工决定
- 人工决策人：维护者
- 人工决定：通过
- 决策来源：本会话用户回复「接受，G6 通过（推荐）」；用户只判断结果，无需运行命令或填写文档。
- 结论：通过
- 遗留 / 后续：维持共享技能源码位置；后续整理安装器时处理两项非阻塞改进。

## 3. 交付与回访
- 交付形态：本机技能已安装；仓库实现提交 `f77f081`，G6 已获用户决定
- 发布或交接证据：`~/.codex/skills/ai-harness-scaffold/SKILL.md` 与 `~/.claude/skills/ai-harness-scaffold/SKILL.md` 均指向 `<本仓库>/skill/SKILL.md`
- 回滚状态：可删除带本工具归属标记的用户级薄入口，并回退本 Spec 的仓库提交；目标老项目未改动
- 实际结果：本机发现入口已安装并静态核对；实际在老项目的首次对话触发待观察
- 后续动作：首次老项目接入时观察自然语言触发和宿主读取路径是否顺利
