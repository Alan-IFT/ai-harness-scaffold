# 审查：feat-t-000047

- 审查者：独立审查上下文（未参与实现与方案） / Claude Sonnet 5.5 / 单次子会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：8aaeac319197e2da0ad0b5d3a83163290607009cf50d9033218baf99879787d8
- 审查范围：f397834...HEAD + 工作区

## 结论
- 关键问题：1
- 改进建议：4
- 人工决定：<待维护者当次决定>
- 决策来源：<待维护者当次决定>

「需人决定：是」判得对：改的是规则入口（哪些改动免三道门、记忆写在哪），属 new-spec.md:12 的架构取舍。AC-01～AC-09 的证据命令我都重跑，全部达到通过条件；问题出在 AC-06 要求写进 README 的那句话本身不成立。

## 关键问题
1. README.md:226 末尾「门禁脚本和状态指纹在两边结果一致」「WSL 下只是实测一致」，本机实测不一致。
   - 现象：同一工作区、同一目标文件，Git Bash 下 `bash template/scripts/ai-state-id.sh template/AGENTS.md` 得 8aaeac31…，用 `wsl.exe -e bash -c "cd /mnt/d/… && bash template/scripts/ai-state-id.sh template/AGENTS.md"` 得 785b6a1a…。
   - 原因（已查实）：`git ls-files --others --exclude-standard` 在 WSL 里多列出 `.claude/settings.local.json`。它在 Git Bash 里被 Windows 用户目录下的全局忽略文件忽略，WSL 的 `~` 是另一个目录，读不到这份全局忽略，于是该文件按「未跟踪文件」进了指纹（ai-state-id.sh 的 untracked 循环）。与 `.gitattributes` 换行无关。
   - 后果：README 与 `.gitattributes` 新注释（.gitattributes:1，「统一后两边算出的状态指纹才一致」）把「换行统一」写成两边一致的充分条件，实际全局忽略差异同样会让指纹分叉；在 WSL 里验证后回 Git Bash 做 g3，会得到 state 不一致。
   - 期望：把 README 这句改成与实测相符的限定（例如指纹按「未被忽略的未跟踪文件」计算，两边的全局忽略配置不同时可能不一致，门禁以实际运行门禁的那个环境为准），删掉「WSL 下只是实测一致」或写明实测条件；两处 `.gitattributes` 注释同理收窄。
   - 说明：我这次为实验在 WSL 里跑了 `ai-verify.sh`，它覆盖写了 verification.md（state 改成 785b6a1a…，时间戳变）。这是我越出只读的副作用，我没能还原（还原被权限拒绝）；请维护者对该文件执行 `git checkout -- process/specs/active/feat-t-000047/verification.md`，之后在 Git Bash 里重跑验证即可。本报告「审查状态」写的是提交里的原值。

## 改进建议
1. README.md:226「PowerShell 里的 `bash` 通常是 WSL」说过头：本机 PowerShell 里 `Get-Command bash -All` 依次为 Git 的 `bash.exe`、`System32\bash.exe`（WSL 启动器）、WindowsApps 的 `bash.exe`，首个是 Git Bash，取决于 PATH 顺序。建议改成「取决于 PATH，PowerShell 里可能是 WSL」。
2. README.md:226 的「CUSTOM_CHECK 在调用它的那个环境里运行」我核实了方向对（ai-verify.sh 用 `bash -c`），但 WSL 里 `which bash`、`git`、`~`（/home/…）确与 Windows 不同，这部分属实；「依赖要两边都能用」可顺带点出 Git 全局配置（如 core.autocrlf：本机 Git Bash 为系统级 true，WSL 内为空）也是两边不同的，正是建议 1 之外的同类来源。
3. docs/architecture/modules/guidance.md:12「Claude Code 的记忆里却有 6 条，其中 2 条只存在那里」是 2026-11-09 的一次性计数，属个人环境信息；原因句保留即可，计数可删，少写一次性经验。
4. template/AGENTS.md:7 小改动出口写的是「源码注释和说明文档」，但没有说「直接提交」时是否还要跑 `ai-verify`/自检；且 `docs/` 在接入项目里含模块活文档（规则性内容），「不改变意思」靠 AI 自判。可钻空子的余地不大（拿不准就收录兜底、有活跃 Spec 不放行），不阻塞。

## 证据
- 验证：verification.md 的 result PASS / state 8aaeac31…（提交版）；我重跑 `bash scripts/harness-selftest.sh`：76 项断言，失败 0 项；`bash scripts/ai-check-bloat.sh`：OK。
- AC-01～03、05、06、07、08 的 grep 命令输出均为 1；AC-04 `wc -l` 为 39；AC-05 的非注释增删行为 0；`git check-ignore -q PREFERENCES.md` 退出 0、`git status` 不含它、`test -s` 退出 0（未读其内容）。
- AC-03 措辞核对：`ai-task-pool.sh:56` 允许的队列状态为 待办|暂缓|取消，与 AGENTS.md:7 一致。
- 与其它文件矛盾检查：根 AGENTS.md「只支持 Windows」未动；README 新句仍说只支持 Windows，与「WSL 可用」不冲突；guidance.md 新增两条与 template/AGENTS.md 说法一致；MEMORY.md 新条目引用的归档文件存在。
- WSL 核实：能核实的有 WSL 存在（Ubuntu v2）、`~` 为 /home/…、Git Bash 系统级 core.autocrlf=true 而 WSL 为空、`CUSTOM_CHECK` 运行环境；不能核实「通常是 WSL」的普遍性（只有本机一例）、「CI 只在 Git Bash 上跑」（未看 CI 实际运行记录，只见 workflow 文件）。
