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
- **已接入**：目标项目有 `.ai-harness/version` 时，说明已经接入过。这时按 `template/.agents/skills/retrofit-legacy.md` 的「升级与降级」处理，不要重装。

## 1. 新项目（空目录或只有 `.git`）
1. 复制全部模板文件；有了第一个真实模块再写活文档并登记 `docs/architecture/00-INDEX.md`。
2. 没有 Git 仓库时运行 `git init -b main`；目标位于别的仓库里或 Git 状态判断不了时，先问人。
3. 跟用户确认技术栈后，在 `harness/verify.conf` 写一条真实的增量检查命令，可参照 `harness/verify.conf.example`。没有真实检查时，`ai-verify` 会拒绝通过。
4. 运行 `bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh` 和 `bash scripts/ai-gate.sh status`，记录红线初始基线后提交。

## 2. 已有项目
按 `template/.agents/skills/retrofit-legacy.md` 做，要点如下：
1. **先只读摸底**：记录 Git 状态、现有规则、构建、测试与 CI，不清理工作区。动手前先把计划列给用户：哪些文件新增、哪些冲突、哪些要合并。
2. **只补缺失的文件**：目标里已有、内容不同的文件不覆盖，把模板与原文件的差异合并进去，或列给人决定。
   - `.gitignore`、`.gitattributes`、`.cursorignore`、`.claudeignore`：在原文件末尾追加 `# >>> ai-harness managed block >>>` 与 `# <<< ai-harness managed block <<<` 包住的模板内容；已有这个块就跳过。
3. **验证命令**：从项目实际用的工具链里选一条能对单个文件跑的检查，比如 tsc、eslint、ruff、`go vet`，写进 `harness/verify.conf`，并实际跑一次确认可用。
4. **试点模块**：从代码目录里挑**一个**真实模块写活文档，登记到 `docs/architecture/00-INDEX.md`；其他候选目录只列给用户，不建空文档。
5. **红线**：`harness/redlines.conf` 的阈值只给建议，由人决定后再运行 `bash scripts/ai-gate.sh baseline`。

## 3. 收尾（新旧项目都做）
1. 写 `.ai-harness/version`：内容是 `version=<本文件 frontmatter 的 version>`，再加一行接入日期。
2. 运行第 1 节第 4 步的三条检查，修好再交付。
3. 报告：接入了哪些文件、冲突怎么处理的、实际跑过哪些验证、还剩哪些事要人决定。

用户负责架构、权限和阈值这类必须由人取舍的事；AI 负责执行、写项目文档和验证。之后各个 AI 工具都靠项目里的 `AGENTS.md`、Spec、活文档和 Git 接力。
