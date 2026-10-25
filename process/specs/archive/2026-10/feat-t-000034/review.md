# 审查：feat-t-000034

- 审查者：独立 subagent（g3 审查上下文，未参与实现）/ Claude Sonnet 5.5 / 新会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：3fad30f6efc810106a99b00fe318b59d8c5e7ae6a63f401631a1affb5dc1d11d
- 审查范围：4cfb155...HEAD + 工作区（含暂存的 template/PREFERENCES.md 与未跟踪的任务文件）

我没写过这段代码，只依据产物判断。

## 结论
- 关键问题：0
- 改进建议：5
- 人工决定：不适用（需人决定：否）
- 决策来源：不适用

## 关键问题
无

## 改进建议
1. `template/scripts/ai-gate.sh:68-74`：g1 反向核对扫描整份 tasks.md 的 `AC-\d+`，「发现但不碰」等正文里提到别的 AC 编号（如引用历史 Spec）会被误拒。前缀匹配本身正确（`AC-1` 与 `AC-10` 不混，`([^0-9]|$)` 在 CRLF 下也成立）；`set -u` 无 `-e`，无匹配的 grep 不会中断脚本。可只扫「对应验收」行。
2. `template/scripts/ai-gate.sh:89`：g2 对 tasks.md 全文做 `grep -F` 反引号路径，WIP 区或正文里出现该路径也算通过，约束比「涉及文件」弱；与方案描述有出入但不构成漏洞。
3. `template/.agents/skills/upgrade.md`：删除版本说明时一并删掉了「降级：反向执行……」一句，而标题、`template/AGENTS.md:40`、`README.md:14` 仍写“升级与降级”。该文件现在没有任何降级的具体做法；步骤“同一套、目标版本不同”可视为覆盖，但建议补一句。
4. AC-06 的「模板 `.gitignore` 忽略 `PREFERENCES.md`」没有自检断言，证据靠人工试点（本次我复核：临时仓库里命中 `.gitignore:5`；本仓库 `template/PREFERENCES.md` 未被忽略，保持入库，一致）；AC-10 的试点结果只写在 tasks.md WIP 里，verification.md 无记录。建议自检加一条 check-ignore 断言。
5. `template/scripts/ai-task-pool.sh` 的 `field` 用 `sed` 取值，CRLF 任务文件里 `- 优先: 是\r` 不等于「是」，优先标记会被静默忽略（既有字段同样受影响，属已有行为）。

## 证据
- 验证：verification.md 的 result PASS / state 3fad30f6efc810106a99b00fe318b59d8c5e7ae6a63f401631a1affb5dc1d11d
- `bash scripts/harness-selftest.sh`：69 项断言，失败 0；`bash scripts/ai-check-bloat.sh` 正常。
- AC-01/02 对应 ai-gate.sh:68-74、89；AC-03 对应 ai-task-pool.sh:148-152 与自检 207-212；AC-04：任务池脚本里无 `prefer`/`update`/`NEXT` 残留（grep 仅命中活文档的“为什么”说明与 skill 的 `version: 2.0.0`，属合理），排序 `sort -t'|' -k1,2` 先优先后 ID，空池时 `selected_pending` 输出空；AC-05：编号扫描含 `process/specs/active/feat-t-*` 与 `archive/*/feat-t-*`，非 feat-t-* 目录不匹配 glob，`feat-t-abc` 被 `valid_id` 跳过，自检 298 行断言 T-000010；AC-07/08/09 grep 命中。
- 无超出需求的新行为；文档无 `update`/`prefer`/`NEXT`/1.x 迁移的残留引用。
knowledge_feedback: 无
