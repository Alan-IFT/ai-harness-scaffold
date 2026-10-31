# 任务与接力：feat-t-000038

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000038` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：只改措辞，不动门禁脚本逻辑；同一文件的改动一次编辑完。审查规则的 3 条新增（复核「需人决定」、对照记忆与模块活文档、只拦本次引入或加重的问题）和 2 条删减（开场声明、与脚本输出重复的必读清单）集中在 `code-review.md` 第 2 步；`AGENTS.md` 删 1 行、改 1 处括号；接入指南把验证命令从「能对单个文件跑的检查」改成「能证明行为的检查」，示例同步换成跑测试的；模块活文档模板只写「为什么」。复核「需人决定」只引用 `new-spec.md` 的判据（同一说法只留一处），不加例外。措辞以分析阶段三个独立核查者多数通过的版本为准。第 3 问推荐现在一起做：`SKILL.md` 改成「有测试就跑测试」后，示例若仍全是 lint 会与它矛盾，接入的 AI 常照抄示例；`npm test`（无测试或未配脚本时非零退出）与 `pytest`（零用例退出码 5）零用例都会失败；不用 `jest --findRelatedTests "$TARGET_FILE"`（目标没有关联测试就失败，改文档的需求过不了 g2）和 `vitest related`（找不到测试时退出 0，空跑也算过）；`go vet ./...` 保留（`go test ./...` 零用例退出 0）。
- 改动文件：`template/.agents/skills/code-review.md`、`template/AGENTS.md`、`template/process/specs/_templates/tasks.md`、`template/docs/architecture/00-INDEX.md`、`template/scripts/harness-selftest.sh`（只改夹具里借用的字段名）、`skill/SKILL.md`、`template/harness/verify.conf`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/install-skill.md`
- 影响与风险：
  - 脚本：`ai-gate.sh` 只机械读 `review.md` 字段与 `requirements.md` 的「需人决定」，措辞变化不影响；`ai-resume.sh` 打印的「正在编辑的文件」来自 git，保留；自检只有 t-wiponly 夹具借用了被删字段名，改成「下一步」后断言含义不变。
  - 行为：改门禁、改流程这类需求以后更常要维护者在 g3 回一句「通过」（维护者已接受）；关键问题收窄到本次引入或加重的，老问题进「发现但不碰」；审查者每轮多读 `MEMORY.md`（≤ `MEMORY_MAX_LINES`）与相关模块活文档；新接入项目的 g2 改跑测试，可能变慢。
  - 兼容：已接入项目的 `verify.conf`、`docs/architecture/` 属项目状态，升级不覆盖（`upgrade.md`）；没有存量用户（T-000034）。
  - 同步面：README、`skill/SKILL.md` 其余部分、`upgrade.md` 不含被改措辞（已 grep）；根目录 `AGENTS.md` 要求改 `SKILL.md` 后在临时目录实际接入一次，放在 Task 4。
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。
- 方案审查（独立 subagent，未写方案，2026-10-30）：需先改 1 处，AC-06 没覆盖 `AGENTS.md` 括号的改动、把「第 2 步第 1 条」写成了「第 1 步」，已改。采纳的建议：`code-review.md` 规则与文档条补「（按 `docs/architecture/00-INDEX.md` 找）」；guidance 新增行写「g3 要人当次决定的唯一开关」（不可逆操作另有人同意的规定）；install-skill 新增行写明关联测试探测由 fee16ca 删除、单文件措辞来自 1e6697b；「做什么」补 `knowledge_feedback`；AC-01 加全文无「除外」「例外」。审查者在临时副本上逐条应用改动：14 处原文都唯一命中，AC 全部可过，自检 72 项 0 失败，t-wiponly 仍按原意拒绝。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：审查指南一次改完（复核需人决定、对照记忆与活文档、只拦本次引入或加重的、删开场声明与重复清单、删 knowledge_feedback）
  - 对应验收：AC-01、AC-02、AC-03、AC-06
  - 涉及文件：`template/.agents/skills/code-review.md`
  - 验证：AC-01~03 与 AC-06 中 code-review.md 部分的 grep；`bash scripts/harness-selftest.sh`
