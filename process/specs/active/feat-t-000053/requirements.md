# 需求：feat-t-000053

- 创建时间：2026-11-12
- **需求来源**: `process/task-pool/T-000053.md`（原始需求与更新）
- 原始问题 / 原话：「那就把建议收成spec?」（维护者 2026-11-12 对博客评估结论的答复；「建议」指 AI 评估后提出的两处，评估请求的原话和两处的出处、证据见任务文件）。同日补充：「那就按推荐处理，撤掉第1处」（维护者看过两处的实现、对照演练的结论和独立审查结果后的答复；「推荐」是 AI 给的选项里撤掉模板记忆信号、只留演练约定的那一个）
- 需人决定：是。留下的一处改的是本仓库的规则入口：改接入、升级说明后怎么验证。以后每次改这两份说明都多一次换上下文的演练，一字之改也不例外，这点成本要维护者看过最终结果后在 g3 当次决定。同日那句补充定的是撤掉第 1 处，不当作对最终结果的「通过」。

## 1. 要做什么
- 做什么：根 `AGENTS.md` 把「改完在临时目录照着做一遍」从接入说明扩到升级说明，并写明由没参与改动的上下文来做；原因写进模块活文档 `install-skill.md`。评估的另一处建议（`template/AGENTS.md` 把「审查判出的关键问题」列为记忆信号）实现后做了新旧文字的对照演练，结论是「无增量证据」，维护者决定撤掉：`template/AGENTS.md` 与 `guidance.md` 改回基准提交的内容。
- 为谁做：本仓库改接入、升级说明的 AI 和维护者，说明里的含糊在发版前被照着做的上下文发现。
- 不做：
  - 不加文件、脚本、配置键；脚本一行不改；不改门禁与红线。
  - 不改模板：`template/` 与基准提交一致，接入项目不受影响。
  - 评估里判为不取的做法（清单见任务文件）。
  - 不补记 feat-t-000047 那条教训进本仓库 `MEMORY.md`，不补升级演练里还没补的两处含糊：记在「发现但不碰」，由维护者决定。
  - 不打 tag，不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 第 1 处撤干净：`template/` 与 `docs/architecture/modules/guidance.md` 和基准提交一致，`process/` 以外不再有「审查判出的关键问题」这几个字 | `git diff --stat 7445381 -- template docs/architecture/modules/guidance.md` 无输出；`git grep -c '审查判出的关键问题' -- . ':(exclude)process'` 无输出 |
| AC-02 | 根 `AGENTS.md` 与活文档 `install-skill.md` 都写明：改 `skill/SKILL.md` 或升级说明后，让没参与改动的上下文按它在临时目录实际接入或升级一次 | `grep -c 'upgrade.md.*让没参与改动的上下文按它在临时目录实际接入或升级一次' AGENTS.md docs/architecture/modules/install-skill.md` 两个文件各输出 1；旧句 `grep -c '按它在临时目录实际接入一次新项目' AGENTS.md docs/architecture/modules/install-skill.md` 各输出 0 |
| AC-03 | 这一处的原因写进模块活文档，一条 | `grep -c '为什么改升级说明也要演练' docs/architecture/modules/install-skill.md` 输出 1 |
| AC-04 | 不新增文件，脚本不变；自检失败 0 项，体积检查通过，正式验证通过 | `git diff --name-status 7445381 -- . ':(exclude)process'` 只有 2 行且都以 `M` 开头（`AGENTS.md`、`docs/architecture/modules/install-skill.md`）；`git ls-files --others --exclude-standard -- . ':(exclude)process'` 无输出；`git diff --stat 7445381 -- template/scripts scripts` 无输出；`bash scripts/harness-selftest.sh` 末尾为「失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000053` 为 PASS |
