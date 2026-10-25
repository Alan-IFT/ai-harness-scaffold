# 任务与接力：feat-t-000035

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000035` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：`ck_g1` 先 `grep '对应验收'` 取出引用行，双向核对都只在这些行里找；`ck_g2` 先 `grep '涉及文件'` 再找反引号路径。
- 改动文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`。
- 影响与风险：变严的只有「AC 只在正文出现」这一种写法，模板与指南本来就要求写「对应验收」行。

## 2. 任务
- [x] Task 1：收窄两处匹配并补断言
  - 对应验收：AC-01、AC-02、AC-03
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh`

## 3. 发现但不碰
- `template/scripts/ai-gate.sh:90` 按整行子串匹配「涉及文件」，其他行恰好含该字样并写了目标路径仍会放行，概率极小（审查建议）
- 自检未覆盖「多路径同行」与「AC-1 与 AC-10」，逻辑上已正确（审查建议）

## 4. WIP 接力区
- 当前任务：无（待审查）
- 已完成：Task 1
- 正在编辑的文件：无
- 已排除的方案：无
- 下一步：独立审查 g3
