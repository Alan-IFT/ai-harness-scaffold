# 审查：feat-t-000050

- 审查者：独立审查上下文（subagent，未参与实现），模型 Sonnet 5.5
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：53ef912bd5866699cedf4466fc2ffbdeaee8db3a74438a6e4c711b0308e29416
- 审查范围：416657b...HEAD + 工作区（工作区干净）

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：通过
- 决策来源：对话（2026-11-10）。实现者把结果（自检 75 项、CI 两个任务成功、正式验证 PASS、独立审查关键问题 0）和风险（接入项目的 `CUSTOM_CHECK` 若用了 `$TARGET_FILE`，升级后变量为空，可能失败也可能悄悄变义；不带兼容代码，靠升级说明第 6 步找出来交人决定；在途验证升级后要重跑）讲给维护者，问「通过还是不通过」，维护者答「通过」。这两行由实现者按维护者的原话填写，其余内容是审查者写的。

## 关键问题
无。

## 改进建议
1. 升级说明第 6 步（`template/.agents/skills/upgrade.md:14`）只让 AI「找出并交人决定」，但旧版 `$TARGET_FILE` 为空时多数命令会直接失败、少数会悄悄变义（未加引号的 `pytest $TARGET_FILE` 变成跑全量）。建议在同一句里点名「`CUSTOM_CHECK` 里引用 `$TARGET_FILE` 的」，「文件注释」改为「`verify.conf` 的注释」（tasks.md 已记为发现但不碰，我同意这是措辞问题，不阻塞）。
2. 红线样例第 8 行与 `template/AGENTS.md:33`「同一目标连续验证失败」的「目标」今后可能被读成文件；红线只允许人改，由维护者定。
3. 升级说明没有提醒：新版指纹算法去掉了目标哈希，升级前已验证通过、尚未归档的 Spec 在升级后一定过期，需重跑 `ai-verify.sh`（`ai-resume.sh` 会显示「已过期」，不致悄悄放行，属体验问题）。

## 证据
- 验证：verification.md 的 result 为 PASS，state 与当前工作区一致（`ai-resume.sh review` 的指纹核对通过）。
- AC-01：`template/scripts/ai-verify.sh:11` 为 `[ "${1:-}" = "--spec" ] && [ "$#" -eq 2 ] || 用法`；空 Spec 名由第 13 行 case 拦住；`bash scripts/harness-selftest.sh` 实跑末尾「75 项断言，失败 0 项」，含「拒绝旧用法多带的参数」。
- AC-02：四脚本 `grep -ci target` 均为 0；`verification.md` 中 `^- target:` 为 0，`- command: ...--spec feat-t-000050$` 为 1。`ai-verify.sh` 里 `export TARGET_FILE` 已删，检查命令环境不再有该变量。
- AC-03：ck_g2（`template/scripts/ai-gate.sh:79-91`）只剩任务全勾、PASS、指纹一致；自检第 3 节剩三条。
- AC-04：`grep -rl TARGET_FILE ...` 只输出 `upgrade.md` 与 `template-mechanism.md`；`<file>` 四文件均 0；`验证目标` 在 README 为 0。AC-05：`wc -l` 为 39。AC-06：0 与 1。AC-07：1。
- AC-09：`gh run view 42827693413` 对应提交 4da97f8（即 origin/main 当前头），两个任务均 success；4da97f8 之后提交只动 `process/`，不影响指纹。`ai-check-bloat.sh` 通过。
- 调用方一致性：`ai-state-id.sh` 的三处调用（ai-verify.sh:55、ai-gate.sh:88、ai-resume.sh:42/84）都已无参；ai-resume owner 分支条件改为只看 `saved` 非空，旧摘要里残留的 `- target:` 行不会被读，行为正常。`ai-state-id.sh` 现在无视多余参数，但自检第 9 节与 README 均写无参数，不构成问题。
- 遗留扫描：在 template、skill、README、README.en、docs 中搜 `验证目标|目标文件|归档后不变|target:`，仅剩活文档新增条目与旧指纹条目里对历史行为的描述（准确）。tasks 模板与 new-spec.md 里的「涉及文件」保留，与需求「不动」一致。`skill/SKILL.md`、README.en.md 无对应旧句。
- 「需人决定：是」判定：我认为对。判据是「架构取舍或不可逆操作」：这是命令接口与配置约定的破坏性变更（旧用法直接报错），并影响已接入项目的 `verify.conf`，维护者应知情。
- 给维护者的最大风险：已接入项目升级时，若 `CUSTOM_CHECK` 用了 `$TARGET_FILE`，变量变空，可能直接失败，也可能悄悄变成别的意思（跑全量或等标准输入）；本改动不带兼容代码，完全靠升级说明第 6 步被 AI 执行并交人决定。其次，指纹算法变了，所有在途 Spec 升级后都要重验。接入项目要跳过 v2.1.4 直接升到下一版，这一点需要在发版说明里写明。
- 未能核实：AC-08 升级演练（已完成的临时目录演练）我没有重放，只核对了 tasks.md 记录与升级说明文字本身，说明文字本身通顺、可执行；某接入项目的 `verify.conf` 是否用了 `$TARGET_FILE` 也无从得知。
