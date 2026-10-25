# ai-harness — 跨工具 AI 辅助开发脚手架（安装器 + 模板）

一个 **host 无关**的初始化工具：把「需求入口、按风险分流、影响面核对、阶段门禁、增量验证、独立 CR、记忆积累和交付反馈」这套规范，
一键装进新项目，或 retrofit 进已有老项目。模板与脚本都在这一个仓库里，单一真相源。

> 面向 Claude Code / OpenAI Codex / Cursor / OpenCode / DeepSeek 等任何能读 `AGENTS.md`、
> 能跑 bash 的 AI 工具；不绑定某个 IDE 或云端平台。

## 一句话使用：先安装技能一次

```bash
bash bin/ai-harness install-skill --host codex
bash bin/ai-harness install-skill --host claude
```

安装器分别在 Codex 和 Claude Code 的用户技能目录生成薄入口，均指向本仓库的 `skill/SKILL.md`；流程正文仍只维护这一份。安装仅更新宿主和来源都匹配的本工具入口；无归属记录的旧 DSH 安装也会拒绝自动覆盖，由 Agent 核对后迁移。移动本仓库后需移除原来的本工具薄入口，再从新位置安装。

以后在任一宿主打开目标项目，直接说：**「把这个老项目接入 ai-harness 脚手架」**。若当前上下文无法确定目标项目，再补一个路径。也可显式调用 Codex 的 `$ai-harness-scaffold` 或 Claude Code 的 `/ai-harness-scaffold`。Agent 会完成摸底、只读预演、冲突合并、一个模块试点和验证；只把必须由维护者决定的架构、权限或阈值问题交回来。

## 两种用法：对话主导（推荐）/ 命令行直接跑

**推荐用法是对话主导**：由 AI 侦察仓库、判断模块边界、合并已有文档、实测 verify 命令，遇到真正需要维护者取舍的问题再回来问你。CLI 是批量落盘的助手，技能负责发现和编排。

```
# 新项目，交给 AI
用 ai-harness-scaffold 这套规范初始化 ~/code/my-new-project

# 老项目，交给 AI
把 ~/code/legacy-project 接入 ai-harness 脚手架
```

AI 从 `skill/SKILL.md` 定位共享流程；老项目的分阶段接入和试点见 `template/.agents/skills/retrofit-legacy.md`。模块扫描只生成候选清单，不自动建立一批空模块文档；**不确定的边界列成清单确认**。

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

# 旧 DSH 技能安装（可选，保持兼容）
bash bin/ai-harness install-skill --host dsh
```

装好后，在新项目里开场跑：

```bash
bash scripts/ai-resume.sh owner  # 主 Agent 接手快照：门状态、WIP、git 残局
bash scripts/ai-gate.sh status   # G1~G7 阶段门
bash scripts/ai-task-pool.sh next  # AI 接手时查看当前工作；维护者直接用自然语言说需求
```

维护者直接告诉 AI 新需求或补充，无需运行命令。AI 用 `ai-task-pool.sh intake` 自动保存原话：有活跃 Spec 就把新需求排队并续做；没有活跃 Spec 就启动人工指定或最早录入的待办，空池则启动刚提出的需求。默认按录入先后，旧 P0/P1/P2 字段仅保留兼容；说“先做某项”即可让 AI 持久指定下一项，仅在该项启动后清除。归档与自动领取共用任务池锁，归档完成后由 AI 接续下一项；新会话运行 `ai-resume.sh owner` 会提示续做的 Spec 或下一条待办。已开始的需求变化会同步修订 Spec 与受影响门禁。旧 `docs/INTAKE.md` 保留历史。需求澄清先明确完成后希望促成的行动、效果与观察方式；设计时用原始证据低成本检验关键前提，不因实现困难擅自降低目标。①低风险小改动可用单步紧凑设计；②③先记录人的风险或架构决定，并在 G3 列出边界样本及 REQ/ERR/AC 到设计的覆盖矩阵；任务引用设计章节，实施前回读原文锚点。④完成分类与人工移交后，门禁会阻止继续自动开发。设计时核对间接消费者与实际检索范围。独立 CR 对照需求原文、相关记忆和本次修改的 AI 协作文件，并核对 AC 措辞与验收证据是否支持结论；验收模板记录发布与回访结果，后续问题仅在有证据时作为候选提出。

G6 由 Agent 执行冒烟和 AC 核对，并把命令、环境、结果写入 `acceptance.md`。①证据充分时自动收尾；②③把风险和结果交给人当次决定。`acceptance.md` 每项以「通过」或「不通过」开头，门禁只认开头的结论，证据与结论是否一致由独立审查和人核对。用户不必填写 Markdown 或亲跑命令。本地文件不是身份认证，需要强制审批时使用项目自己的权限机制。

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
ai-harness install-skill [--host dsh|codex|claude] [--dest DIR]
ai-harness version | help
```

## 仓库结构

```
bin/ai-harness     # CLI：复制 / 冲突隔离 / 栈探测 / 模块扫描 / 体检 / 装 skill
template/          # 要被复制进目标项目的全部内容（唯一真相源）
skill/SKILL.md     # 共享技能入口：宿主薄入口指向这里，机械步骤交给 CLI，判断步骤交给 Agent
```

## 本仓库自用

根目录也按这套流程开发：`AGENTS.md`、`process/specs/`、`MEMORY.md` 与 Git 保存状态；根目录 `scripts/` 只转发到 `template/scripts/`，机制仍只维护一份。根目录的项目专属阈值与验证命令在 `harness/`。

