# 需求：feat-t-000047

- 创建时间：2026-11-09
- **需求来源**: `process/task-pool/T-000047.md`（原始需求与更新）
- 原始问题 / 原话：做，先做第一、二批，不绑定宿主，bash更通用吧？（维护者 2026-11-09 对脚手架整体分析的答复；本条是第二批：规则与文档措辞，范围见任务文件）
- 需人决定：是。改的是规则入口：哪些改动可以不走三道门、记忆写在哪，属于架构取舍，g3 要维护者对最终措辞的当次决定。

## 1. 要做什么
- 做什么：补上分析里核实过的规则缺口和文档偏差：AI 工具自带的记忆不作来源；小改动有不走三道门的出口；任务暂缓、取消怎么记；README 说明同一台 Windows 上 `bash` 可能是 Git Bash 也可能是 WSL，以及这意味着什么；写明统一换行的另一个原因。
- 为谁做：在接入项目里换着用不同 AI 工具的维护者，和照这些规则干活的 AI 工具。
- 不做：
  - 平台范围不动：是否把「只支持 Windows」改成按 Bash 写、CI 加不加 `ubuntu-latest`、根 `AGENTS.md` 与 ADR-0003 的那一句改不改，原话「不绑定宿主，bash更通用吧？」有两种读法，另行问维护者，不在本需求里推断。
  - g1 对括号开头的原话的误报、缺配置时的报错文案：16 个归档 Spec 里没出现过，按「没出现过的问题默认不加」不做（任务文件里列了这两项，方案审查后砍掉）。
  - 「验证后提交会过期」（等第三批的决定）；不改 `skill/SKILL.md`；不删 AI 工具那边的记忆文件；不打 tag；不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `template/AGENTS.md` §4 写明 AI 工具自带的记忆不作来源，并写明不宜入库的项目事实放本项目的 `PREFERENCES.md`；`template/PREFERENCES.md` 的说明同步 | `grep -c '自带的记忆不作来源.*不宜入库' template/AGENTS.md` 输出 1；`grep -c '不宜入库' template/PREFERENCES.md` 输出 1 |
| AC-02 | `template/AGENTS.md` §1 写明只有源码注释和说明文档（README、`docs/`）里不改变意思的错别字与措辞可以直接改完提交、不进任务池，前提是没有活跃 Spec，拿不准就收录 | `grep -c '直接改完提交、不进任务池.*没有活跃 Spec.*拿不准就收录' template/AGENTS.md` 输出 1 |
| AC-03 | `template/AGENTS.md` §1 写明维护者说暂缓或不做时怎么改任务文件 | `grep -c '说暂缓或不做了.*队列状态.*暂缓.*取消' template/AGENTS.md` 输出 1 |
| AC-04 | `template/AGENTS.md` 的行数不增加 | `wc -l < template/AGENTS.md` 输出 39 |
| AC-05 | 模板与本仓库的 `.gitattributes` 注释写明统一换行也是为了 Git Bash 与 WSL 算出的状态指纹一致；规则行不变 | `grep -c '状态指纹' template/.gitattributes .gitattributes` 各输出 1；`git diff f397834 -U0 -- template/.gitattributes .gitattributes | grep -E '^[-+][^-+]' | grep -vc '^[-+]#'` 输出 0（增删的行都是注释） |
| AC-06 | README 说明同一台 Windows 上的 `bash` 可能是 Git Bash 也可能是 WSL：门禁与状态指纹两边一致，`CUSTOM_CHECK` 在调用它的环境里运行，WSL 里的 `~` 不是 Windows 用户目录；前置条件指向这条说明，英文版同步一句；「只支持 Windows」的说法不变 | `grep -c 'CUSTOM_CHECK.*调用它的那个环境' README.md` 输出 1；`grep -c 'USERPROFILE' README.md` 输出 1；`grep -c 'WSL' README.en.md` 输出 1；`grep -c '只支持 Windows' README.md AGENTS.md` 各输出 1 |
| AC-07 | 活文档 `guidance.md` 写明为什么 AI 工具自带的记忆不作来源、为什么小改动的出口只列注释和说明文档 | `grep -c '自带的记忆不作来源' docs/architecture/modules/guidance.md` 与 `grep -c '小改动的出口' docs/architecture/modules/guidance.md` 各输出 1 |
| AC-08 | 只存在于 AI 工具记忆里的两条已搬回项目：评估文章的做法进 `MEMORY.md`；含非公开信息的那条进本机不入库的 `PREFERENCES.md` | `grep -c '评估外部文章' MEMORY.md` 输出 1；`git check-ignore -q PREFERENCES.md` 退出码 0，`git status --short` 不含该文件，`test -s PREFERENCES.md` 退出码 0 |
| AC-09 | 自检与体积检查通过，正式验证通过 | `bash scripts/harness-selftest.sh` 失败 0 项；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000047 template/AGENTS.md` 为 PASS |
