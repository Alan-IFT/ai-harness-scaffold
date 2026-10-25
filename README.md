# ai-harness — 跨工具 AI 辅助开发脚手架

一套不绑定宿主的开发规范：任务池收需求，三道门（计划 / 验证 / 审查）管交付，WIP 与 Git 管接力，`MEMORY.md` 与模块活文档积累经验。
面向任何能读 `AGENTS.md`、能跑 bash 的 AI 工具（Claude Code、Codex、Cursor、DeepSeek 等）；只支持 Windows（Git Bash）。

## 用法：直接跟 AI 说

```
用 ai-harness 脚手架初始化 D:\code\my-new-project
把 D:\code\legacy-project 接入 ai-harness 脚手架
把 D:\code\legacy-project 的脚手架升级到最新版
```

没有安装命令。AI 读 `skill/SKILL.md`（告诉它本仓库路径即可）完成摸底、合并、验证命令、一个模块试点和体检，只把架构、权限、阈值这类需要你决定的事交回来。升级与降级按 `template/.agents/skills/upgrade.md` 手动完成。想让宿主自动发现这个技能，可在宿主的用户技能目录（如 `~/.claude/skills/ai-harness-scaffold/`）放一个只写「先读 `<本仓库>/skill/SKILL.md`」的 `SKILL.md`。

装好后你只需要用自然语言说需求：AI 收录进任务池，写需求与方案过 g1，编码并正式验证过 g2，换一个没写过代码的上下文审查过 g3；涉及数据、权限、发布或架构取舍的需求，会把风险交给你当次决定。门只检查骗不过的信号，文字质量交给独立审查与人。换 AI 工具时，新工具运行 `bash scripts/ai-resume.sh owner` 接着做。

## 仓库结构

```
template/          # 接入目标项目的全部内容（唯一真相源）
skill/SKILL.md     # 接入说明，由 AI 照着判断执行
scripts/           # 只转发到 template/scripts/；本仓库自己也用这套流程开发
```

## 设计取舍

- **少就是多**：会让脚手架变臃肿的功能、配置和文档直接删除，追溯交给 Git（见 ADR-0003）。
- **不写 CLI 与兼容代码**：接入、升级、降级都写成说明，由 AI 判断执行；特殊情况比命令行处理得好。
- **不覆盖、不猜测**：老项目已有的 `AGENTS.md` 等是团队约定，合并是判断题，不是复制题。
- **阈值只有一处**：每个项目以自己的 `harness/redlines.conf` 为准，只由人修改；缺键或值无效时脚本直接报错。
