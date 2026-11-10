# 任务与接力：feat-t-000048

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000048` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：三个问题的决定和依据如下，本需求只落地其中改仓库文件的部分。
  - ① CI 加 Linux：加。维护者偶尔用 Codex、DeepSeek harness，这类工具调到的 `bash` 不一定是 Git Bash（README「安全与局限」已写明可能是 WSL）；它们各自调到哪一个没有逐个核实，所以只说「可能」。做法是把 `runs-on` 改成两项的矩阵，加 `fail-fast: false`（否则一边失败会取消另一边，看不出是哪边坏的），加一行注释说明 `ubuntu-latest` 的用意。不选「正式支持 Linux」：那是对外承诺，要改根 `AGENTS.md` 和 ADR-0003，之后 Linux、macOS 的问题都得接。不选「不加」：现在 Linux 的 bash 只靠本机 WSL 手动跑，没人跑就没人发现。
  - ② 工具记忆：Claude Code 为本仓库记的 6 条里，5 条与项目文件重复（根 `AGENTS.md` 的「少就是多」「仓库已公开」、通用偏好的回复语言、`MEMORY.md` 的评估文章做法、本机 `PREFERENCES.md` 的接入项目版本说明）。只有「为什么保留 `CLAUDE.md` 的导入」项目里没有：`guidance.md` 只写了「`CLAUDE.md` 只做导入」，没写为什么不能删。把这条依据写成 `guidance.md` 的一条，写之前对照官方文档当天的内容复核。同一文件「自带的记忆不作来源」那条里的「6 条、其中 2 条只存在那里」是一次性计数，而且按今天的核对应是 3 条，改成不带数字的说法（上一个 Spec 的审查建议过删计数）。仓库这边改完并提交后，再清工具那边的目录。
  - ③ 发版：不等后续改动，本需求归档、CI 通过后发 v2.1.4。理由：`main` 上的 README 已经在讲最新 tag 里没有的行为；还没定的那批改动会改验证命令的用法，和已经验证过的两批绑在一起发，只会拖住后者；接入项目可以跳过一个版本直接升到后面的。发版是单独动作，不在本需求的门里。
- 改动文件：`.github/workflows/selftest.yml`、`README.md`、`docs/architecture/modules/self-hosting.md`、`docs/architecture/modules/guidance.md`。
- 影响与风险：
  - 依据（2026-11-09 实测）：自检在本机 WSL（bash 5.3、git 2.53）下 76 项全过。GitHub 的 `ubuntu-latest` 不是 WSL，bash 与 git 的版本也不同，所以 AC-02 以推送后的实际运行结果为准；失败就在本需求里查原因，不为它写兼容代码，查不清就撤掉这一项并如实记录。
  - CI 配置只在本仓库，不装进接入项目；模板、脚本一行不改。CI 用时变成两个任务并行，各自几十秒。
  - 搜索过：仓库里提到 CI 运行环境的只有 `README.md` 第 226、252 行和 `self-hosting.md` 第 9 行；`README.en.md` 没提 CI，不改；徽章「Platform: Windows (Git Bash)」是对外承诺，不改。
  - AC-02 要推送后才有证据，所以 Task 1 提交后先推送、等 CI 结果，再做正式验证和审查。推送的是 CI 配置和说明文字，接入项目按 tag 安装，不受 `main` 上未审查提交的影响。
  - 官方文档复核（2026-11-10，`code.claude.com/docs/en/memory`）：Claude Code v2.1.277 起能直接读 `AGENTS.md`，默认只在工作目录及上级没有 `CLAUDE.md`、`.claude/CLAUDE.md`、`CLAUDE.local.md` 时才读；文档明说加一个 `CLAUDE.local.md` 就会让它不再读 `AGENTS.md`；有些会话读不到（内置插件被禁用、升级后的第一个会话、v2.1.281 之前的 Bedrock 或关闭遥测的会话）；保留 `@AGENTS.md` 导入不会读两遍，「有会话读不到就保留」。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：CI 加 `ubuntu-latest`，同步三句说明
  - 对应验收：AC-01、AC-02、AC-03、AC-04
  - 涉及文件：`.github/workflows/selftest.yml`、`README.md`、`docs/architecture/modules/self-hosting.md`
  - 验证：AC-01、AC-03、AC-04 的命令；提交并推送后等 CI，跑 AC-02 的命令
- [x] Task 2：把「为什么保留 `CLAUDE.md` 的导入」写进活文档，去掉一次性计数
  - 对应验收：AC-05、AC-06
  - 涉及文件：`docs/architecture/modules/guidance.md`
  - 验证：AC-05 的命令；全部任务完成后跑自检、体积检查和正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `.github/workflows/selftest.yml` 的 `ubuntu-latest` / 是浮动标签，GitHub 提示它将改指 Ubuntu 26，以后可能在没有代码改动时变红 / 审查的改进建议；变红时先查原因，不为它写兼容代码，查不清就撤掉这一项
- `docs/architecture/modules/guidance.md` 的「为什么保留只有一行导入的 `CLAUDE.md`」/ 没提用户级设置 `claude-md-and-agents-md` 能让 `CLAUDE.local.md` 与 `AGENTS.md` 同时加载；仓库无法替用户设置，结论不变 / 审查的改进建议；日后复核官方文档时一并看

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无
- 已完成：需求与方案
- 已完成：Task 1。AC-01、AC-03、AC-04 的命令都按预期输出。提交 d5ba3f8 推送后的 CI 运行 42800588786：`selftest (windows-latest)` 与 `selftest (ubuntu-latest)` 都是 `success`，两边日志都是「76 项断言，失败 0 项」（AC-02）。运行日志里有一条 GitHub 的提示：`ubuntu-latest` 标签将改指 Ubuntu 26，不影响结果。
- 已完成：Task 2。AC-05 的命令都按预期输出；`guidance.md` 新增一条（现 16 行），官方文档当天的说法见方案里的「官方文档复核」。
- 已排除的方案：正式支持 Linux（对外承诺，见方案 ①）；为不宜入库的事实或记忆另开文件或文件夹（维护者问过，结论是现有四处够用，见 `guidance.md`）
- 已完成：独立审查一轮通过（关键问题 0，改进建议 2，已记入「发现但不碰」）。
- 下一步：归档、推送。本需求之外的两件事：Claude Code 那边的记忆目录已清（与项目文件重复的删除，接入项目版本那条留作备份，因为项目里的副本不入库）；归档后 CI 通过即发 v2.1.4。
