# 技术架构与接口设计：feat-t-000007

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：无
- 契约入口（只读）：`template/scripts/ai-gate.sh`
- 新增模块：无
- 人工前置决策：不适用（①）；「大概率」取舍已由维护者选 A，见 requirements.md §4。

## 1. 架构变更与数据流

只改 `ck_g2` 的含糊词扫描：中文词表把「大概率」放在「大概」之前，命中时报完整词；英文词边界由 `[^a-z]` 改为 `[^a-z0-9_]`。bash 侧在命中「大概率」时追加改写示例。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 独立英文词仍拦 | §2 步骤 1 | AC-02 |
| REQ-02 | 「大概率」报完整词与示例 | §2 步骤 1 | AC-03 |
| ERR-01 | 标识符片段不拦 | §2 步骤 1 | AC-01 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/ai-gate.sh` 改词表顺序、英文边界与「大概率」提示；`template/scripts/harness-selftest.sh` 补正反例；同步 `docs/architecture/modules/template-mechanism.md` 的边界描述。验证：两种 locale 自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 退出码不变；「大概率」命中时提示多一行改写示例。

### 3.3 契约兼容性
- 只减少标识符误拦，不新增拦截。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/ai-gate.sh`：ck_g2
  - `template/scripts/harness-selftest.sh`：G2 用例
  - `docs/architecture/modules/template-mechanism.md`：边界描述
- **只读依赖契约**：
  - `template/harness/redlines.conf`

- 间接消费者 / 副作用：`requirements.md` 模板说明未枚举英文边界，无需改；根目录 `scripts/` 转发。
- 检索依据：`grep -n "a-z" template/scripts/ai-gate.sh` 仅 ck_g2 一处英文边界；`grep -rn "大概" template docs/architecture` 只在 ck_g2 词表与活文档出现。
- 复用检索：沿用 ck_g2 现有字面量匹配与 tolower 写法，不新增函数。

## 5. 对抗自审

1. 最可能错在哪：边界放宽后，`asap2` 这类写法不再被拦；它是标识符，可接受。
2. 关键前提：「标识符应加反引号，但作者常不加」——本 Spec 的 AC 首稿即因未加引号被拦，已实测。
3. 边界：`etc.` 后紧跟字母、数字或下划线（如 `config.etc.json`、`etc.1`）视为标识符不拦；首版去掉了 etc 右边界导致新增误拦，G5 指出后恢复。
4. 能否更简单：已是最小改动。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：极低。
- **回滚方式**：`git revert`。
