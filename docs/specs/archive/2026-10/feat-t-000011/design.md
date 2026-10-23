# 技术架构与接口设计：feat-t-000011

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：项目指南 → `docs/architecture/modules/guidance.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 契约入口（只读）：`template/scripts/ai-gate.sh`
- 新增模块：无
- 人工前置决策：不适用（①）；兼容方式已由维护者选 A，见 requirements.md §4。

## 1. 架构变更与数据流

只改 `ck_g6` 中委托快照不一致时的 `say` 文案，追加升级提示；比对与哈希代码不动。升级指南在 `retrofit-legacy.md` 第 21 行升级段后补一句。自检在原用例「G6 拒绝 G3 后补写的委托」旁加一条，断言输出含升级提示。

### 1.1 需求覆盖矩阵（①可精简）

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 报错含升级提示 | §2 步骤 1 | AC-01 |
| REQ-02 | 升级指南说明 | §2 步骤 1 | AC-03 |
| ERR-01 | 校验不放宽 | §2 步骤 1 | AC-02 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：改 `template/scripts/ai-gate.sh` 第 507 行文案；`template/.agents/skills/retrofit-legacy.md` 升级段补说明；`template/scripts/harness-selftest.sh` 加提示断言；自检与正式验证。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 退出码不变，报错多半句。

### 3.3 契约兼容性
- 判定不变。

## 4. 影响面与涉及文件清单

- **修改文件**：
  - `template/scripts/ai-gate.sh`：G6 报错文案
  - `template/.agents/skills/retrofit-legacy.md`：升级说明
  - `template/scripts/harness-selftest.sh`：提示断言
- **只读依赖契约**：
  - `template/harness/redlines.conf`

- 间接消费者 / 副作用：`retrofit-legacy.md` 属受管理指南，upgrade 时随之分发；README 与 CLI 不描述该报错文案，无需改。
- 检索依据：`grep -n "授权快照不一致" template/scripts/*.sh` 命中 ai-gate.sh 第 507 行与自检第 510 行；`grep -n "upgrade" template/.agents/skills/retrofit-legacy.md` 命中第 21 行升级段。
- 复用检索：沿用现有 `say` 报错与 `expect_fail` 断言，不新增函数。

## 5. 对抗自审

1. 最可能错在哪：提示被理解为「升级后可以绕过」；文案明确是「重过 G3」，仍要人重新授权快照。
2. 关键前提：「这种情况极少，说明足够」——维护者已据此选 A。
3. 边界：原「事后补写须重过 G3」语义保留在同一句中。
4. 能否更简单：已最小。
5. 回滚：`git revert`。

- 独立设计审查：不适用（①）
- **自审结论**：可实施。

## 6. 待确认问题
- 无。

## 7. 风险与回滚
- **风险**：极低。
- **回滚方式**：`git revert`。
