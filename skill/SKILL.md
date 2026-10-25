---
name: ai-harness-scaffold
description: 给新项目或已有代码项目接入 ai-harness 跨 IDE 开发脚手架，或升级 / 降级已接入的项目。用户说“把这个项目接入脚手架”“用这套规范管理开发”“升级脚手架”等话时使用；先摸底、保护原文件，再由 AI 完成安装和验证。
version: 2.0.0
---

# ai-harness-scaffold

没有安装命令，全部由 AI 按本文判断着做。遇到本文没写到的情况，按「不覆盖、不删除、拿不准就问人」处理。

## 0. 定位
- **脚手架仓库**：本文件所在目录的上一级，以其中存在 `template/AGENTS.md` 为准；找不到就停下报告路径，不凭记忆重建。
- **要装的文件**：`git -C <仓库> ls-files template` 列出的文件，去掉 `template/` 前缀后就是目标项目里的相对路径。不在 Git 里的文件不装。
- **目标项目**：从对话或当前工作区确定；有多个候选又判断不了时再问。
- **已接入**：目标项目有 `.ai-harness/version` 时不要重装，按 `template/.agents/skills/upgrade.md` 升级或降级。

## 1. 新项目（空目录或只有 `.git`）
1. 复制全部模板文件；没有 Git 仓库时运行 `git init -b main`（目标在别的仓库里或判断不了时先问人）。
2. 跟用户确认技术栈后，把 `harness/verify.conf` 的 `CUSTOM_CHECK` 改成一条真实检查命令。

## 2. 已有项目
1. **只读摸底**：记录 Git 分支、未提交改动、现有规则（`AGENTS.md` / `CLAUDE.md`）、构建、测试与 CI；不清理工作区。只给接入后的新变更用 Spec，不为历史补造 Spec。
2. **先列计划**：哪些文件新增、哪些与已有文件冲突，先给用户看。
3. **只补缺失的文件**：已有文件不覆盖；`AGENTS.md`、`.gitignore` 等冲突文件把模板内容合并进去，或列给人决定。已有需求系统继续用，Spec 的「原话」里链接过去即可。确认 `.gitignore` 覆盖构建产物、依赖目录与日志：状态指纹按全仓计算，没被忽略的产物会让验证不停过期。
4. **验证命令**：从项目现有工具链里选一条能对单个文件跑的检查写进 `harness/verify.conf`，实际跑一次确认可用；命令里含测试的，再用一个空用例目录跑一次，确认零用例时失败。
5. **试点模块**：只为一个真实模块写活文档并登记 `docs/architecture/00-INDEX.md`；其他模块等下次改到时再补。
6. **红线**：`harness/redlines.conf` 的阈值只给建议，由人决定。

## 3. 收尾（新旧项目都做）
1. 写 `.ai-harness/version`：`version=<本文件 frontmatter 的 version>`，再加一行接入日期。
2. 运行 `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`、`bash scripts/ai-gate.sh status`，修好后提交。
3. 报告：接入了哪些文件、冲突怎么处理的、实际跑过哪些验证、还剩哪些事要人决定。

用户负责架构、权限和阈值这类必须由人取舍的事；AI 负责执行、写项目文档和验证。之后各个 AI 工具都靠项目里的 `AGENTS.md`、Spec、活文档和 Git 接力。
