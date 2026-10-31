# 任务与接力：feat-t-000039

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000039` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：只改措辞，不动脚本。拟定文字：
  - ① `skill/SKILL.md:24` 句末补「现有测试已经失败或不稳定（时而通过时而失败）的，停下问人。」不写怎么处理（修测试、隔离、换命令都是人的取舍），也不允许退回只跑 lint。
  - ② `code-review.md:19` 在分号处拆开：「规则与文档」只留对照 `MEMORY.md` 与活文档、按关键问题处理那句；后半句另起一条「**指南与记忆**：改了 `AGENTS.md`、指南、模板或 `MEMORY.md` 时，检查有无矛盾和过时内容，有无把一次性经验写成通用结论、混入个人调试信息。」不写档位，由第 4 条的两档定义归类（这些都不属关键问题定义，自然进改进建议）。
  - ③ `code-review.md:21` 改为「本次改动引入或加重（新增调用点、扩大影响面也算）的 bug、…」。
  - ④ `code-review.md:15` 句末补「实现者改为「是」后不补审方案，由 g3 的人工决定兜底。」（写明实现者，审查者只读）依据：`ai-gate.sh` 在 g3 现读 `requirements.md` 的「需人决定」，改了就会要求人的「人工决定：通过」；编码已完成，补审方案只是事后走形式。
  - `docs/architecture/modules/guidance.md:8` 末尾补原因：「需人决定」改为「是」后不补审方案，因为 g3 现读该字段、要人当次决定，代码已写完再审方案只是走形式。
- 改动文件：`skill/SKILL.md`、`template/.agents/skills/code-review.md`、`docs/architecture/modules/guidance.md`
- 影响与风险：
  - 脚本：自检与门禁脚本都不读这几句（已 grep `规则与文档`、`引入或加重`、`判据见`、`零用例时失败`，只在这两个文件与 `guidance.md:8` 出现）；`guidance.md:8` 的「为什么」仍成立，只补④的原因。
  - 行为：①让接入在测试本身坏掉时多问一次人；③让审查对「把老 bug 扩散到新调用点」也拦，修复限于新调用点本身（不调用、加保护），要改老函数才能修的停下问人，避免违背「精准改动」；④明确不补审方案；②不改拦截标准，只消除歧义。
  - 兼容：已接入项目升级时按 `upgrade.md` 合并指南，无存量用户（T-000034）。
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。
- 方案审查（独立 subagent，未写方案，2026-10-31）：无必须先改项；在仓库外临时副本套用四处措辞，AC-01~04 grep 全中，自检 72 项 0 失败；核实 `ai-gate.sh` 只在 g3 现读「需人决定」、g1 不查方案审查，④与门禁一致。采纳的建议：「时过时不过」改为「不稳定（时而通过时而失败）」；④写明主语「实现者」；`guidance.md` 补「不补审方案」的原因；③在影响与风险写明修复限于新调用点；AC-05 加 `git status --porcelain`。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：审查指南三处措辞（②③④）
  - 对应验收：AC-02、AC-03、AC-04
  - 涉及文件：`template/.agents/skills/code-review.md`
  - 验证：AC-02~04 的 grep；`bash scripts/harness-selftest.sh`
- [ ] Task 2：接入指南补「先问人」，整体验收与临时目录接入
  - 对应验收：AC-01、AC-05
  - 涉及文件：`skill/SKILL.md`、`docs/architecture/modules/guidance.md`
  - 验证：AC-01 的 grep；`bash scripts/harness-selftest.sh`、`bash scripts/ai-check-bloat.sh`；提交后按 `skill/SKILL.md` 在临时目录接入一次新项目；正式验证 `bash scripts/ai-verify.sh --spec feat-t-000039 template/.agents/skills/code-review.md`

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- feat-t-000038 审查建议中维护者未选的 3 条：`template/harness/verify.conf:6` 的 `go vet` 示例；`skill/SKILL.md:18` 新项目可补「选法同第 2 节第 4 条」、`:25` 可补「写不出原因就留空」；`docs/architecture/modules/install-skill.md:7` 两个提交号的叙述顺序。

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 2
- 已完成：需求与方案；独立方案审查；Task 1（AC-02~04 grep 全中，自检 72 项 0 失败）
- 已排除的方案：②给第二条写明「记改进建议」（会把有害的规则矛盾也降级，交给两档定义归类即可，有意不写档位）；④单独起子项（句末补半句即可）
- 下一步：Task 2
