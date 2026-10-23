# 技术架构与接口设计：feat-t-000009

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：无
- 契约入口（只读）：`template/scripts/ai-gate.sh`
- 新增模块：无
- 人工前置决策：不适用（①）

## 1. 架构变更与数据流

只在 `harness-selftest.sh` 的 t-vague 用例组追加 4 项。非 AC 行：在 §3 的说明行加入含糊词，AC 行保持干净。『』：AC 行写『适当』。未闭合：AC 行写「尽量 2 秒（缺右引号）。awk 失败：在 `$TMP` 建包装 awk，参数含 `function strip` 时 `exit 2`，否则 `exec` 真实 awk 路径；用 `env PATH=...` 只对这一次 G2 调用生效。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 非 AC 行不拦 | §2 步骤 1 | AC-01 |
| REQ-02 | 『』豁免 | §2 步骤 1 | AC-01 |
| ERR-01 | 未闭合仍拦 | §2 步骤 1 | AC-01 |
| ERR-02 | awk 失败拒绝 | §2 步骤 1 | AC-01 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/harness-selftest.sh` 追加 4 项用例；沙箱分别破坏 ck_g2 的 AC 行过滤、『』剥离、未闭合 break、失败 `||` 处理，确认对应用例报出；`docs/architecture/modules/template-mechanism.md` 记录 mawk 1.3.4 与 onetrue-awk 20250116 实测结果；无 locale 自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 无变化。

### 3.3 契约兼容性
- 门禁行为不变。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/harness-selftest.sh`：4 项用例
  - `docs/architecture/modules/template-mechanism.md`：跨 awk 实测记录
- **只读依赖契约**：
  - `template/scripts/ai-gate.sh`

- 间接消费者 / 副作用：无；自检只在沙箱运行。
- 检索依据：`grep -n "t-vague" template/scripts/harness-selftest.sh` 定位现有 G2 用例组；`grep -n "function strip" template/scripts/ai-gate.sh` 确认包装 awk 的识别特征唯一。
- 复用检索：沿用已有 `expect_ok` / `expect_fail` 与 t-vague 夹具，不新建夹具。

## 5. 对抗自审

1. 最可能错在哪：包装 awk 识别特征不唯一，误伤其他 awk 调用；已确认 `function strip` 只出现在 ck_g2。
2. 关键前提：「破坏逻辑后用例会报出」——用沙箱逐项验证，不只看当前通过。
3. 边界：未闭合引号用例要确认剥离循环 `break` 后剩余文本仍被扫描。
4. 能否更简单：已是最小改动。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：极低。
- **回滚方式**：`git revert`。
