# 需求：feat-t-000039

- 创建时间：2026-10-31
- **需求来源**: `process/task-pool/T-000039.md`（原始需求与更新）
- 原始问题 / 原话：「通过，把1到4收成下一个任务并开始执行；」（「1到4」指 feat-t-000038 归档时 AI 列出的审查建议 ①~④）
- 需人决定：是，与 feat-t-000038 同类：改审查的拦截标准和什么时候叫人（架构取舍），g3 要维护者对结果的当次决定

## 1. 要做什么
- 做什么：补 feat-t-000038 审查留下的 4 处措辞：① 接入指南选验证命令时，现有测试已失败或不稳定（时而通过时而失败）时停下问人；② 审查指南「规则与文档」条拆成两条，让「检查矛盾、过时内容」不再紧挨「按关键问题处理」；③ 关键问题的「加重」写明边界（新增调用点、扩大影响面也算）；④ 审查发现「需人决定」应为「是」时，写明实现者改为「是」后不补审方案、由 g3 的人工决定兜底。
- 为谁做：接入脚手架时选验证命令的 AI、按 `code-review.md` 审查的 AI，以及在 g3 拍板的维护者。
- 不做：不加文件、脚本、配置键；不改门禁脚本逻辑与红线；不做 feat-t-000038 审查建议里维护者没选的 3 条（Go 示例、新项目与试点模块各补一句、`install-skill.md` 提交号顺序）。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `skill/SKILL.md` 验证命令一步写明现有测试已失败或不稳定时停下问人 | `grep -n "时而通过时而失败" skill/SKILL.md` 命中第 2 节第 4 条 |
| AC-02 | `code-review.md` 第 2 步「规则与文档」只含对照记忆与活文档、按关键问题处理的那句；「检查矛盾和过时内容」在单独一条里，同一行不含「按关键问题处理」 | `grep -n "检查有无矛盾" template/.agents/skills/code-review.md` 命中的行不含「关键问题」；`grep -c "规则与文档" template/.agents/skills/code-review.md` 为 1 |
| AC-03 | 关键问题定义写明新增调用点、扩大影响面也算加重 | `grep -n "新增调用点" template/.agents/skills/code-review.md` 命中「关键问题」那一行 |
| AC-04 | 需求条目写明实现者改为「是」后不补审方案、由 g3 的人工决定兜底，仍无例外条款 | `grep -n "人工决定兜底" template/.agents/skills/code-review.md` 命中需求条目；`grep -c -e "除外" -e "例外" template/.agents/skills/code-review.md` 为 0 |
| AC-05 | 自检失败 0；体积检查通过；不新增文件；`guidance.md` 补「不补审方案」的原因；改 `SKILL.md` 后按它在临时目录实际接入一次新项目，接入后的自检、体积检查与门禁状态都通过 | `bash scripts/harness-selftest.sh`；`bash scripts/ai-check-bloat.sh`；提交后 `git diff --stat --diff-filter=A c10990c -- template skill docs` 与 `git status --porcelain -- template skill docs` 都无输出；`grep -n "不补审方案" docs/architecture/modules/guidance.md` 命中；接入记录写进 tasks.md WIP 区 |
