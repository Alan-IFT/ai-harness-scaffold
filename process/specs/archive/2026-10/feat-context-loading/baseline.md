# 接手加载量基线：feat-context-loading

## 计数口径

- 样本：本仓库的 `feat-context-loading` 活跃 Spec；Git HEAD `ea84691`，工作区含本 Spec 未提交文件。
- 旧入口：`bash scripts/ai-resume.sh feat-context-loading`。旧脚本副本与原始输出留在本 Spec 的本地 `reports/`，不入库。
- 字节：PowerShell 重定向的 UTF-8 文件长度（`Get-Item.Length`）；新旧脚本复测均用相同方法。它是脚本输出量代理指标，不是模型实际输入 token。
- 重复材料项：按输出章节计数。限定 worker 不需要全局体积体检、完整七门表、所有未提交路径、最近三次提交、全局知识 TTL 与通用五条接力指令；这些是六类候选重复项。审查者仍需独立读取需求、diff 与验证证据，不将其列为浪费。
- 实际读取路径：按接手命令和被调用脚本的文件读取语句逐项审计；路径存在性检查与读取正文分开记录。Git 内部对象不逐文件列出，只记录触发它们的命令。宿主自动注入的上下文不可从脚本推断。

## 实施前

| 项 | 数值 / 状态 | 证据 |
| :-- | :-- | :-- |
| 旧入口输出字节 | 4025 bytes | 本地 `reports/resume-before.txt` |
| 单次命令墙钟 | 1834 ms | PowerShell Stopwatch；含脚本启动与 Git 查询 |
| 对限定 worker 无关的章节类别 | 6 类 | 上述计数口径与原始输出 |
| 宿主输入 token | 未知 | 当前工具未提供按子 Agent 分项的可信用量 |
| 端到端需求耗时归因 | 未知 | 无可比的多 Agent 任务样本 |

## 角色样本的项目读取路径

下表用同一套口径列实施前与改后。旧脚本没有角色参数，主 Agent、worker、审查者若都调用旧 `ai-resume.sh <feat>`，都会执行相同读取链；它不代表三类 Agent 实际都曾这样调用。改后 worker 样本为本 Spec 的 Task 5；review 样本使用本 Spec 与基准提交 `ea84691`，四种输出都在修复后正式验证通过的同一工作区状态测量。

| 入口 | 脚本读取正文 / 状态 | 只检查存在或列路径 | Git 命令来源 | 仅输出的后续读取建议 |
| :-- | :-- | :-- | :-- | :-- |
| 旧入口（任意角色） | `AGENTS.md`、`MEMORY.md` 的行数；`harness/redlines.conf`；`docs/specs/active/feat-context-loading/.gates`、`tasks.md` §4、`verification.md` 摘要、`.violations` 计数 | `docs/specs/active/*/`；`.knowledge/cards/K-*.md`（本样本 0 张） | `git status -s`、`git diff --name-only`、`git diff --stat`、`git log -n 3` | 通用五条接力指令，未按角色区分 |
| 新 `owner` | 与旧入口相同；仍用于主 Agent 完整接手 | 与旧入口相同 | 与旧入口相同 | `MEMORY.md`、当前 Spec、相关模块 |
| 新 `worker` | 读取 `docs/specs/active/feat-context-loading/tasks.md` 全文以定位，只输出指定 Task 正文 | 活跃 Spec 目录与 `tasks.md` 存在性 | 无；只提示 Agent 另行运行 `git status --short` | `AGENTS.md`、本 Task 的 WIP、相关 requirements/design 章节与分配文件 diff；脚本没有读取这些正文 |
| 新 `review` | `verification.md` 的 result/target/state；`ai-state-id.sh` 按当前 Spec 读取 `design.md`、验证目标并核对代码状态 | `requirements.md`、`design.md`、`tasks.md`、`verification.md` 的存在性 | `git rev-parse`、`git merge-base`、`git diff --name-only`、`git ls-files --others` | 独立读取需求原文与 AC、设计矩阵、完整 diff、验证摘要和 code-review 指南；脚本没有代读这些原件 |

证据路径：旧脚本本地副本 `reports/ai-resume-before.sh`、新脚本 `template/scripts/ai-resume.sh`、`ai-check-bloat.sh`、`ai-gate.sh`、`ai-knowledge.sh ttl`、`ai-state-id.sh` 的调用路径，以及本地 `reports/resume-*-final-state.txt` 原始输出。最初的 4025 字节测量时 `verification.md` 尚无可用目标；下面同状态复测在正式 G4 后执行，旧版和 owner 会额外校验状态指纹。

## 同一状态的旧版与新版对比

修复三项审查问题并重新正式验证后，连续运行保存的旧脚本、新 `owner feat-context-loading`、`worker feat-context-loading 5` 与 `review feat-context-loading ea84691`。四条命令在同一工作区和同一 Spec 上按上述 UTF-8 重定向方法测量；原始输出留本地 `reports/resume-*-final-state.txt`。先前 5629 / 1341 字节的测量是实施中间状态，不用于最终 AC 判定。

| 入口 | 输出字节 | 单次命令墙钟 | 对限定 worker 无关的章节类别 |
| :-- | --: | --: | --: |
| 旧 `ai-resume.sh feat-context-loading` | 5792 | 2081 ms | 6 |
| 新 `ai-resume.sh owner feat-context-loading` | 5792 | 2021 ms | 主 Agent 需要完整接手，不计为 worker 的重复项 |
| 新 `ai-resume.sh worker feat-context-loading 5` | 1237 | 152 ms | 0 |
| 新 `ai-resume.sh review feat-context-loading ea84691` | 1367 | 742 ms | 0；仍须独立读取原始审查证据 |

- 限定 worker 输出减少 `4555 / 5792 = 78.6%`，达到 AC-01 的 30% 目标。worker 输出只含 Task 5 条目、相关原件路径和变更前核对命令；review 输出减少 `4425 / 5792 = 76.4%`，但审查者必要的独立读取没有纳入这项节省。
- 四次墙钟数据都是单次本机命令结果，受 Git 状态、进程启动和缓存影响；只说明这次脚本运行，不代表 AI 需求端到端耗时按相同比例缩短。
- 宿主输入 token、真实跨 Agent 重复加载量、需求端到端耗时仍为「未知」；后续有可信分项数据才能做因果比较。
