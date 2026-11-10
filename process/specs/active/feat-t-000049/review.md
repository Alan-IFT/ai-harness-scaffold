# 审查：feat-t-000049

- 审查者：独立审查上下文（subagent，未参与实现），模型 Sonnet 5.5
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：7aded11b7976775dc53e8e9bf1ee4b5d8a68f3689f96e6f9f81a997a706b560e
- 审查范围：2407de2...HEAD + 工作区

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：无需人工决定。独立判断「需人决定：否」成立：改动不涉及数据、权限、发布、架构取舍或不可逆操作（new-spec.md Step 1 第 3 点）；只把没有 Git 的目录里「悄悄给出只覆盖单文件的指纹」改成报错，Git 仓库里的指纹值不变，接入说明（skill/SKILL.md:18）本来就要求先 git init。
- 决策来源：不适用（无需人工决定）

## 关键问题
无

## 改进建议
1. template/scripts/ai-state-id.sh:6 守卫用 `git rev-parse --is-inside-work-tree` 的退出码判断；在 `.git` 目录内部或裸仓库里该命令输出 false 但退出 0，守卫放行，之后 `git ls-files` 才失败。属极少见边界，不阻塞；要堵可改为比较输出是否为 true。
2. harness-selftest.sh:287 的「非 Git 目录拒绝计算指纹」在 `$TMP`（系统临时目录）里跑，若某环境的临时目录恰在某个 Git 工作区内会误失败。当前 CI 两个平台都通过，不阻塞。

## 证据
- 验证：verification.md result PASS，state 7aded11b…560e，与本审查一致。
- 需求 AC-01：ai-state-id.sh:6 守卫在取目标参数之前，Git 报错不吞（未重定向 stderr）、说明写明两种可能；自检断言 harness-selftest.sh:287 在 CI 日志里通过。
- AC-02：diff 对 Git 分支只做去缩进、删 else，hash 输入序列逐字节相同（`global`、ls-files、diff、untracked、target 顺序未变），指纹值不变；tasks.md 的新旧脚本对比记录与此一致。
- AC-03：自己重跑 `bash scripts/harness-selftest.sh`，输出「77 项断言，失败 0 项」，约 60 秒；沙箱 `git init` 在 harness-selftest.sh:126，位于第 1 节之前，git_q 已定义。反向检查未重跑，依赖实现者记录（17 项失败）。
- AC-04：template-mechanism.md:6 有该条目，措辞与代码一致。
- AC-05：`gh run view 42825259969` 两个任务名 selftest (ubuntu-latest)、selftest (windows-latest)，结论均 success；日志里「77 项断言，失败 0 项」出现 2 次。
- AC-06：未重跑 ai-verify / ai-check-bloat（只读约束，不得运行 ai-verify）；verification.md 有 PASS 记录。
- 文档核对：README、skill/SKILL.md 中没有被本次改动弄成不成立的句子（grep「no-git」「非 Git」无残留）；ai-resume.sh:110 的 git init 提示按需求「不做」保持不变，与新行为不矛盾。
- 范围：改动文件仅 ai-state-id.sh、harness-selftest.sh、template-mechanism.md 及流程记录，每行都对应需求，无额外行为。
- 工作区：审查前后 `git status --short` 仅多出 review.md。
