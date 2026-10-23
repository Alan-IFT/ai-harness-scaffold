# 代码审查报告 (Code Review): feat-t-000006

- **审查者**：独立 subagent（Claude Code / Opus 5.5，G5 审查会话，只读）
- **未参与实现**：是
- **审查时间**：2026-10-22
- **审查范围**：`git diff f0ea114...HEAD`（第 2 轮 HEAD=bad5454，增量为 `git show bad5454`）（工作区与暂存区无改动）；design.md §4 文件清单：ai-gate.sh、ai-resume.sh、ai-state-id.sh、harness-selftest.sh、template-mechanism.md、K-0001、.knowledge/INDEX.md
- **CR 轮次**：2 / 4
- 审查状态：92cb6686c4620eb217c3e9be5d5f5bb9228548404a1aaa26f7ec6bdc8ae7b938

我没写过这段代码，只依据产物判断。

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：3（已记入 tasks.md §3）
- 判定：通过

### 第 2 轮结论（增量复审 bad5454）
- 上一轮关键问题 1：已修复。`ai-gate.sh:236` 的矩阵文本接 `sed 's/　/ /g'`，只改这一处，没有泛化。HEAD 副本里把矩阵单元格改成只有全角空格后，`LC_ALL=C`、`LC_ALL=C.UTF-8` 和无 locale 三种环境下 g3 都拒绝，提示「需求覆盖矩阵有空单元格或模板占位」，结论一致。
- 新增回归：`harness-selftest.sh:371-373`。HEAD 副本在无 locale 环境下自检 224 项、失败 0 项；只把 ai-gate.sh 换回 6a38f9b 版本后，自检失败 1 项，正是「LC_ALL=C：覆盖矩阵单元格只有全角空格被拒」，说明这条用例能防住回归。
- 改进建议 ③ 的扫描结论：复核成立。ai-gate.sh 其余直接读文件的位置有 :151、:373-374、:427（复选框）、:226、:266（追溯版本标记）、:231、:241（ID 列，trim 后要求完整匹配 `AC-[0-9]+`）、:268、:293-297（章节号、Task、编号）、:408（日期）。这些位置都不判断“冒号后是否有内容”；全角空格只会让编号无法识别，两种 locale 下都按拒绝或缺失处理，不会放行。
- 门状态：`.violations` 记录了「回退 g4 及之后」，G4 已用新 state 重新记录；verification.md 的 state 与本报告一致。
- 第 2 轮新发现关键问题：无。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

1. 【第 1 轮，已于第 2 轮确认修复】`template/scripts/ai-gate.sh:236-246`（`ck_trace_g3` 需求覆盖矩阵空单元格检查）漏掉了全角空格归一。
   - 现象：矩阵直接从原始 design.md 用 awk 截取（:236），单元格用 `gsub(/^[[:space:]]+|[[:space:]]+$/…)` 判空（:244），没有经过 `section_body` 或 `sed 's/　/ /g'`。实测：把本 Spec 矩阵 ERR-02 行的「原文锚点」单元格改成只有一个全角空格（U+3000），`LC_ALL=C` 和无 locale 环境下 `check feat-t-000006 g3` 输出「✅ 校验通过」；`LC_ALL=C.UTF-8` 下输出「需求覆盖矩阵有空单元格或模板占位」并拒绝（沙箱为 `git archive HEAD` 的副本）。
   - 为什么阻塞：违反 requirements.md §0 关键业务规则「同一份 Spec 在 LC_ALL=C 与 UTF-8 下的门禁结论必须一致」。design.md §5 第 1 条说 `[[:space:]]` 的分歧“已在步骤 1 归一化”，但这个入口没覆盖。本机默认环境（无 LANG/LC_*）下，新 Spec 的 G3 追溯矩阵可以用全角空格占位通过，这和本 Spec 要修的门禁绕过属于同一类。
   - 修复指引（期望行为）：只在 `ck_trace_g3` 的矩阵文本上把全角空格替换为半角后再判空（例如 :236 的 awk 输出接 `sed 's/　/ /g'`，或在 awk 里先 `gsub("　"," ")`）。在自检里补一条 `env LC_ALL=C` 用例：矩阵单元格只有全角空格时 G3 被拒。不扩展到其他函数。

