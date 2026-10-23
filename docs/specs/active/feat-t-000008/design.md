# 技术架构与接口设计：feat-t-000008

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：项目指南 → `docs/architecture/modules/guidance.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 契约入口（只读）：`template/scripts/ai-gate.sh`
- 新增模块：无
- 人工前置决策：不适用（①）；例子去留已由维护者选 A，见 requirements.md §4。

## 1. 架构变更与数据流

模板说明加半句指向脚本。自检在沙箱里读 `docs/specs/_templates/requirements.md` 中含「G2 拒绝 AC 行里的含糊词」的一行，用 awk 以字面量「「」切分、再用 index 找「」」截出例子；去掉末尾句点后，逐个在 `scripts/ai-gate.sh` 含 `split("` 的词表行里查找。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 以脚本为准 | §2 步骤 1 | AC-01 |
| REQ-02 | 例子都在词表 | §2 步骤 1 | AC-02 |
| ERR-01 | 不一致报出该词 | §2 步骤 1 | AC-03 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：改 `template/docs/specs/_templates/requirements.md` 第 50 行；在 `template/scripts/harness-selftest.sh` 的 G2 用例后加一致性检查；沙箱删词验证能报出；两种 locale 自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 无变化。

### 3.3 契约兼容性
- 门禁行为不变。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/docs/specs/_templates/requirements.md`：G2 说明
  - `template/scripts/harness-selftest.sh`：一致性检查
- **只读依赖契约**：
  - `template/scripts/ai-gate.sh`

- 间接消费者 / 副作用：`ai-new-spec.sh` 复制该模板生成新 Spec，说明会出现在新 Spec 中；已有 Spec 不变。活文档不列词表，无需改。
- 检索依据：`grep -rn "适当\|尽可能\|视情况\|酌情" template docs/architecture README.md skill`，只命中模板第 50 行与 `ai-gate.sh` 第 210 行。
- 复用检索：自检沿用已有 `ok_msg` / `ng_msg` 输出；抽取写法遵循 K-0001（不用多字节字符类）。

## 5. 对抗自审

1. 最可能错在哪：抽取到空例子（「」『』说明本身）；跳过空串即可。
2. 关键前提：「以后会改词表」——T-000007 刚改过词表顺序，已发生过。
3. 边界：例子「etc.」去掉句点后在英文词表行查 `etc`；子串查找可能把「大概」误判为存在于「大概率」中，可接受，因为两者都在词表。
4. 能否更简单：只加说明不加检查更简单，但起不到防漂移作用。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：极低。
- **回滚方式**：`git revert`。
