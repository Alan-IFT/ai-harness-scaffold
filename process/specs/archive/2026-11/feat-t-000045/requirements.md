# 需求：feat-t-000045

- 创建时间：2026-11-06
- **需求来源**: `process/task-pool/T-000045.md`（原始需求与更新）
- 原始问题 / 原话：我发现这个readme好像不太行，别人看了都不知道项目的架构等，好像只有个安装说明和简单一句话介绍，其他的就没了，参考很多大型开源项目那样标准化且结构清晰的写readme吧，重构readme吧；（维护者 2026-11-06）
- 需人决定：否，只改说明文档，不涉及数据、权限、发布、架构取舍或不可逆操作。

## 1. 要做什么
- 做什么：按大型开源项目的常见结构重写 `README.md`，讲清项目解决什么问题、工作流程、架构和目录；`README.en.md` 按同样骨架补上架构概览，仍保持简短。
- 为谁做：第一次打开仓库、要判断是否使用或想了解实现的人。
- 不做：不改脚本、模板和接入说明；不加路线图、CHANGELOG、示例项目；不打 tag；不做英文全量翻译（维护者 2026-11-05 定的是简短英文 README）。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `README.md` 有徽章、目录，以及这些二级标题：为什么需要它、快速开始、工作原理、架构、支持的 AI 工具、安全与局限、设计取舍、参与开发、许可证；目录每一项都指向存在的标题 | 校验脚本逐项检查标题与目录锚点，输出 0 缺失 |
| AC-02 | 原有信息不丢：一句话接入语句逐字不变；升级、降级、无法访问 GitHub 的说明还在；T-000041 AC-03 的关键词全部命中 | 校验脚本对比 `git show HEAD:README.md` 的代码块，并 grep `github.com/Alan-IFT/ai-harness-scaffold.git`、`Git Bash`、`ZIP`、`Claude Code`、`Codex`、`理论兼容`、`只支持 Windows`、`安全边界`、`CUSTOM_CHECK`、`security/advisories/new`、`Issue`、`process/`、`README.en.md`，输出 0 缺失 |
| AC-03 | 架构内容与代码一致：`template/scripts/*.sh` 每个脚本都出现在脚本表，文中子命令都能在脚本用法里找到；`template/harness/redlines.conf` 的每个键都出现在配置表；目录树里的文件都能在模板或脚本写入路径中找到；所有相对链接指向存在的文件 | 校验脚本输出 0 缺失；目录树由审查者对照 `git ls-tree -r --name-only HEAD template` 复核 |
| AC-04 | `README.md` 与 `README.en.md` 的所有 Mermaid 图在 GitHub 页面上都渲染成图，没有语法错误提示 | 推送后在浏览器打开两个 GitHub 页面，截图查看每张图 |
| AC-05 | `README.en.md` 有 How it works、Architecture 两节，保留一句话接入语句、中文产出提示、Windows 限制与 `README.md` 互链，正文不超过 100 行 | 校验脚本 grep 关键词并统计行数 |
| AC-06 | 两份 README 不含本机路径和私人邮箱；正式验证通过 | `grep` 无命中；`bash scripts/ai-verify.sh --spec feat-t-000045 README.md` 输出通过 |
