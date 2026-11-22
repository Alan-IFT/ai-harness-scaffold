# 需求：feat-t-000057

- 创建时间：2026-11-21
- **需求来源**: `process/task-pool/T-000057.md`（原始需求与更新）
- 原始问题 / 原话：「都按推荐」（维护者 2026-11-21 对 feat-t-000056 汇报里三件事的答复；归本 Spec 的两件是：「先提交代码再跑」换成直接指标再比一次，有增量才加回；`guidance.md` 补上多跑之后的两个新数。给他的选项原文见任务文件）
- 需人决定：否。只涉及 `template/AGENTS.md`「验证」一条的半句操作提示（留不留看对照）和活文档里的两个数字，不改脚本和门的判定，不涉及数据、权限、发布和不可逆操作；做法和判定办法维护者已选定。

## 1. 要做什么
- 做什么：两件事，都是维护者看过 feat-t-000056 的汇报后选定的。
  - 把 feat-t-000056 里试过又撤回的那半句「先提交代码再跑」原样加回 `template/AGENTS.md`，换一个直接的指标再做一次新旧对照：看第一次正式验证之前业务代码有没有先提交。有增量就留下，没有就撤回。
  - `docs/architecture/modules/guidance.md`「为什么「待确认问题」按后果划线」一条补上两个新数：清楚的需求 7 次里 2 次被多问；同一份样本上 Sonnet 5.5 审查者带着那半句 8 次里只拦了 2 次。
- 为谁做：照规则干活的 AI 和它的维护者：少重跑一次正式验证；看活文档的人不再按只跑过 1 次、3 次的旧数字判断。
- 不做：
  - 不换那半句的写法，不为了留下它再换指标或加跑。
  - 不改「待确认问题」规则和审查半句本身：多问、拦截率低只如实记下，维护者说了先用用看。
  - 不改脚本，不启用 `T-000051`，不打 tag、不发版、不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。基准提交是 `839cd1c`。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | AC-02 的结论是「有增量」时，`template/AGENTS.md` 的「验证」一条带着那半句，只改这一行；是「无增量证据」时，这个文件与基准提交相同 | 有增量：`grep -c '先提交代码再跑（验证后再 .git add.，状态指纹会变，验证就过期）' template/AGENTS.md` 输出 1，`git diff --numstat 839cd1c -- template/AGENTS.md` 为 1 行新增、1 行删除，文件仍是 40 行。无增量证据：`git diff --stat 839cd1c -- template/AGENTS.md` 无输出 |
| AC-02 | 换直接指标的新旧对照，如实下结论。同一句清楚的需求（「给 export_orders.py 加一个 --version 参数，输出 1.0.0」，人在场，显式指定 Sonnet 5.5），两个沙箱基准只差那半句，旧新各跑 3 次 | 指标：主 AI 第一次运行 `bash scripts/ai-verify.sh --spec` 之前，业务代码是否已经提交。判法：取宿主落盘的运行记录里那条命令的开始时间，和沙箱 Git 历史里第一个改到 `export_orders.py` 的提交的时间比；提交在前算「已提交」；提交和验证写在同一条命令里的，按命令里的先后算；一直没提交过代码就跑验证的算「没提交」。结论写法：「已提交」的流程数新文字多于旧文字，记「有增量」，保留半句；否则记「无增量证据」，撤回。流程中途停下来问问题或等同意的，以维护者身份回「按推荐」或「同意」，两边一样处理。每次流程的判定、正式验证通过的次数和有没有验证过期的提示，都记进 tasks.md 的 WIP 区；后两项只作参考，不参与判定 |
| AC-03 | 活文档补上两个新数，并指向出处；那半句留下时再写一条为什么 | `grep -c '先后跑了 7 次，有 2 次停在 g1 问了输出格式这类细节' docs/architecture/modules/guidance.md` 输出 1；`grep -c '共审了 8 次，只有 2 次拦了' docs/architecture/modules/guidance.md` 输出 1；`grep -c 'feat-t-000056/tasks.md' docs/architecture/modules/guidance.md` 输出 1。半句留下时 `grep -c '为什么写明正式验证前先提交代码' docs/architecture/modules/guidance.md` 输出 1，撤回时输出 0 |
| AC-04 | 不新增文件，脚本不变；自检、体积检查、正式验证通过 | `git ls-files --others --exclude-standard -- . ':(exclude)process'` 无输出；`git diff --name-status 839cd1c -- . ':(exclude)process'` 每行都以 `M` 开头；`git diff --stat 839cd1c -- template/scripts scripts template/harness harness` 无输出；`bash scripts/harness-selftest.sh` 末尾为「77 项断言，失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000057` 为 PASS |

## 3. 待确认问题
> 要交人定的点（判据见 `AGENTS.md`「待确认问题」）列出选项、后果和推荐让人选，不替人拍板；人回答后改成 `- [x] 问题 → 结论（日期：答复原话）`。没有就删掉下面这行。
- [x] 要不要再比、怎么比、活文档补不补，都在 feat-t-000056 的汇报里给过选项 → 都选 A（2026-11-21：「都按推荐」）；选项原文记在任务文件的「补充与变更」
