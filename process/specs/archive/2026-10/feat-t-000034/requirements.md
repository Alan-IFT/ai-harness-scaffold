# 需求：feat-t-000034

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000034.md`（原始需求与更新）
- 原始问题 / 原话：先做值得补的；希望还有个文件来支持放用户个人偏好；现在都不使用cli命令了，要做什么都是给AI说一声，让AI干，所以只需要有对应的指导文档或skill就行；没有存量用户
- 需人决定：否（「值得补的」五条、删命令、删迁移说明都已由维护者在对话里定下；个人偏好文件的命名与是否入库由 AI 决定并在交付时说明）

## 1. 要做什么
- 做什么：补上独立评审列出的五条门禁缺口；新增个人偏好文件；把只为人准备的任务池命令（`update`、`prefer`）改成给 AI 的说明；删掉没有用户的 1.x→2.0 迁移说明；顺带修复任务编号与已有 Spec 目录撞号的问题（本次收录时实际撞上）。
- 为谁做：接入脚手架的维护者与各 AI 工具。
- 不做：不加钩子、不给 `.gates` 加签名；不删 AI 要调用的门禁脚本；不改 `harness/redlines.conf` 的键。

## 2. 验收标准
| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | g1 拒绝：验收标准未被任何任务引用、任务引用不存在的 AC 编号 | 自检「g1 计划」新增两条断言通过 |
| AC-02 | g2 拒绝验证目标不在 tasks.md 反引号路径里的摘要 | 自检「g2 验证」新增断言通过 |
| AC-03 | `archive` 在三道门未全部通过或审查已失效时拒绝归档；全部通过时照常归档 | 自检新增「未过门拒绝归档」「三门通过后归档」断言通过 |
| AC-04 | `ai-task-pool.sh` 不再有 `update`、`prefer` 与 `NEXT` 文件；任务文件写 `- 优先: 是` 时 `next`/`start-next` 先选它；`AGENTS.md` 写明补充需求与指定优先都由 AI 直接改任务文件 | `grep -n "prefer\|update\|NEXT" template/scripts/ai-task-pool.sh` 无结果；自检「按优先选下一项」通过 |
| AC-05 | 新任务编号避开已存在的 `feat-t-*` Spec 目录 | 自检新增「编号避开已有 Spec」断言通过 |
| AC-06 | 模板有 `PREFERENCES.md` 且被模板 `.gitignore` 忽略；`AGENTS.md` 写明接手时读、个人习惯写这里；升级说明把它列为不动的项目状态 | `git -C . check-ignore` 在接入试点目录里命中；`grep -n PREFERENCES template/AGENTS.md template/.agents/skills/upgrade.md` |
| AC-07 | `review.md` 模板有「审查范围」一行 | `grep -n "审查范围" template/.agents/skills/code-review.md` |
| AC-08 | `skill/SKILL.md` 要求用空用例目录跑一次测试命令、检查 `.gitignore` 覆盖构建产物与日志 | `grep -n "空用例\|构建产物" skill/SKILL.md` |
| AC-09 | `upgrade.md` 不再有「版本说明」与 1.x→2.0 段落 | `grep -c "1.x" template/.agents/skills/upgrade.md` 为 0 |
| AC-10 | 自检、体积检查通过；按 `skill/SKILL.md` 在临时目录接入一个新项目，自检通过 | `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`、试点目录内自检输出 |
