# 审查：feat-t-000048

- 审查者：独立审查上下文（subagent，未参与实现）/ 模型 Sonnet 5.5 / 首轮
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：c0ca76a1bf9b926ce0c9304be35ed8115b97ef61655f42cc1e26231dfd53cce5
- 审查范围：7964c11...HEAD（fb05dda）+ 工作区（工作区干净，审查前 `git status --short` 无输出）

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：无需人工决定。我独立判断「需人决定：否」成立：本次改动只含 CI 矩阵、README 与活文档的措辞、一条依据说明，不涉及数据、权限、发布、架构取舍或不可逆操作（new-spec.md Step 1 第 3 点）；「只支持 Windows」的对外承诺在 README 与根 AGENTS.md 里原样保留；发版被需求明确划出范围。
- 决策来源：不适用（「需人决定：否」；维护者 2026-11-10 已就三个问题答复「你帮我决策吧」，见 requirements.md 原话）

## 关键问题
无

## 改进建议
1. `ubuntu-latest` 是浮动标签：tasks.md WIP 记了运行日志提示它将改指 Ubuntu 26。以后换底座可能让 CI 在没有代码改动时变红。此时应先查原因，不要为它写兼容代码；可记进 `self-hosting.md` 的「发现但不碰」，不阻塞。
2. `docs/architecture/modules/guidance.md:5` 没提官方文档给出的另一条路：用户级设置 `claude-md-and-agents-md` 能让 `CLAUDE.local.md` 与 `AGENTS.md` 同时加载（官方文档 AGENTS.md 一节）。这个设置在用户级，仓库无法替用户设置，所以结论「保留导入」仍成立；日后复核时看一眼即可。

## 证据
- 验证：verification.md result PASS；其 state 与当前 `bash scripts/ai-state-id.sh docs/architecture/modules/self-hosting.md` 输出一致（c0ca76a1…ce5）。`ai-gate.sh status`：g1、g2 已过，g3 待审。HEAD 比验证状态晚的提交只动 `process/`，不进指纹。
- AC-01 通过：`grep -c 'os: \[windows-latest, ubuntu-latest\]'` 输出 1，`grep -c 'fail-fast: false'` 输出 1；`git diff 7964c11 -- .github/workflows/selftest.yml` 只增删注释、`strategy:` 块与 `runs-on:` 一行，`on:`、`permissions:`、`steps:` 无增删行。
- AC-02 通过：`gh run view 42800588786 --json jobs --jq ...` 输出 `selftest (ubuntu-latest)`、`selftest (windows-latest)`、`success`、`success`；`--json headSha,event,status` 输出 headSha d5ba3f8b…、event push、status completed。d5ba3f8 即 ci 改动提交（`git log` 确认），且是 7964c11 之后唯一动 CI 与 README/活文档措辞的提交，CI 测的就是被审内容。
- AC-03 通过：`CI 只在 Git Bash 上跑` 0；`替 WSL 把关，不代表支持 Linux` 1；`windows-latest. 和 .ubuntu-latest` 1；`只支持 Windows` 在 README.md、AGENTS.md 各 1。
- AC-04 通过：`ubuntu-latest.*替 WSL 把关.*不代表支持 Linux.*不装进接入项目` 1；`与支持的平台一致` 0。
- AC-05 通过：`为什么保留只有一行导入的 .CLAUDE.md` 1；`CLAUDE.local.md` 1；`[126] 条` 0。我自己抓取了 code.claude.com/docs/en/memory 的「AGENTS.md」一节，逐句对照 `guidance.md:5`：
  - 「默认只在工作目录及上级都没有 CLAUDE.md、CLAUDE.local.md 时才读」：与官方「reads AGENTS.md only when you have no CLAUDE.md in your working directory or above」及 `.claude/CLAUDE.md`、`CLAUDE.local.md` 都计入一致。
  - 「一加 CLAUDE.local.md，规则整份不再加载」：与官方「adding one … stops Claude from reading AGENTS.md for you」一致。
  - 「有些会话读不到」：官方「When AGENTS.md support is unavailable」（插件被禁用、升级后首个会话、v2.1.281 前 Bedrock 或关闭遥测）。
  - 「保留导入不会读两遍」：官方「Keeping the import never makes Claude read AGENTS.md twice」。
  - 官方对「只有一行导入的 CLAUDE.md」是「可留可删，有会话读不到就留」，本条与之不矛盾。
- AC-06 通过：`bash scripts/harness-selftest.sh` 输出「76 项断言，失败 0 项」；`bash scripts/ai-check-bloat.sh` 输出 🟢 体积正常；正式验证见上。
- 他处有无被本次改动弄成假话：grep `README.en.md`、根 `AGENTS.md`、`MEMORY.md`、`skill/SKILL.md`、`template/`、`docs/` 里的 CI 运行环境与「6 条」等计数，只剩 README 两处与 `self-hosting.md` 一处，均已同步；ADR 里的 CI 字样是「已删除的 CI 文档」，不受影响；README.en.md 没提 CI。未发现新的过时句子。
- 越界检查：diff 只含四个计划内文件，加 `process/` 记录；`template/`、`skill/`、脚本、红线均未动。文件与说明中无本机路径、用户名、邮箱或非公开项目名。
- 未能核实：Claude Code 记忆目录的清理属本机操作，不在仓库内，未检查。
