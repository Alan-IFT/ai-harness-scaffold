# 审查：feat-t-000057

- 审查者：独立 subagent 上下文 / Sonnet 5.5 / 第 2 轮由同一个审查 subagent 接着做，带着第 1 轮的上下文
- 未参与实现：是
- CR 轮次：2 / 4
- 审查状态：6934e08374584d4c9c63765fcc0c33ae40dfc78e7fbe92578f65bf47faffe626
- 审查范围：839cd1c...HEAD（6a0c96f）+ 工作区；本轮复审重点是 106d608..6a0c96f

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不适用（复核「需人决定：否」仍成立：本轮新增的只是活文档一句改写和 `MEMORY.md` 一条教训，仍不涉及数据、权限、发布、架构取舍或不可逆操作；事故没有造成不可逆后果，见下）
- 决策来源：`template/.agents/skills/new-spec.md:12` 的判据；维护者 2026-11-21「都按推荐」（`process/task-pool/T-000057.md`）

## 关键问题
无。第 1 轮的关键问题已解决：`docs/architecture/modules/guidance.md` 现写「feat-t-000056 数验证过期的提示，两边都是 0；feat-t-000057 改看第一次正式验证前提交没有，旧 3 次里 1 次、新 3 次里 2 次，旧文字有 1 次流程验证过期后重跑，新文字没有」，与我第 1 轮复算的表格一致（旧 1：验证通过 2 次、2 处过期提示；其余为 0）。修复只改这一句，没有引入新问题。

## 改进建议
1. `MEMORY.md` 新条里「5 个空文件」「只删了这 100 个文件」我现在核对不了（文件已删，没有清单留存），只能核到：输出里「找不到活跃 Spec」的用法提示出现 95 次，与 95 个任务文件对得上；写成「按当时的清单」更稳妥。
2. 同条写「连带执行了规则入口等 4 个文件」，输出里实际被当成脚本的有 5 个（`template/AGENTS.md`、`00-INDEX.md`、`guidance.md` 本身、归档的 feat-t-000055 tasks.md、用户目录的偏好文件），tasks.md 的事故段是「活文档 + 另外 4 个」，两处口径不一，统一一下即可。

## 证据
- 验证：verification.md 的 result PASS / state 6934e083…（与上面一致）；`template/`、脚本、harness 自 106d608 起无改动（`git diff 106d608..HEAD --stat` 只有 MEMORY.md、guidance.md 和 process/）。
- 事故记录核对（我自己统计命令的落盘输出，约 6100 行）：
  - 被当成脚本逐行执行的文件按行首统计：用户目录偏好文件、`template/AGENTS.md`、`guidance.md`、归档的 feat-t-000055 tasks.md、`00-INDEX.md`；滤掉 command not found 和 syntax error 后只剩：95 次接手脚本的用法提示（`ai-resume.sh` 找不到活跃 Spec）、95 次 `reset` 终端报错、几十次「Is a directory」或「No such file」，以及末尾 1 次 fork 资源不足。没有出现提交、推送、打 tag、删除类命令的输出。95 次与 tasks.md 说的 95 次收录/快照一致。
  - 仓库现状：`git status --short` 为空；`git reflog` 只有 feat-t-000057 的提交，没有 reset、checkout、push 记录；`git tag` 最新仍是 v2.2.0，没有新 tag；`git status -sb` 为领先远端 11 个提交，与 c07e1f6 到 6a0c96f 的 11 个提交对得上，远端仍在 839cd1c；`process/task-pool` 只有 2 个文件，`process/specs/active` 只有本 Spec；仓库根没有多余文件；`template/process/specs/` 下 `_templates`、`active`、`archive` 三个目录都在，日期是事故前的（`active`、`archive` 是原有的两个空目录）。
  - 仓库外：用户目录偏好文件的修改时间仍是 2026-11-05，没变；家目录里除宿主自己的文件外没有新的偏好类改动。这只能证明偏好文件没被改写，不能证明所有仓库外位置都没动，「仓库外没有改动」我只核到这一层。
  - 因此「清理后与事故前一致」：可核对的部分（跟踪文件、提交历史、tag、任务池、根目录、空目录）都成立；被删的 100 个文件的内容和 5 个根目录空文件的存在，核对不了。
- 其余结论沿用第 1 轮：AC-01 到 AC-04 的命令输出、AC-02 的规则先于对照、判定与表格一致、「13 次里 5 次」「8 次里 2 次」的来源、AC-03 改数如实且未超范围，本轮这部分没有改动。