- [ ] Task 2：规则入口与模板删减（上下文上限提醒、「正在编辑的文件」、00-INDEX 只写为什么、自检夹具）
  - 对应验收：AC-05、AC-06
  - 涉及文件：`template/AGENTS.md`、`template/process/specs/_templates/tasks.md`、`template/docs/architecture/00-INDEX.md`、`template/scripts/harness-selftest.sh`
  - 验证：AC-05、AC-06 的 grep；`wc -l template/AGENTS.md` 为 39；`bash scripts/harness-selftest.sh`
- [ ] Task 3：接入指南的验证命令与示例
  - 对应验收：AC-04
  - 涉及文件：`skill/SKILL.md`、`template/harness/verify.conf`
  - 验证：AC-04 的 grep
- [ ] Task 4：模块活文档补「为什么」，整体验收与临时目录接入
  - 对应验收：AC-07、AC-08
  - 涉及文件：`docs/architecture/modules/guidance.md`、`docs/architecture/modules/install-skill.md`
  - 验证：AC-07 的 grep；提交后按 `skill/SKILL.md` 在临时目录接入一次新项目并跑自检、体积检查与门禁状态；`bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`；正式验证 `bash scripts/ai-verify.sh --spec feat-t-000038 template/.agents/skills/code-review.md`

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/AGENTS.md:7` 与根目录 `AGENTS.md:10` 不一致：根目录写「非平凡变更走三道门」，模板没有这个限定；分析阶段三个核查者都反对给模板加快速通道（ADR-0003 删过分档与 `--quick`，feat-t-000031 排除过快速通道），留给维护者决定。
- 根目录 `docs/architecture/00-INDEX.md` 的模块表没有登记 `template/docs/**`、`template/MEMORY.md`、`template/PREFERENCES.md`、`template/CLAUDE.md`；建议并入「项目指南」一行。
- `template/.agents/skills/code-review.md:8`（Step 1 第 2 条）复述了 `ai-verify.sh` 已做的事，`template/PREFERENCES.md` 表头与 `AGENTS.md:6` 重复；分析阶段只有查漏者提出，未经三方核查，暂不动。
- 改动检查本身（弱化 `verify.conf`、删减测试、改门禁脚本）目前靠「每一行改动对应需求」间接拦；分析阶段三方多数认为无需单列，若日后出现再在 `code-review.md` 测试条目补一句。
- `template/.agents/skills/archive-spec.md:6`「公共契约…写进 `docs/architecture/`」与模板 00-INDEX 改后的「只写「为什么」与已知坑」略有张力，可读作路由表的「公共契约入口」列；方案审查建议只记录不动。
- `template/harness/verify.conf` 的 Go 示例仍是静态检查 `go vet ./...`：`go test ./...` 零用例退出 0，不满足同文件「零用例时必须失败」，Go 项目接入时要自己加零用例保护。

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 2
- 已完成：需求与方案；独立方案审查（结论已写回方案）；Task 1（grep 全中，自检 72 项 0 失败）
- 已排除的方案：多代理找 bug 加投票、风险三档与分类器、单独安全审查、事故评测集与度量、REVIEW.md 与 PR 模板文件、按类报告、误报申诉、审查者重跑验收命令、「怎么撤销」字段、漏网缺陷复盘、叫停流程、修根因、删 `template/CLAUDE.md`、放宽复述确认、去掉任务数上限、删 Karpathy 收尾句、写明「人工批准只是约定」、「非平凡变更」快速通道（理由见分析：宿主绑定、无实际问题、与维护者既有决定冲突，或会架空复核）
- 下一步：过 g1，按 Task 1~4 顺序改
