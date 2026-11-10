# 需求：feat-t-000048

- 创建时间：2026-11-10
- **需求来源**: `process/task-pool/T-000048.md`（原始需求与更新）
- 原始问题 / 原话：1.偶尔用codex、DeepSeek harness，你帮我决策吧;2.你帮我决策吧；3.你帮我决策吧（维护者 2026-11-10 对三个问题的答复：① CI 加不加 Linux，取决于平时有没有用 Git Bash 以外的工具；② Claude Code 自带记忆里和项目文件重复的条目删不删；③ 现在发版还是等后续改动一起发）
- 需人决定：否。不改模板、脚本和对外承诺（「只支持 Windows」原样保留），只给本仓库的 CI 加一个运行环境、改几句说明、给活文档补一条依据；加不加这件事已经问过维护者，维护者说明了用哪些工具并把决定交给 AI。发版不在本需求里。

## 1. 要做什么
- 做什么：本仓库的 CI 除了 `windows-latest`，再在 `ubuntu-latest` 上跑同一份自检，README 和活文档里说 CI 只在一处跑的三句话跟着改；把只记在 Claude Code 自带记忆里的最后一条依据（为什么保留只有一行导入的 `CLAUDE.md`）写进活文档，并去掉活文档里已经不准的一次性计数。
- 为谁做：偶尔用 Codex、DeepSeek harness 这类不一定走 Git Bash 的工具的维护者：改动把 Linux 的 bash 弄坏时，CI 先报出来。
- 不做：
  - 不放开平台：README 的前置条件和徽章、根 `AGENTS.md`、ADR-0003 的「只支持 Windows（Git Bash）」都不动；不加任何兼容代码；不改 `template/` 和 `skill/`。
  - 不检查 Git Bash 与 WSL 的状态指纹是否一致（README 已如实写明可能不同）。
  - 清理 Claude Code 那边的记忆目录是本机操作，不属于仓库改动，不列验收；本需求归档后单独做。
  - 发版（问题 ③）：结论是不等后续改动，本需求归档、CI 通过后发 v2.1.4，作为单独动作执行，不在本需求的门里。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | CI 在 `windows-latest` 和 `ubuntu-latest` 上各跑一遍自检，一边失败不取消另一边；触发条件、权限和步骤不变 | `grep -c 'os: \[windows-latest, ubuntu-latest\]' .github/workflows/selftest.yml` 输出 1；`grep -c 'fail-fast: false' .github/workflows/selftest.yml` 输出 1；`git diff 7964c11 -- .github/workflows/selftest.yml` 里 `on:`、`permissions:`、`steps:` 三段没有增删行 |
| AC-02 | 改动推送后，CI 的两个任务都成功 | `gh run view <run-id> --json jobs --jq '.jobs[].name, .jobs[].conclusion'` 输出四行：两个任务名分别含 `windows-latest` 与 `ubuntu-latest`，两个结论都是 `success`；run-id 记在 tasks.md 的 WIP 区 |
| AC-03 | README 里说 CI 在哪跑的两处与实际一致，并写明 Linux 那一份是替 WSL 把关、不代表支持 Linux；「只支持 Windows」的说法不变 | `grep -c 'CI 只在 Git Bash 上跑' README.md` 输出 0；`grep -c '替 WSL 把关，不代表支持 Linux' README.md` 输出 1；`grep -c 'windows-latest. 和 .ubuntu-latest' README.md` 输出 1；`grep -c '只支持 Windows' README.md AGENTS.md` 各输出 1 |
| AC-04 | 活文档 `self-hosting.md` 的 CI 一条写明两个运行环境各自的理由，以及这不代表支持 Linux、CI 配置不装进接入项目 | `grep -c 'ubuntu-latest.*替 WSL 把关.*不代表支持 Linux.*不装进接入项目' docs/architecture/modules/self-hosting.md` 输出 1；`grep -c '与支持的平台一致' docs/architecture/modules/self-hosting.md` 输出 0 |
| AC-05 | 活文档 `guidance.md` 写明为什么保留只有一行导入的 `CLAUDE.md`，内容与 Claude Code 官方文档当天的说法一致；「自带的记忆不作来源」那条不再写一次性的条数 | `grep -c '为什么保留只有一行导入的 .CLAUDE.md' docs/architecture/modules/guidance.md` 输出 1；`grep -c 'CLAUDE.local.md' docs/architecture/modules/guidance.md` 输出 1；`grep -c '[126] 条' docs/architecture/modules/guidance.md` 输出 0；官方文档 `code.claude.com/docs/en/memory` 的「AGENTS.md」一节可对照 |
| AC-06 | 自检在 Git Bash 下通过，体积检查通过，正式验证通过 | `bash scripts/harness-selftest.sh` 失败 0 项；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000048 docs/architecture/modules/self-hosting.md` 为 PASS |
