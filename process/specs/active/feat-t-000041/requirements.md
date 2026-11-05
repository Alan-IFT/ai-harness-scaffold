# 需求：feat-t-000041

- 创建时间：2026-11-05
- **需求来源**: `process/task-pool/T-000041.md`（原始需求与更新）
- 原始问题 / 原话：那就都按推荐来做（维护者 2026-11-05 对公开化改造清单的答复，隐私部分已脱敏；全文见任务文件）。
- 需人决定：是。选定开源许可证并对外发布，属于发布决定；首个公开 tag 也在本需求收尾时打。

## 1. 要做什么
- 做什么：补齐公开项目必需的内容：许可证、外部用户能照做的 README、版本选择规则、自检 CI，并把隐私约束写进仓库规则。
- 为谁做：第一次在 GitHub 上看到本仓库、想把脚手架接入自己项目的人，以及之后接手本仓库的 AI 工具。
- 不做：行为准则、Issue / PR 模板、CHANGELOG、Dependabot、文档站、徽章、全面国际化、Linux 或 macOS 支持、CLI 或安装包；不接受 PR 的流程设计；不改 `process/` 归档里的旧记录。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 根目录 `LICENSE` 是标准 MIT 全文，GitHub 识别为 MIT | 推送后 `gh repo view --json licenseInfo` 返回 `mit` |
| AC-02 | 模板随接入项目分发一份声明，含本脚手架 MIT 全文和 Karpathy 准则的来源与许可；不在接入项目根目录放 `LICENSE`；升级说明把它列为机制文件 | `git ls-files template` 含 `template/.ai-harness/LICENSE.md`，不含 `template/LICENSE`；该文件含 `forrestchang`、`MIT`，并写明上游没有 LICENSE 文件、依其 README 与 plugin.json 的声明，不写上游版权行；`grep -n 'ai-harness/LICENSE' template/.agents/skills/upgrade.md` 命中 |
| AC-03 | `README.md` 写明克隆地址、前置条件、ZIP 不可用、实测工具（Claude Code、Codex）与理论兼容工具、只支持 Windows、门禁不是安全边界、`CUSTOM_CHECK` 会被执行、安全问题报告入口、只收 Issue、`process/` 是自用记录，并链接英文版 | 逐条 `grep` 命中 `README.md`：`github.com/Alan-IFT/ai-harness-scaffold.git`、`Git Bash`、`ZIP`、`Claude Code`、`Codex`、`理论兼容`、`只支持 Windows`、`安全边界`、`CUSTOM_CHECK`、`security/advisories/new`、`Issue`、`process/`、`README.en.md` |
| AC-04 | `README.en.md` 说明项目用途、产出是中文、只支持 Windows、如何开始，并与 `README.md` 互相链接 | `grep` 命中 `Chinese`、`Windows`、`git clone`、`README.md`；`README.md` 命中 `README.en.md` |
| AC-05 | 接入与升级先拉取 tag（失败就停下问人），默认取版本号排序最新的 tag，没有 tag 时取 HEAD；`.ai-harness/version` 记录解析到提交后的完整提交号；未点名版本且目标不比已装版本新时，升级停下问人 | 在临时克隆里打一个旧提交的 tag，按 `skill/SKILL.md` 接入新项目：`commit=` 等于该 tag 的提交，装入文件与该 tag 一致，自检通过；删除 tag 后再接入一次：`commit=` 等于 HEAD，自检通过；`grep -n 'is-ancestor' template/.agents/skills/upgrade.md` 命中（升级路径只改说明，不做实测） |
| AC-06 | 跟踪文件里没有非公开项目名和个人信息；根目录 `AGENTS.md` 写明公开仓库的隐私约束；`.gitignore` 不再含本机工具锁文件 | 隐私词表 `git grep` 无命中（词表含敏感内容不入库，由实现者在本机核对）；`grep -n '公开' AGENTS.md` 命中；`grep -c dsh .gitignore` 为 0 |
| AC-07 | 现行文档里没有因历史重写失效的提交号；活文档说明 `process/` 归档里的旧提交号已失效 | 用重写映射表核对非 `process/` 文件无命中（映射表不入库，由实现者在本机核对）；`grep -n '历史' docs/architecture/modules/self-hosting.md` 命中该说明 |
| AC-08 | CI 在 `windows-latest` 上运行自检：只读权限，第三方 action 固定到完整提交号，推送后实际运行成功 | `.github/workflows/selftest.yml` 含 `contents: read` 与 40 位 SHA；`gh run list` 显示该工作流 `success` |
| AC-09 | 模板自检全部通过 | `bash scripts/ai-verify.sh --spec feat-t-000041 README.md` 为 PASS |

## 3. 待确认问题
- [x] Q1：用哪种许可证、怎么分发？→ 维护者 2026-11-05 选推荐方案：全仓 MIT，模板带一份声明。
- [x] Q2：支持哪些工具算实测？→ 维护者 2026-11-05 答：Claude Code、Codex。
