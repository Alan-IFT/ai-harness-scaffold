---
name: ai-harness-scaffold
description: 用「跨工具防膨胀 AI 辅助开发脚手架」初始化新项目，或给已有老项目 retrofit 同一套规范（AGENTS.md 入口、docs/specs 三件套与 G1~G7 阶段门、ai-verify 增量验证、CR 独立审查、知识卡飞轮、上下文体积体检）。当用户说「按这个规范初始化项目」「给老项目接入这套 AI 开发流程」「用脚手架管理开发」时使用。它是「AI 主导、人在关键处拍板」的流程向导：你负责侦察仓库、判断模块边界与契约入口、编写 AGENTS 定制与 verify 命令，机械性的文件复制可调用随附 CLI（可选，复杂项目可手写以适配已有目录习惯）。
version: 1.1.0
user-invocable: true
---

# ai-harness-scaffold — 初始化 / 改造 / 体检

**主导者是你，不是脚本。** 用户说一句话（「用这套规范初始化 <dir>」或「把 <dir> 接进这套流程」），你负责侦察、判断、编写、验证；CLI 只是可选的「批量复制助手」，它的输出是**建议**，不是结论。

遇到下列情况就**停下来与用户确认**，不要硬套命令：目录结构与模板差异大、已有自己的一套流程规则、模块边界不清、技术栈混杂（多语言/单体+微服务）、已有 CI 与 verify 命令冲突、目标目录有未提交改动。

## Step 0：接手前先把三个事实说给用户（30 秒）

1. **目标路径与模式**：空目录（或只有 `.git`）→ 新模式；已有代码/文档 → 接入模式。
2. **技术栈与规模**：读 `README`、顶层目录、构建文件（package.json / pyproject.toml / go.mod / pom.xml / Cargo.toml）+ 顶层目录数量估算模块数；**不通读实现代码**。
3. **已有同类文件**：`AGENTS.md` / `CLAUDE.md` / `docs/architecture/` / `.cursorignore` / 已有 CI 配置是否已存在——这决定了后面是合并不是覆盖。

说清楚后直接开始，不需要用户再确认（除非命中上面「停下来」的条件）。

## Step 1：拿到模板文件（两种方式，任选）

- **方式 A（推荐用于标准项目）**：用 CLI 批量落盘，再按需修改
  ```bash
  bash "<skill-base-dir>/bin/ai-harness" version                      # 先确认可用
  bash "<skill-base-dir>/bin/ai-harness" init <dir> --no-git         # 新项目
  bash "<skill-base-dir>/bin/ai-harness" retrofit <dir> --skip-doctor # 老项目（永不覆盖）
  ```
  要看计划先加 `--dry-run`；**不要**对非空目录用 `init --force`。
- **方式 B（复杂/非标准项目）**：直接读 `<skill-base-dir>/template/` 下的文件，按项目实际结构调整后再写。模板里这些是**机制文件**（必须落地）：`AGENTS.md`、`MEMORY.md`、`scripts/*.sh`、`harness/redlines.conf`、`.agents/skills/*.md`、`docs/specs/_templates/*`；这些是**示例文件**（按需重建）：`docs/architecture/*`、`.knowledge/*`、`CLAUDE.md` / `.cursorrules` 等入口别名。

无论哪种方式，CLI 输出都如实转述给用户（`+新增 / =同内容 / →冲突建议 / ↳managed block`）。

## Step 2：合并而不是覆盖（判断工作）

看 `<dir>/.ai-harness/suggested/` 与已有文件：

- 已有 `AGENTS.md`：**不要整体替换**。只并入机制段落（门禁表 G1~G7、迭代上限、红黄绿卡、验证口径、上下文分层），保留项目专属规则，保证 **仍 <120 行**；超了就拆到 `docs/architecture/modules/`。
- 已有 `docs/architecture/00-INDEX.md`：把模板表格行并入既有表格，保留用户已有模块行；**老项目的索引不要被脚本生成的候选行污染**。
- 已有 `.gitignore` / `.cursorignore`：用 managed block 追加，不重复追加。
- 过时、重复、被取代的旧材料 → 移入 `docs/specs/archive/`（或项目既有归档目录），**不留两份真相**；删除前在汇报里列清单。
- 合并完成后可删 `.ai-harness/suggested/` 中已处理完的文件并说明。

## Step 3：把模块索引变成真的

新项目先从 `template/docs/architecture/` 起步；老项目看 `retrofit` 生成的 `docs/architecture/modules/*.md` 桩（全部标注「待人工确认」）。你要做：

1. 只读侦察：`README`、顶层目录、构建文件、CI 配置，确认模块边界；**不要**通读实现代码。
2. 每个模块文档填：职责与边界、**对外公共契约入口**（只读，如 `index.ts` / `types.py` / 导出头文件）、核心数据结构、本模块专属红线。
3. 模块超过 12 个时只保留主干模块，其余合并或留待后续；不要为了全而生成一堆空文档。
4. 00-INDEX 的每一行都必须指向真实存在的模块文档与代码路径。
5. **不确定的模块边界不要自己拍板**：列成「待确认清单」问用户（1~3 个最关键的问题，不要一次抛十个）。

## Step 4：配真实 verify 命令

新项目参考 `harness/verify.conf.example`；老项目看 `retrofit` 探测生成的 `harness/verify.conf` 的 `CUSTOM_CHECK`（可能为空）。核对它：

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

## Step 6：汇报 + 交接

给用户：① 模式（init/retrofit）与目标路径；② 新增/跳过/冲突数；③ **需要人工确认的清单**（模块边界、契约入口、verify 命令、AGENTS 合并点）——这是人工门，不要替用户签；④ doctor 结果；⑤ 下一步建议（从第一条 `[ ]` 原子任务开始，或先补模块文档）。

若中途停下（信息不足 / 命中「停下来」条件），也要给出**已完成的哪几步 + 卡在哪 + 需要用户回答的具体问题**，让下次会话能直接接着做。

## 硬约束

- 不覆盖老项目已有文件；不改用户的业务代码；不自动 git push。
- **CLI 只是工具**：它的判断（技术栈探测、模块候选、`ALLOWED_WRITE_DIRS`）在复杂项目里可能不准，以你的侦察结论为准，必要时手写替代。
- 不把模板里的示例模块/示例红线留成「真相」——要么替换，要么归档。
- `harness/redlines.conf` 只允许人类修改；你只能建议。
- 归档优先于删除；确实要删时先说明影响。
