# 技术架构与接口设计：feat-t-000012

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

在 `section_body` 上方注释：它负责按章节抽取的文本（需求四项、AC、设计各节、委托等）。在 `field_ok` 注释：它还被直接传入整份文件或单行原文（ck_g1 的原始问题、象限行、分级依据），这些不经 section_body，所以自身也要归一；另有直接读文件的入口各自归一（需求覆盖矩阵、G5 / G6 的 nv）。自检在 G1 用例组加一条 `LC_ALL=C` 原始问题只填全角空格的拒绝用例。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 注释列入口 | §2 步骤 1 | AC-01 |
| ERR-01 | 原始问题全角空格被拒 | §2 步骤 1 | AC-02 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/ai-gate.sh` 加注释；`template/scripts/harness-selftest.sh` 加用例；沙箱删掉 field_ok 归一验证用例报出；自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 无变化。

### 3.3 契约兼容性
- 无变化。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/ai-gate.sh`：注释
  - `template/scripts/harness-selftest.sh`：一条用例
- **只读依赖契约**：
  - `template/harness/redlines.conf`

- 间接消费者 / 副作用：无。
- 检索依据：`grep -n "s/　/ /g" template/scripts/ai-gate.sh` 列出 6 处 sed 归一与 1 处 awk gsub；`grep -n 'field_ok "$(cat' template/scripts/ai-gate.sh` 等确认 field_ok 的原文入口为ck_g1 中原始问题、象限行、分级依据三处调用。
- 复用检索：沿用 t-noorigin 夹具的改写方式（mk_spec 后 sed 原始问题行）。

## 5. 对抗自审

1. 最可能错在哪：注释与代码以后不同步；用新用例约束最关键的一条。
2. 关键前提：「删 field_ok 归一现有自检发现不了」——实现时用沙箱验证。
3. 边界：象限行经 field_ok 时也走原文入口，同一层归一覆盖。
4. 能否更简单：只写注释更简单，但无法防止误删。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：无。
- **回滚方式**：`git revert`。
