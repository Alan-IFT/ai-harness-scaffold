# 技术架构与接口设计：feat-t-000010

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：无
- 契约入口（只读）：`template/scripts/ai-task-pool.sh`
- 新增模块：无
- 人工前置决策：不适用（①）

## 1. 架构变更与数据流

`nonblank()` 内先用 bash 参数替换把全角空格换成半角，再做 `[^[:space:]]` 判断。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 有文字照常收录 | §2 步骤 1 | AC-03 |
| ERR-01 | 纯全角空格被拒 | §2 步骤 1 | AC-01 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：改 `template/scripts/ai-task-pool.sh` 第 27 行；`template/scripts/harness-selftest.sh` 在「拒绝空白原话」「拒绝空白补充」旁加 `LC_ALL=C` 纯全角空格用例；沙箱换回旧函数确认用例报出；无 locale 自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 无变化。

### 3.3 契约兼容性
- 只多拒绝纯全角空格输入。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/ai-task-pool.sh`：nonblank
  - `template/scripts/harness-selftest.sh`：两项用例
- **只读依赖契约**：
  - `template/scripts/ai-config.sh`

- 间接消费者 / 副作用：`nonblank` 只在 add / intake 的原话与 update 的补充处调用（第 118、145 行），无其他调用方。
- 检索依据：`grep -n "nonblank" template/scripts/*.sh` 只命中 ai-task-pool.sh 的定义与两处调用。
- 复用检索：与 ai-gate.sh 的全角空格归一同一做法（K-0001），不抽公共函数，因为脚本之间不共享库。

## 5. 对抗自审

1. 最可能错在哪：bash 参数替换中的全角空格在字节 locale 下能否作为整体匹配；先在沙箱实测。
2. 关键前提：「有人会输入纯全角空格」——概率低，但修复成本极低且消除 locale 分歧。
3. 边界：全角空格与制表符混合仍被拒。
4. 能否更简单：已最小。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：极低。
- **回滚方式**：`git revert`。