## 改进建议（非阻塞，"改善即批准"）
- `ai-gate.sh:88` 和 `:103` 是双重归一化：`section_body` 已经替换过，`field_ok` 再替换一次。结果无害，可以保留，但注释应说明 `field_ok` 也接收 `$(cat file)` 的原始文本（:149、:164），以免以后有人删掉其中一处。
- `ai-gate.sh:75-77`：`delegation_fields` 的输出会参与 G3 授权快照哈希（:607）和 G6 比对（:502）。归一化发生在哈希之前，两端都用新脚本时结果一致。只有一种边缘情况会让 G6 报「授权快照不一致」：G3 用旧脚本通过，而委托行里含全角空格。这时应提示重新过 G3，不需要改代码。
- `tasks.md` §3 已记录 `ai-task-pool.sh` 的 `nonblank()` 分歧。建议另立任务时一起扫描「直接对原始文件做 `[[:space:]]` 判空」的写法，作为 K-0001 的检查清单。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 Bash 门禁脚本，无用户身份 |
| 鉴权中间件 | 不适用 | 无网络入口 |
| SQL 参数化 | 不适用 | 无数据库 |
| 无敏感信息硬编码 | ✅ | diff 中无密钥；自检邮箱为 `selftest@example.invalid`（harness-selftest.sh 新增 locale-baseline 提交） |
| 入参边界校验 | ✅ | `ai-gate.sh:317` 新增象限枚举校验，无效则拒绝 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01 已落实，`ai-gate.sh:52`、`:159` 改为交替写法；ERR-01 已落实，`:317` 对无效象限 fail-closed；REQ-02 / ERR-02 已落实，`ai-resume.sh:51` 用 index 判前缀，`ai-state-id.sh:37` 用 `(：|:)`；REQ-03 已落实，`harness-selftest.sh:350-360`、`:536-542`、`:641-655` 有 LC_ALL=C 用例。AC-01：本次在无 LANG/LC_* 环境下自检 223 项、失败 0 项。AC-02/03/04：把三个脚本换成 f0ea114 版本后，新自检失败 29 项，其中包括全部 LC_ALL=C 新用例（象限、无效象限、全角空格、worker 全角括号、指纹全角括号），说明这些用例能防住回归。AC-05：`grep -rn 'LC_ALL=C.UTF-8|export LC_ALL|export LANG' template/scripts` 无结果，脚本没有强制设置 locale。遗漏：§0 关键业务规则「两种 locale 结论一致」在覆盖矩阵判空处不成立（见关键问题 1）。无超纲改动。
- 知识检索：K-0001（模板机制，awk/grep locale）是唯一候选，予以采用并核对内容。卡片结论正确，「旧脚本跑新用例失败 29 项」与我的实测一致；「空白判断前把全角空格替换为半角」作为规则正确，但实现尚未完全遵守。活文档 `template-mechanism.md` 写的「全角空格在空白判断前归一为半角」第 1 轮与 `ai-gate.sh:236-246` 不符；第 2 轮修复后，与代码一致。
- AI 协作文件审查：本次改动了 `.knowledge/cards/K-0001.md`、`.knowledge/INDEX.md`、`docs/architecture/modules/template-mechanism.md`，没有改 AGENTS.md 或 Skill。卡片关联路径已补 ai-resume / ai-state-id，复核期限 2027-04-20 有效。第 2 轮复核：活文档的描述与代码一致。
- 审查范围限制：只在 Windows Git Bash（GNU Awk 5.4.1）下实测，没有覆盖 mawk/BSD awk、macOS grep 的行为；`bin/` 未改，未审查。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000006 template/scripts/ai-gate.sh` → `verification.md`：result PASS / checks 1 / state 00494b4f…6b00
- 无 locale 环境，HEAD 副本运行 `bash scripts/harness-selftest.sh` → 223 项断言，失败 0 项
- 同一副本把三个脚本换成 `git show f0ea114:…` 后运行自检 → 223 项断言，失败 29 项（新增 LC_ALL=C 用例均失败）
- 沙箱复现关键问题 1（第 1 轮）：矩阵单元格只有全角空格时，`LC_ALL=C` 和无 locale 下 g3 通过，`LC_ALL=C.UTF-8` 下 g3 被拒
- 第 2 轮：verification.md 的 state 为 92cb6686…b938，result PASS；HEAD 副本自检 224 项、失败 0 项；只回退修复后自检失败 1 项

knowledge_feedback: 无（第 1 轮反馈的活文档与代码不符已随 bad5454 修复消除）