```bash
bash scripts/ai-resume.sh owner
bash scripts/ai-gate.sh status
bash scripts/harness-selftest.sh
```

本仓库在接入前已有 Git 历史和 `main` 分支，因此自用接入保留原仓库；没有重新执行 `git init`。接入记录已归档在 `process/specs/archive/2026-10/feat-self-hosting/`。

`template/` 里包含：`AGENTS.md`（L1 入口）、`MEMORY.md`（踩坑池）、`docs/`（轻量需求入口 + 模块活文档 + Spec 与验证摘要模板 + 度量）、
`scripts/`（ai-task-pool / ai-gate / ai-verify / ai-resume / ai-new-spec / ai-state-id / ai-config / ai-check-bloat / harness-selftest）、
`harness/redlines.conf`（唯一阈值来源）、`MEMORY.md`（踩坑记忆）、`.agents/skills/`（阶段技能）。
通用 CI 接入命令见 `template/harness/CI.md`；覆盖率和变异测试阈值须由目标项目的 CI 实现，并用低于阈值的样本确认失败路径。未接线时配置值不代表检查已通过。
老项目 `retrofit --dry-run` 只读；正式接入不会覆盖已有文件、删除同名示例文件或自动改写红线。目录扫描结果放在 `.ai-harness/suggested/` 供审核。
升级与降级不提供命令：让项目 AI 按 `template/.agents/skills/retrofit-legacy.md` 的「升级与降级」比对目标版本 `template/` 手动完成，项目状态与红线不替换；跨版本的目录变化（如 2.0 把 Spec、任务池与度量移到顶层 `process/`）写在同一处的版本说明里。

若旧项目的红线配置缺少必要键或值无效，脚本会指出键名并停止；维护者按项目需要补齐 `harness/redlines.conf` 后再运行。脚本不使用另一套隐含默认阈值。
示例领域图与路线图不会复制进老项目，避免把虚构架构当成项目事实。

单一事实来源按项目划分：`template/scripts/` 是分发机制源码；`template/harness/redlines.conf` 是新项目初始样本；安装后的项目各自以自己的 `harness/redlines.conf` 为阈值来源。根目录 `scripts/` 是薄转发，根目录 `harness/redlines.conf` 只属于本仓库。指南与 Spec 模板只引用配置键；当前工作状态由项目内 Spec、活文档和 Git 记录。

## Claude Code ↔ Codex 接力

项目内 `AGENTS.md`、当前 Spec 的 `tasks.md` / `.gates` / `verification.md` 和 Git 改动是持久状态；
`CLAUDE.md` 仅导入 `AGENTS.md`，不存另一份规则。`.agents/skills/*.md` 是按需读取的普通项目指南。
本地 `reports/` 保存详细验证日志，`verification.md` 保存可入库的摘要。

```bash
bash scripts/ai-resume.sh owner feat-example
bash scripts/ai-resume.sh worker feat-example 2          # 只接 Task 2
bash scripts/ai-resume.sh review feat-example HEAD~1      # G5：改为本次变更前的实际提交
bash scripts/ai-verify.sh --quick --spec feat-example src/example.ts  # 需配置 QUICK_CHECK；不生成 G4 摘要
bash scripts/ai-verify.sh --spec feat-example src/example.ts
bash scripts/ai-gate.sh status feat-example
bash scripts/ai-gate.sh metrics feat-example
```

换 IDE 且使用同一工作区，可直接接手未提交改动；换 worktree 或电脑时，须用 Git 提交或补丁传递未提交代码。
接手命令必须显式选择 `owner`、`worker` 或 `review`；旧式 `ai-resume.sh [feat]` 会报错并提示新用法。worker 读取指定任务的项目原件；review 独立读取需求、完整相关 diff 与验证摘要，不接收实现者的自评作为审查依据。
没有 Git 时摘要只能检测目标文件本身的变化，因此完整的跨工作区接力应使用 Git。
G4 只认不带 `--quick` 的正式验证摘要。状态指纹全仓计算，只排除 `process/`：其下的 Spec、任务池与度量是流程记录，不计入指纹，Spec 进行中收录任务不会使摘要过期。修改相关代码或暂存后请重验；相同索引内容提交后指纹保持稳定。TTY 和本地红线哈希只防误操作；
首次正式 G4 前，先对照需求原文、AC、设计文件清单和实际交付物，检查 `git status --short` 中的未跟踪、未暂存及已暂存文件；项目检查可同时运行 `git diff --check` 和 `git diff --cached --check`。quick 适合短反馈，不能替代完整验证。本仓库的完整验证先做双区 diff，再跑自检和 CLI 回归；本地报告逐阶段打印耗时，便于依据实测定位慢阶段。
需要强制人工审批时，用目标项目自己的外部权限机制。

## 设计取舍

- **升级只写说明**：升级、降级与迁移不写代码，由项目 AI 照说明比对合并；兼容代码只会越积越多。
- **不覆盖、不猜测**：老项目的 `AGENTS.md`、`00-INDEX.md` 可能已有团队约定，合并是判断题，不是复制题。
- **过时内容归档而非删除**：被取代的旧文档移入 `process/specs/archive/`，保持单一真相。
- **模板即实例**：这个仓库自身就是可运行的脚手架（`template/` 内可跑 `harness-selftest.sh` 自检）。
