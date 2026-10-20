# ai-harness — 跨工具 AI 辅助开发脚手架（安装器 + 模板）

一个 **host 无关**的初始化工具：把「需求入口、按风险分流、影响面核对、阶段门禁、增量验证、独立 CR、知识飞轮和交付反馈」这套规范，
一键装进新项目，或 retrofit 进已有老项目。模板与脚本都在这一个仓库里，单一真相源。

> 面向 Claude Code / OpenAI Codex / Cursor / OpenCode / DeepSeek 等任何能读 `AGENTS.md`、
> 能跑 bash 的 AI 工具；不绑定某个 IDE 或云端平台。

## 两种用法：对话主导（推荐）/ 命令行直接跑

**推荐用法是对话主导**：在 AI 对话里说一句话，由 AI 侦察仓库、判断模块边界、合并已有文档、实测 verify 命令，遇到不确定性再回来问你。CLI 只是给它批量落盘的助手（也可完全不用，直接读 `template/`）。

```
# 新项目，交给 AI
用 ai-harness-scaffold 这套规范初始化 ~/code/my-new-project

# 老项目，交给 AI
把 ~/code/legacy-project 接进 ai-harness-scaffold 流程，先给我冲突与改造建议，我确认后再动手
```

AI 按 `skill/SKILL.md` 的六步走；老项目的分阶段接入和试点见 `template/.agents/skills/retrofit-legacy.md`。模块扫描只生成候选清单，不自动建立一批空模块文档；**不确定的边界列成清单确认**。

**命令行直接跑**适合：标准结构的项目、CI 里的重复初始化、你已清楚要什么的时候。

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

粗想法可先记在项目内 `docs/INTAKE.md`，保留原话与处理决定；明确的需求直接建 Spec。①低风险小改动可用单步精简设计；②③先记录人的风险或架构决定；④完成分类与人工移交后，门禁会阻止继续自动开发。设计时核对间接消费者与实际检索范围。知识卡可用 `ai-knowledge.sh suggest <module>` 找候选，代码改动后用 `impact <path...>` 提示复核；验收模板记录发布与回访结果。

G6 由 Agent 执行冒烟和 AC 核对，并把命令、环境、结果写入 `acceptance.md`。①证据充分时自动收尾；②③只把需要判断的风险、结果和遗留交给人，通过对话取得明确决定后由 Agent 记录并推进门禁。用户不必填写 Markdown、亲跑检查命令或逐篇阅读全部材料；记录会区分人的决定和 Agent 执行的检查。本地文件不是身份认证，需要强制审批时使用项目自己的权限机制。

## 两种模式的区别

| | `init` | `retrofit` |
| :-- | :-- | :-- |
| 目标 | 空目录 | 任意已有项目 |
| 已有文件 | 拒绝执行（除非 `--force`） | **一律不覆盖**，冲突内容放 `.ai-harness/suggested/` |
| ignore 文件 | 直接放置 | 用 `# >>> ai-harness managed block` 幂等追加 |
| 技术栈 | 不探测 | 探测 `package.json` / `pyproject.toml` / `go.mod` / `pom.xml` / `Cargo.toml`，生成 `harness/verify.conf` |
| 模块索引 | 保留模板示例 | 扫描代码树生成候选清单；确认试点模块后才写活文档和 `00-INDEX` |
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

## 本仓库自用

根目录也按这套流程开发：`AGENTS.md`、`docs/specs/`、`MEMORY.md` 与 Git 保存状态；根目录 `scripts/` 只转发到 `template/scripts/`，机制仍只维护一份。根目录的项目专属阈值与验证命令在 `harness/`。

```bash
bash scripts/ai-resume.sh
bash scripts/ai-gate.sh status
bash scripts/harness-selftest.sh
```

本仓库在接入前已有 Git 历史和 `main` 分支，因此自用接入保留原仓库；没有重新执行 `git init`。当前接入工作记录在 `docs/specs/active/feat-self-hosting/`。

`template/` 里包含：`AGENTS.md`（L1 入口）、`MEMORY.md`（踩坑池）、`docs/`（轻量需求入口 + 模块活文档 + Spec 与验证摘要模板 + 度量）、
`scripts/`（ai-gate / ai-verify / ai-resume / ai-new-spec / ai-state-id / ai-check-bloat / ai-knowledge / harness-selftest）、
`harness/redlines.conf`（唯一阈值来源）、`.knowledge/`（知识卡）、`.agents/skills/`（阶段技能）。
通用 CI 接入命令见 `template/harness/CI.md`；覆盖率和变异测试阈值须由目标项目的 CI 实现。
老项目 `retrofit --dry-run` 只读；正式接入不会覆盖已有文件、删除同名示例文件或自动改写红线。目录扫描结果放在 `.ai-harness/suggested/` 供审核。
示例领域图与路线图不会复制进老项目，避免把虚构架构当成项目事实。

## Claude Code ↔ Codex 接力

项目内 `AGENTS.md`、当前 Spec 的 `tasks.md` / `.gates` / `verification.md` 和 Git 改动是持久状态；
`CLAUDE.md` 仅导入 `AGENTS.md`，不存另一份规则。`.agents/skills/*.md` 是按需读取的普通项目指南。
本地 `reports/` 保存详细验证日志，`verification.md` 保存可入库的摘要。

```bash
bash scripts/ai-resume.sh feat-example
bash scripts/ai-verify.sh --spec feat-example src/example.ts
bash scripts/ai-gate.sh status feat-example
```

换 IDE 且使用同一工作区，可直接接手未提交改动；换 worktree 或电脑时，须用 Git 提交或补丁传递未提交代码。
没有 Git 时摘要只能检测目标文件本身的变化，因此完整的跨工作区接力应使用 Git。
G4 要求验证摘要与当前代码状态一致。修改代码或暂存后请重新验证；相同索引内容提交后指纹保持稳定。TTY 和本地红线哈希只防误操作；
需要强制人工审批时，用目标项目自己的外部权限机制。

## 设计取舍

- **不做 `upgrade` 子命令**：升级时用 `git diff` 对比 `template/` 与项目内文件即可；自动化合并的维护成本高于收益。
- **不覆盖、不猜测**：老项目的 `AGENTS.md`、`00-INDEX.md` 可能已有团队约定，合并是判断题，不是复制题。
- **过时内容归档而非删除**：被取代的旧文档移入 `docs/specs/archive/`，保持单一真相。
- **模板即实例**：这个仓库自身就是可运行的脚手架（`template/` 内可跑 `harness-selftest.sh` 自检）。
