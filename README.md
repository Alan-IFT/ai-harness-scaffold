# ai-harness — 跨工具 AI 辅助开发脚手架

[English](README.en.md)

一套不绑定宿主的开发规范：任务池收需求，三道门（计划 / 验证 / 审查）管交付，WIP 与 Git 管接力，`MEMORY.md` 与模块活文档积累经验。规范、模板和门禁提示都是中文。

## 开始使用

前置条件：Windows 与 Git Bash（只支持 Windows，macOS 和 Linux 未适配）、Git，以及一个能读 `AGENTS.md`、能跑 bash 的 AI 工具。

```bash
git clone https://github.com/Alan-IFT/ai-harness-scaffold.git
```

必须用 `git clone`。下载 ZIP 不可用：接入和升级要靠 Git 的 tag 和历史选版本、取回基线。

然后告诉 AI 这个克隆的路径，直接说：

```
用 ai-harness 脚手架初始化 D:\code\my-new-project
把 D:\code\legacy-project 接入 ai-harness 脚手架
把 D:\code\legacy-project 的脚手架升级到最新版
```

没有安装命令。AI 读 `skill/SKILL.md` 完成摸底、合并、验证命令、一个模块试点和体检，只把架构、权限、阈值这类需要你决定的事交回来。升级与降级按 `template/.agents/skills/upgrade.md` 完成。想让宿主自动发现这个技能，可在宿主的用户技能目录（如 `~/.claude/skills/ai-harness-scaffold/`）放一个只写「先读 `<本仓库>/skill/SKILL.md`」的 `SKILL.md`。

装好后你只需要用自然语言说需求：AI 收录进任务池，写需求与方案过 g1，编码并正式验证过 g2，换一个没写过代码的上下文审查过 g3；涉及数据、权限、发布或架构取舍的需求，会把风险交给你当次决定。门只检查骗不过的信号，文字质量交给独立审查与人。换 AI 工具时，新工具运行 `bash scripts/ai-resume.sh owner` 接着做。你自己的习惯（回复语言、语气、详略等）写进用户目录的 `~/.ai-harness/PREFERENCES.md`，所有项目、所有 AI 工具共用；只对某个项目的写进该项目根的 `PREFERENCES.md`（不入库）。

## 支持的 AI 工具

- **实测过**：Claude Code、Codex。
- **理论兼容**：Cursor、DeepSeek 等能读 `AGENTS.md`、能跑 bash 的工具，未实测。

## 使用前要知道

- **门禁不是安全边界**：门禁脚本在本地运行，防的是疏漏，防不住有意绕过。需要强制审批时，用代码托管平台的权限机制。
- **配置里的命令会被执行**：`ai-verify.sh` 用 `bash -c` 执行 `harness/verify.conf` 的 `CUSTOM_CHECK`。在别人的项目上运行前，先看这个文件。
- **版本**：接入和升级默认取最新 tag，没有 tag 时取 HEAD。`main` 可能包含未发布的改动，要用它就明确告诉 AI。

## 反馈与贡献

- **问题和建议**：提 [Issue](https://github.com/Alan-IFT/ai-harness-scaffold/issues)。目前只收 Issue，Pull Request 个案处理，提交前请先开 Issue 讨论。
- **安全问题**：通过 [私密漏洞报告](https://github.com/Alan-IFT/ai-harness-scaffold/security/advisories/new) 提交，不要公开发 Issue。

## 仓库结构

```
template/          # 接入目标项目的全部内容（唯一真相源）
skill/SKILL.md     # 接入说明，由 AI 照着判断执行
scripts/           # 只转发到 template/scripts/；本仓库自己也用这套流程开发
process/           # 本仓库自用的任务和 Spec 记录，不会装进你的项目
```

## 设计取舍

- **少就是多**：会让脚手架变臃肿的功能、配置和文档直接删除，追溯交给 Git（见 [ADR-0003](docs/architecture/decisions/ADR-0003-three-gates-no-compat-code.md)）。
- **不写 CLI 与兼容代码**：接入、升级、降级都写成说明，由 AI 判断执行；特殊情况比命令行处理得好。
- **不覆盖、不猜测**：老项目已有的 `AGENTS.md` 等是团队约定，合并是判断题，不是复制题。
- **编码原则取自 Karpathy 准则**：`template/AGENTS.md` §3 的四条原则译自 [andrej-karpathy-skills](https://github.com/multica-ai/andrej-karpathy-skills)，来源与许可见 `template/.ai-harness/LICENSE.md`。
- **阈值只有一处**：每个项目以自己的 `harness/redlines.conf` 为准，只由人修改；缺键或值无效时脚本直接报错。

## 许可证

[MIT](LICENSE)。接入时会把许可声明一起装到项目的 `.ai-harness/LICENSE.md`，它不决定你项目自身的许可证。
