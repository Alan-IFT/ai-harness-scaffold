# 需求：feat-t-000050

- 创建时间：2026-11-10
- **需求来源**: `process/task-pool/T-000050.md`（原始需求与更新）
- 原始问题 / 原话：那就你做好完全规划，然后拆分为多个spec（维护者 2026-11-10 对「验证机制怎么精简、什么时候做」的答复。规划拆成三个 Spec，按顺序做：本条是第二个，正式验证去掉 `<file>` 参数与 `$TARGET_FILE`；第一个 `feat-t-000049` 已归档；第三个 `T-000051` 是暂缓状态。维护者同日说「逐个领取spec并完成」，本条据此开工）
- 需人决定：是。改的是命令用法和配置约定：`ai-verify.sh` 少一个参数，检查命令里不再有 `$TARGET_FILE`，接入项目的 `harness/verify.conf` 可能要跟着改。

## 1. 要做什么
- 做什么：正式验证的命令从 `bash scripts/ai-verify.sh --spec <feat> <file>` 改成 `bash scripts/ai-verify.sh --spec <feat>`；检查命令里不再提供 `$TARGET_FILE`；g2 不再检查「验证目标在涉及文件里」；`verification.md` 不再记目标；规则、指南、README 和活文档跟着改。
- 为谁做：照规则干活的 AI 工具和维护者。现在每个 Spec 都要挑一个「归档后不变的项目文件」当目标，可它不影响查什么。
- 不做：
  - 不改指纹算法（`T-000051`，暂缓）。
  - 不删 `ai-verify.sh` 的 `redact()`。
  - 不写兼容旧用法的代码：旧用法（多带一个文件参数）直接报用法提示。
  - 不改 `skill/SKILL.md`、`README.en.md` 和 ADR：它们没提目标文件。
  - 不动 tasks.md 模板里的「涉及文件」字段：它还供审查者对照方案。
  - 不改 `template/harness/redlines.conf`（只允许人改）。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `bash scripts/ai-verify.sh --spec <feat>` 两个参数就能完成正式验证；多带参数（旧用法带文件）时打印用法并以非 0 退出，不静默忽略 | 自检断言「正式验证生成摘要」（命令不带文件）与新断言「拒绝旧用法多带的参数」通过 |
| AC-02 | 四个脚本里不再有目标文件的逻辑，检查命令的环境里不再有 `TARGET_FILE`；`verification.md` 不再写 `- target:` 行，`- command:` 行是新用法 | `grep -ci 'target' template/scripts/ai-verify.sh template/scripts/ai-state-id.sh template/scripts/ai-gate.sh template/scripts/ai-resume.sh` 四个都输出 0；在本 Spec 自己的 `verification.md` 上 `grep -c '^- target:'` 输出 0，`grep -c '^- command: bash scripts/ai-verify.sh --spec feat-t-000050$'` 输出 1 |
| AC-03 | g2 不再检查验证目标，其余条件不变：任务全勾、结果 PASS、指纹与当前代码一致 | 自检第 3 节删掉「拒绝验证目标不在涉及文件里」「验证目标只在 WIP 区出现时拒绝」两条，剩下三条（未完成任务、失败摘要、过期摘要）通过 |
| AC-04 | 规则、指南、配置样例、README 不再要求选目标，除升级说明和活文档外不再出现 `TARGET_FILE` | `grep -rl 'TARGET_FILE' template skill README.md README.en.md AGENTS.md docs/architecture` 只输出 `template/.agents/skills/upgrade.md` 与 `docs/architecture/modules/template-mechanism.md`；`grep -c '<file>' README.md template/AGENTS.md template/.agents/skills/code-review.md AGENTS.md` 四个都输出 0；`grep -c '验证目标' README.md` 输出 0 |
| AC-05 | `template/AGENTS.md` 行数不增加 | `wc -l < template/AGENTS.md` 输出 39 |
| AC-06 | 活文档删去「为什么 g2 要求验证目标在「涉及文件」里」，新增「为什么正式验证不带目标文件」 | `grep -c '为什么 g2 要求验证目标' docs/architecture/modules/template-mechanism.md` 输出 0；`grep -c '为什么正式验证不带目标文件' docs/architecture/modules/template-mechanism.md` 输出 1 |
| AC-07 | 升级说明第 6 步写明：`CUSTOM_CHECK` 或文件注释里还有 `$TARGET_FILE` 的，连同建议的整项目命令交人决定 | `grep -c 'TARGET_FILE' template/.agents/skills/upgrade.md` 输出 1 |
| AC-08 | 升级演练走得通：在系统临时目录里按 v2.1.4 装一个项目，把它的 `CUSTOM_CHECK` 写成用 `$TARGET_FILE` 的命令，再按新版升级说明升到本 Spec 的提交；第 6 步能找出这一行，换成整项目命令后新用法的正式验证通过 | 演练的命令和输出摘要记进 tasks.md 的 WIP 区 |
| AC-09 | 自检 75 项断言、失败 0 项（前一个 Spec 之后是 77 项；本条第 3 节删 2 条，第 7 节有 1 条原地换成新断言）；推送后 CI 两个任务成功；体积检查通过；正式验证用新用法为 PASS | `bash scripts/harness-selftest.sh` 末尾输出「75 项断言，失败 0 项」；`gh run view <run-id> --json jobs --jq '.jobs[].name, .jobs[].conclusion'` 输出两个任务名和两个 `success`，`--log` 里两处「75 项断言，失败 0 项」；`bash scripts/ai-check-bloat.sh` 通过；`bash scripts/ai-verify.sh --spec feat-t-000050` 为 PASS |
