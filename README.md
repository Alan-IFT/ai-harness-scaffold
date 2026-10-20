# ai-harness — 跨工具 AI 辅助开发脚手架（安装器 + 模板）

一个 **host 无关**的初始化工具：把「防上下文膨胀、阶段门禁、增量验证、独立 CR、知识飞轮」这套规范，
一键装进新项目，或 retrofit 进已有老项目。模板与脚本都在这一个仓库里，单一真相源。

> 面向 Claude Code / OpenAI Codex / Cursor / OpenCode / DeepSeek 等任何能读 `AGENTS.md`、
> 能跑 bash 的 AI 工具；不绑定某个 IDE 或云端平台。

## 快速开始

```bash
# 新项目（目标必须为空目录或只有 .git）
bash bin/ai-harness init ../my-new-project

# 老项目改造（永不覆盖已有文件）
bash bin/ai-harness retrofit ../legacy-project --dry-run   # 先看计划
bash bin/ai-harness retrofit ../legacy-project

# 体检
bash bin/ai-harness doctor ../legacy-project

# 装成 DSH skill（可选）
bash bin/ai-harness install-skill
```

装好后，在新项目里开场跑：

```bash
bash scripts/ai-resume.sh        # 接手快照：门状态、WIP、知识库、git 残局
bash scripts/ai-gate.sh status   # G1~G7 阶段门
```

## 两种模式的区别

| | `init` | `retrofit` |
| :-- | :-- | :-- |
| 目标 | 空目录 | 任意已有项目 |
| 已有文件 | 拒绝执行（除非 `--force`） | **一律不覆盖**，冲突内容放 `.ai-harness/suggested/` |
| ignore 文件 | 直接放置 | 用 `# >>> ai-harness managed block` 幂等追加 |
| 技术栈 | 不探测 | 探测 `package.json` / `pyproject.toml` / `go.mod` / `pom.xml` / `Cargo.toml`，生成 `harness/verify.conf` |
| 模块索引 | 保留模板示例 | 扫描代码树生成模块文档桩，全部标注「待人工确认」，并登记 `00-INDEX` |
| 收尾 | 打印下一步 | 自动跑 `doctor`（可 `--skip-doctor`） |

## 命令

```
ai-harness init     <dir> [--no-git] [--dry-run] [--force]
ai-harness retrofit <dir> [--no-git] [--skip-doctor] [--dry-run]
ai-harness doctor   <dir>
ai-harness install-skill [--dest DIR]
ai-harness version | help
```

## 仓库结构

```
bin/ai-harness     # CLI：复制 / 冲突隔离 / 栈探测 / 模块扫描 / 体检 / 装 skill
template/          # 要被复制进目标项目的全部内容（唯一真相源）
skill/SKILL.md     # DSH skill：机械步骤交给 CLI，判断步骤（模块边界、契约、verify 命令）交给 agent
```

`template/` 里包含：`AGENTS.md`（L1 入口）、`MEMORY.md`（踩坑池）、`docs/`（模块活文档 + spec 三件套模板 + 度量）、
`scripts/`（ai-gate / ai-verify / ai-resume / ai-new-spec / ai-check-bloat / ai-knowledge / harness-selftest）、
`harness/redlines.conf`（唯一阈值来源）、`.knowledge/`（知识卡）、`.agents/skills/`（阶段技能）。

## 设计取舍

- **不做 `upgrade` 子命令**：升级时用 `git diff` 对比 `template/` 与项目内文件即可；自动化合并的维护成本高于收益。
- **不覆盖、不猜测**：老项目的 `AGENTS.md`、`00-INDEX.md` 可能已有团队约定，合并是判断题，不是复制题。
- **过时内容归档而非删除**：被取代的旧文档移入 `docs/specs/archive/`，保持单一真相。
- **模板即实例**：这个仓库自身就是可运行的脚手架（`template/` 内可跑 `harness-selftest.sh` 55 项断言）。
