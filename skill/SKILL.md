---
name: ai-harness-scaffold
description: 用「跨工具防膨胀 AI 辅助开发脚手架」初始化新项目，或给已有老项目 retrofit 同一套规范（AGENTS.md 入口、docs/specs 三件套与 G1~G7 阶段门、ai-verify 增量验证、CR 独立审查、知识卡飞轮、上下文体积体检）。当用户说「按这个规范初始化项目」「给老项目接入这套 AI 开发流程」「装/升级 ai-harness」「用脚手架管理开发」时使用。它负责机械部分（复制模板、冲突隔离、技术栈探测、模块索引桩），你负责判断部分（模块边界、契约入口、真实 verify 命令、AGENTS 定制）。
version: 1.0.0
user-invocable: true
---

# ai-harness-scaffold — 初始化 / 改造 / 体检

本 skill 自带一份工具（CLI + 模板），**不要凭记忆手抄脚手架内容**，机械部分全部交给 CLI。

## Step 0：定位工具

`<skill-base-dir>` 是本 SKILL.md 所在目录（skill 文件夹本身）。CLI 路径：`<skill-base-dir>/bin/ai-harness`。

先跑一次确认可用；若当前目录就是源码仓库，也可以用仓库里的 `bin/ai-harness`：

```bash
bash "<skill-base-dir>/bin/ai-harness" version
```

## Step 1：判断模式并执行 CLI

- 目标目录为空（或只有 `.git`）→ **init**
  ```bash
  bash "<skill-base-dir>/bin/ai-harness" init <dir> --no-git   # 需要时去掉 --no-git
  ```
- 目标已有代码/文档 → **retrofit**（永不覆盖已有文件）
  ```bash
  bash "<skill-base-dir>/bin/ai-harness" retrofit <dir> --skip-doctor
  ```
  先加 `--dry-run` 看计划也允许。**不要**对非空目录用 `init --force`。

CLI 会输出 `+新增 / =同内容 / →冲突建议文件 / ↳managed block` 四类结果，把输出如实转述给用户。

## Step 2：处理冲突与归档（判断工作）

看 `<dir>/.ai-harness/suggested/`：

- 已有 `AGENTS.md`：**不要整体替换**。只把模板里的机制段落（门禁表 G1~G7、迭代上限、红黄绿卡、验证口径）并入用户现有 AGENTS.md，保证 **仍 <120 行**；其余项目专属内容保留。
- 已有 `docs/architecture/00-INDEX.md`：把模板表格行并入既有表格，保留用户已有模块行。
- 已有 `.gitignore` 等：CLI 已用 managed block 追加，不要重复追加。
- 过时、重复、被新文档取代的旧材料 → 移入 `docs/specs/archive/`（或项目既有归档目录），**不留两份真相**；删除前在改动说明里列出。

合并完成后可以删掉 `.ai-harness/suggested/` 里已处理完的文件，并在汇报里说明。

## Step 3：把模块索引变成真的

`retrofit` 会扫描代码树生成 `docs/architecture/modules/*.md` 桩（全部标注「待人工确认」）并登记 00-INDEX。你要做：

1. 只读侦察：`README`、顶层目录、构建文件（package.json / pyproject.toml / go.mod / pom.xml），确认模块边界；**不要**通读实现代码。
2. 每个模块文档填：职责与边界、**对外公共契约入口**（只读，如 `index.ts` / `types.py` / 导出头文件）、核心数据结构、本模块专属红线。
3. 模块超过 12 个时只保留主干模块，其余合并或留待后续；不要为了全而生成一堆空文档。
4. 00-INDEX 的每一行都必须指向真实存在的模块文档与代码路径。

## Step 4：配真实 verify 命令

`retrofit` 会探测技术栈并生成 `harness/verify.conf` 的 `CUSTOM_CHECK`（可能为空）。核对它：

- Node/TS：`npx --no-install tsc --noEmit` 或 eslint / vitest related；
- Python：`ruff check "$TARGET_FILE"` 或 `pytest <对应测试>`；
- Go：`gofmt -l "$TARGET_FILE" | (! grep .)` 或 `go vet <包>`；
- 其它：写一条能在秒级内对该文件给出真实结论的命令。

然后**实际验证一次**：挑一个源码文件跑 `bash scripts/ai-verify.sh <file>`，确认报告里 `# result: PASS` 且 `# checks: N`（N≥1）。没有真实检查时脚本会失败，这是设计（未验证 ≠ 通过），不要用假命令绕过。

## Step 5：空需求 Dry Run + 体检

```bash
cd <dir>
bash scripts/harness-selftest.sh      # 55 项断言，应全绿
bash scripts/ai-check-bloat.sh        # 🟢 Context Budget OK
bash scripts/ai-gate.sh status        # 🔒 红线基线一致
```

再跑一条真实小需求验证流程可用：`bash scripts/ai-new-spec.sh feat-dryrun`，只填到能通过 `ai-gate.sh check feat-dryrun g1 g2` 为止（不要写业务代码），确认门禁会「该拒的拒、该过的过」，然后删掉该 spec 目录。

## Step 6：汇报

给用户：① 模式（init/retrofit）与目标路径；② 新增/跳过/冲突数；③ 需要人工确认的清单（模块边界、契约入口、verify 命令、AGENTS 合并点）；④ doctor 结果；⑤ 下一步建议（从第一条 `[ ]` 原子任务开始，或先补模块文档）。

## 硬约束

- 不覆盖老项目已有文件；不改用户的业务代码；不自动 git push。
- 不把模板里的示例模块/示例红线留成「真相」——要么替换，要么归档。
- `harness/redlines.conf` 只允许人类修改；你只能建议。
- 归档优先于删除；确实要删时先说明影响。
