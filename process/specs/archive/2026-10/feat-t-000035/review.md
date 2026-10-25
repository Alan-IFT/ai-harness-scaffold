# 审查：feat-t-000035

- 审查者：独立 subagent 审查上下文 / Claude Sonnet 5.5 / 新会话（g3）
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：dd1784c171efe268970bef2c58e2610ecf7eff7606be7ab13a03c4a1c9ddfa36
- 审查范围：6e27149...HEAD + 工作区（改动均在未提交工作区）

我没写过这段代码，只依据产物判断。

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不适用（需人决定：否）
- 决策来源：不适用

## 关键问题
无

## 改进建议
- `template/scripts/ai-gate.sh:90`：`grep '涉及文件'` 是整行子串匹配，若其他行（如 WIP 区）恰好含「涉及文件」字样并写了目标路径仍会放行；概率极小，需求所述场景已解决，可记入「发现但不碰」。
- 自检未覆盖「同一行多个反引号路径」「AC-1 与 AC-10」，但 `grep -F` 带反引号整串匹配、`grep -qx` 整行匹配逻辑上天然正确，不阻塞。

## 证据
- 验证：verification.md 的 result: PASS / state: dd1784c171efe268970bef2c58e2610ecf7eff7606be7ab13a03c4a1c9ddfa36
- AC-01：自检新增 t-acprose（正文提 AC-07 不误拒）、t-acnoline（只在正文出现则拒）；ai-gate.sh:69-76。
- AC-02：自检新增 t-wiponly（目标只在 WIP 区则拒）；ai-gate.sh:90。
- AC-03：`bash scripts/harness-selftest.sh` 实跑：72 项断言，失败 0 项。
- 边界：无「对应验收」行时 refs 为空，`printf '%s\n' "" | grep -qx` 不匹配而拒绝，第二个循环空展开无害；脚本未设 set -e/-u（grep 无匹配返回 1 不致命）；全角冒号不影响（只匹配关键词，不依赖冒号）；AC-1/AC-10 由 `grep -oE 'AC-[0-9]+'` 取整后 `grep -qx` 整行比较；模板 tasks.md:14-15 格式与新匹配兼容。
- 范围：仅两处匹配与对应断言，无超出需求的行为。
