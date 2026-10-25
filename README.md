# ai-harness — 跨工具 AI 辅助开发脚手架

一套 **host 无关**的开发规范：需求入口、三道门（计划 / 验证 / 审查）、增量验证、独立审查、记忆积累和交付反馈。
没有安装命令：由 AI 按 `skill/SKILL.md` 把 `template/` 接入新项目或老项目，遇到特殊情况由 AI 判断，拿不准再问人。

> 面向 Claude Code / OpenAI Codex / Cursor / OpenCode / DeepSeek 等任何能读 `AGENTS.md`、能跑 bash 的 AI 工具；只支持 Windows（Git Bash）。

## 用法：直接跟 AI 说

```
用 ai-harness 脚手架初始化 D:\code\my-new-project
把 D:\code\legacy-project 接入 ai-harness 脚手架
把 D:\code\legacy-project 的脚手架升级到最新版
```

AI 读 `skill/SKILL.md`（本仓库路径告诉它即可）完成摸底、计划、合并、验证命令、一个模块试点和体检，只把架构、权限、阈值这类需要你决定的事交回来。
想让宿主自动发现这个技能，可以让 AI 在宿主的用户技能目录（如 `~/.claude/skills/ai-harness-scaffold/`、`~/.codex/skills/ai-harness-scaffold/`）放一个只写「先读 `<本仓库>/skill/SKILL.md`」的薄 `SKILL.md`。

装好后，在项目里开场跑：

```bash
bash scripts/ai-resume.sh owner    # 主 Agent 接手快照：门状态、WIP、git 残局
bash scripts/ai-gate.sh status     # 三道门：计划 / 验证 / 审查
bash scripts/ai-task-pool.sh next  # 当前工作；维护者直接用自然语言说需求
```

维护者直接告诉 AI 新需求或补充，无需运行命令。AI 用 `ai-task-pool.sh intake` 保存原话：有活跃 Spec 就排队并续做；没有就启动人工指定或最早录入的待办，空池则启动刚提出的需求。说“先做某项”即可让 AI 指定下一项。需求澄清后写 requirements.md（原话、是否需人决定、验收标准）与 tasks.md（方案、任务、WIP），过 g1（计划）再编码；任务完成后正式验证过 g2；换一个没写过代码的上下文审查过 g3，涉及数据、权限、发布或架构取舍的需求还要人当次决定。门只检查骗不过的信号，文字质量交给独立审查与人。

人的决定记在 `review.md` 的「人工决定」与「决策来源」，由 Agent 记录人的原话结论，用户不必填写 Markdown 或亲跑命令。本地文件不是身份认证，需要强制审批时使用项目自己的权限机制。

## 仓库结构

```
template/          # 接入目标项目的全部内容（唯一真相源）
skill/SKILL.md     # 接入、升级、降级的做法，由 AI 照着判断执行
scripts/           # 只转发到 template/scripts/，本仓库自己也用这套流程
tests/             # 本仓库的验证入口
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
通用 CI 接入命令见 `template/harness/CI.md`。
接入老项目时先列计划再动手，不覆盖已有文件、不删除同名示例文件、不自动改写红线。
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
bash scripts/ai-resume.sh review feat-example HEAD~1      # 独立审查：改为本次变更前的实际提交
bash scripts/ai-verify.sh --quick --spec feat-example src/example.ts  # 需配置 QUICK_CHECK；不生成验证摘要
bash scripts/ai-verify.sh --spec feat-example src/example.ts
bash scripts/ai-gate.sh status feat-example
bash scripts/ai-gate.sh metrics feat-example
```

换 IDE 且使用同一工作区，可直接接手未提交改动；换 worktree 或电脑时，须用 Git 提交或补丁传递未提交代码。
接手命令必须显式选择 `owner`、`worker` 或 `review`；worker 读取指定任务的项目原件；review 独立读取需求、完整相关 diff 与验证摘要，不接收实现者的自评作为审查依据。
没有 Git 时摘要只能检测目标文件本身的变化，因此完整的跨工作区接力应使用 Git。
g2 只认不带 `--quick` 的正式验证摘要。状态指纹全仓计算，只排除 `process/`：其下的 Spec、任务池与度量是流程记录，不计入指纹，Spec 进行中收录任务不会使摘要过期。修改相关代码或暂存后请重验；相同索引内容提交后指纹保持稳定。TTY 和本地红线哈希只防误操作；
正式验证前，先对照需求原文、AC 和实际交付物，检查 `git status --short` 中的未跟踪、未暂存及已暂存文件；项目检查可同时运行 `git diff --check` 和 `git diff --cached --check`。quick 适合短反馈，不能替代完整验证。本仓库的完整验证先做双区 diff，再跑自检；本地报告逐阶段打印耗时，便于依据实测定位慢阶段。
需要强制人工审批时，用目标项目自己的外部权限机制。

## 设计取舍

- **升级只写说明**：升级、降级与迁移不写代码，由项目 AI 照说明比对合并；兼容代码只会越积越多。
- **不覆盖、不猜测**：老项目的 `AGENTS.md`、`00-INDEX.md` 可能已有团队约定，合并是判断题，不是复制题。
- **过时内容归档而非删除**：被取代的旧文档移入 `process/specs/archive/`，保持单一真相。
- **模板即实例**：这个仓库自身就是可运行的脚手架（`template/` 内可跑 `harness-selftest.sh` 自检）。
