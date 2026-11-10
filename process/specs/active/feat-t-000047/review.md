# 审查：feat-t-000047

- 审查者：独立审查上下文（未参与实现与方案） / Claude Sonnet 5.5 / 单次子会话（复审沿用同一审查上下文）
- 未参与实现：是
- CR 轮次：2 / 4
- 审查状态：ac757ef0ced54a12abbf8dfc62f38f60228fd0a651314968cfc85f340fad8cd2
- 审查范围：本轮修复提交 2cc065d（及其后的验证与门禁提交 23de34c、c3fa11e）相对第一轮审查提交 bae477a；工作区干净

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：<待维护者当次决定>
- 决策来源：<待维护者当次决定>

复审只核对两件事：上轮关键问题是否解决（已解决）；修复是否引入新问题（未发现）。「需人决定：是」仍判得对（规则入口的架构取舍，new-spec.md:12）。

## 关键问题
上轮第 1 条（README 与 `.gitattributes` 称 Git Bash 与 WSL 状态指纹一致）：已解决。
- README.md:226 不再写「结果一致」，改为「两边的 Git 配置各是各的，同一份代码算出的状态指纹可能不同」，点明已知两个原因：换行设置、只被 Windows 侧全局忽略文件忽略的未跟踪文件会被 WSL 计入。与我上轮实测（`.claude/settings.local.json` 导致 785b6a1a… 与 8aaeac31… 之别）一致；`grep -c '结果一致' README.md` 输出 0。
- 「取决于 PATH 里哪个在前」与上轮实测（PowerShell 首个 bash 是 Git Bash，另有 System32、WindowsApps 两个）相符，上轮改进建议 1 已解决。
- `.gitattributes:1`、`template/.gitattributes:1` 改成「不统一的话两边算出的状态指纹不同」。我在临时仓库复测：无 `.gitattributes` 时 Git Bash 克隆出 CRLF 工作区，WSL 里 `ai-state-id.sh` 直接因 CRLF 报语法错（与 Git Bash 的值不同）；加 `* text=auto eol=lf` 重检出后两边同为 593a7089…。表述成立，且没有再写「统一后一定一致」。
- README.en.md:24「Git is configured separately on each side, so a verification made on one can show as stale on the other」不过头；上轮建议 2（提及两边 Git 配置不同）已由 README.md 的「两边的 Git 配置各是各的」覆盖。
- 修复没有引入新问题：本轮除 requirements.md 的 AC-05/06、tasks.md、`.gates`、verification.md 外只动了上述 4 个文件的各 1 行；README 其余句子（CUSTOM_CHECK、`~`、「CI 只在 Git Bash 上跑」）未变，「只支持 Windows」仍在。

## 改进建议
1. docs/architecture/modules/guidance.md:12 的「6 条 / 2 条」是一次性个人环境计数，建议删计数、保留原因句（tasks.md 已记入「发现但不碰」，待维护者确认）。
2. template/AGENTS.md:7 小改动出口没说直接提交前要不要跑自检；`docs/` 含活文档，「不改变意思」靠 AI 自判（有「没有活跃 Spec」「拿不准就收录」兜底，不阻塞；同上已记录）。

## 证据
- 验证：verification.md 的 result PASS；`- state:` 为 ac757ef0…，我在 Git Bash 下 `bash scripts/ai-state-id.sh template/AGENTS.md` 算得同一值；`bash scripts/ai-gate.sh check feat-t-000047 g2` 通过。
- AC-05：`grep -c '状态指纹'` 两个 `.gitattributes` 各 1；`git diff f397834 -U0 … | grep -vc '^[-+]#'` 输出 0。
- AC-06：`全局忽略` 1、`结果一致` 0、`CUSTOM_CHECK.*调用它的那个环境` 1、`USERPROFILE` 1、README.en.md 的 `WSL` 1、`只支持 Windows` README.md 与 AGENTS.md 各 1。
- 本轮只用只读命令（grep、git diff/log/status、ai-state-id.sh、ai-gate.sh check）；换行实验在系统临时目录进行，未运行 ai-verify.sh；复审前后 `git status` 无仓库文件被改（除本文件）。
- 未能核对：「CI 只在 Git Bash 上跑」只看了 workflow 文件，没看运行记录；「已知两个原因」不排除还有别的原因，README 用「已知」限定，措辞没有过头。
