# 需求：feat-t-000037

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000037.md`（原始需求与更新）
- 原始问题 / 原话：通用偏好当前存放位置，绑定宿主DeepSeek harness了，我的意思是 脚手架中设计一个位置来方便用户放入自己的偏好
- 需人决定：否，只新增一个可选的读取位置，不改门禁和红线；维护者已在对话中明确要求

## 1. 要做什么
- 做什么：约定一个不绑定宿主、跨项目共用的个人偏好文件 `~/.ai-harness/PREFERENCES.md`；接手时先读它，再读项目根的 `PREFERENCES.md`，冲突时项目的优先。
- 为谁做：在多个项目、多个 AI 工具间切换的维护者，偏好只写一份。
- 不做：不写脚本读取或校验该文件；不替用户搬运或删改 T-000028 里的偏好原文。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `template/AGENTS.md` 接手步骤与经验积累都写明通用偏好 `~/.ai-harness/PREFERENCES.md` 与项目 `PREFERENCES.md` 的读取顺序和优先级 | `grep -n ai-harness/PREFERENCES template/AGENTS.md` |
| AC-02 | `template/PREFERENCES.md` 说明两层位置；`skill/SKILL.md` 收尾报告提示用户通用偏好放哪；README 提一句 | 读文件 |
| AC-03 | 本仓库根 `AGENTS.md` 接手步骤同样读通用偏好；`guidance.md` 写明为什么 | 读文件 |
| AC-04 | 自检通过，`template/AGENTS.md` 不超 `AGENTS_MAX_LINES` | `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh` |
