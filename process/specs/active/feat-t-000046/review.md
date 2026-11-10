# 审查：feat-t-000046

- 审查者：独立审查上下文（subagent，未见实现过程）/ Sonnet 5.5 / 本次会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：bc367682ef14edd3408cad27bf98a193caa761976319df2b746a8c75f2583ea8
- 审查范围：960747b...HEAD + 工作区

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不适用（requirements.md「需人决定：否」；改动只移动任务文件，不改门禁标准、不涉权限与发布，判据成立）
- 决策来源：requirements.md 第 5 行；不需要人的当次决定

## 关键问题
无

## 改进建议
1. `template/scripts/ai-task-pool.sh:149-152` 的移动循环只在 `archive` 成功路径上处理「关联 Spec 等于 feat」的任务文件；若有人把任务文件手工关联到已归档 Spec 又留在池里，只会显示「关联异常」，由 upgrade.md 第 5 条处理，这已被文档覆盖，仅提示：该循环对 `取消`/`暂缓` 状态的任务也会带走，行为合理但 requirements.md 未明说。
2. `template/scripts/ai-task-pool.sh:105-109` 的 `list` 对「关联 Spec 已在 archive」的遗留文件与「真的指错 Spec」的文件都显示「关联异常」，无法区分；这是需求明确接受的取舍（AC-03），不阻塞。

## 证据
- 验证：verification.md result: PASS，state 与 review.md「审查状态」一致；`ai-gate.sh status` 显示 g1、g2 已过，g3 待本报告。
- AC-01：`archive` 先 `mv` 任务文件进 `$source_dir`，再整体移走（脚本 149-153 行）；自检断言「任务文件随 Spec 归档」通过（`bash scripts/harness-selftest.sh` 输出「76 项断言，失败 0 项」）。
- AC-02：脚本编号扫描新增 `process/specs/archive/*/*/T-*.md`（约 84 行）；自检断言「归档带走的任务编号不重用」通过，用的是名为 `t-arch` 的 Spec。
- AC-03：`status_for` 只判 active，否则「关联异常」；`grep -c '已归档' template/scripts/ai-task-pool.sh` 输出 1（只剩 archive 成功提示）；自检「Spec 不在 active 的任务标为关联异常」通过。
- AC-04：`grep -cE 'basename|find ' template/scripts/ai-task-pool.sh` 输出 0。
- AC-05：自行复测（临时目录，复制 template/scripts，300 个已归档 Spec 目录各带一个关联任务文件，再 add 4 个待办）：add 4 次编号为 T-000301 至 T-000304，接在 300 之后；`time` 测得 next 0.80 秒、list 0.75 秒、add 0.22 秒（add 时池里已有 4 个待办，新编号 T-000305），均不超过 2 秒，与 tasks.md 的实测一致。
- AC-06：三处 grep「随 Spec」分别命中 archive-spec.md:13、template-mechanism.md:10、README.md:185；upgrade.md:13 命中「关联异常」。
- AC-07：`ls process/specs/archive/*/*/T-*.md | wc -l` 输出 16；`bash scripts/ai-task-pool.sh list` 只有 T-000046（进行中）、T-000047（待办），无「关联异常」；`process/task-pool/` 只剩这两个文件。
- AC-08：自检失败 0 项；ai-verify 的 PASS 记录在 verification.md。
- 其他：`ai-gate.sh`、`ai-resume.sh`、`ai-new-spec.sh` 不读 `task-pool` 路径下的归档任务（grep 仅 ai-resume.sh:98 调 `next`）；`git status --short` 为空，工作区干净；改动中无非公开项目名与本机路径；根目录 scripts/ 仍只转发；每行改动都对应需求。
- 中途失败：任务文件移动失败时 `die` 在 `mv` 目录之前，Spec 仍在 active，可重跑；目录移动失败时任务文件已在 Spec 内，重跑一并带走，与 tasks.md 描述一致。
