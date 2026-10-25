# 技术架构与接口设计：feat-t-000006

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：无
- 契约入口（只读）：`template/scripts/ai-gate.sh`、`template/scripts/ai-resume.sh`、`template/scripts/ai-state-id.sh`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-22「那就按照推荐处理」（针对方案 A/B/C）；取舍：修脚本为 locale 无关写法并加字节 locale 回归，不强制 LC_ALL，不只修自检；结论：同意。

## 1. 架构变更与数据流

门禁脚本在任何宿主下都由 Bash 调 grep/awk 解析 Spec 文本。改动只替换三处把多字节字符放进方括号字符类的正则：字节 locale 下字符类按字节匹配，单个字节会被当成一个「字符」。字面量交替（`①|②|③|④`、`(：|:)`）在两种 locale 下都按完整字节序列匹配。G3 再加一道 fail-closed：象限不是 ①~④ 之一就拒绝。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 象限返回完整字符 | §2 步骤 1：`quadrant()` 与 G1 象限检查改交替写法 | AC-01 |
| REQ-02 | 只认三种分隔符 | §2 步骤 2：`ai-resume.sh` 用 index 判前缀，`ai-state-id.sh` 用 `(：|:)` | AC-04 |
| REQ-03 | 自检字节 locale 回归 | §2 步骤 3：自检新增 LC_ALL=C 用例 | AC-02 |
| ERR-01 | 象限无效 G3 拒绝 | §2 步骤 1：`ck_g3` 开头校验 q | AC-03 |
| ERR-02 | 全角括号不算分隔 | §2 步骤 2 | AC-04 |
| AC-01 | 无 locale 自检全过 | §2 检查点 2 | AC-01 |
| AC-02 | C 下用例 | §2 步骤 3 | AC-02 |
| AC-03 | 无效象限 | §2 步骤 3 | AC-03 |
| AC-04 | 冒号分隔 | §2 步骤 2 沙箱命令 | AC-04 |
| AC-05 | 回归与不强制 locale | §2 检查点 2 | AC-05 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/ai-gate.sh`：第 51、157 行 `[①②③④]` 改 `①|②|③|④`；`ck_g3` 取 q 后若不是 ①~④ 之一，输出「需求象限无效」并拒绝。全角空格（U+3000）在 C 下不属于 `[[:space:]]`、在 UTF-8 下属于，会让「冒号后只有全角空格」的字段在 C 下被判为已填：在 `section_body` 输出、`field_ok`、`field_value`、`delegation_fields`、G1 加权总分、G5/G6 的 `nv` 归一化处，统一先把全角空格替换为半角空格（sed 字面量 `s/　/ /g`，awk 用 gsub 字面量），再做空白判断。
2. 步骤 2：`template/scripts/ai-resume.sh` 第 50 行改为取编号后的剩余串 rest，`substr(rest,1,1)` 为半角冒号或空格、或 `index(rest,"：")==1` 才匹配；`template/scripts/ai-state-id.sh` 第 37 行 `[：:]` 改 `(：|:)`。
3. 步骤 3：`template/scripts/harness-selftest.sh` 新增「字节 locale 回归」节，用显式 `env LC_ALL=C`（宿主默认 UTF-8 时仍执行）复跑：②缺前置决策被 G3 拒绝、②缺边界样本被拒、④可记录 G1、①单步设计通过、无效象限被 G3 拒绝、前置决策冒号后只有全角空格被 G3 拒绝；`ai-resume.sh worker` 对「Task 1（」不匹配、对「Task 1：」匹配；`ai-state-id.sh` 对「指纹范围确认（…）」不启用 scoped、对「指纹范围确认：…」启用 scoped。
4. 步骤 4：`docs/architecture/modules/template-mechanism.md` 补 locale 无关约束；知识卡 K-0001 扩充为字符类通用规则并刷新复核日期。

- **检查点**：
  - 检查点 1（第 2 步后）：沙箱中 LC_ALL=C 与 C.UTF-8 下 `ai-resume.sh worker` 对「Task 1：」「Task 1（」结论一致。
  - 检查点 2（第 4 步后）：`env -u LC_ALL -u LANG` 与 `LC_ALL=C.UTF-8` 两种方式自检都 0 失败；正式验证 PASS；脚本中没有强制设置 locale。
- **拆分自查**：每步 ≤2 文件，无跨子系统。
- 边界样本：象限行写「⑤」或「X」→ G3 拒绝；象限行写「②」但缺前置决策、LC_ALL=C → G3 拒绝；「Task 1（备注）」在两种 locale 下都不匹配 Task 1；「- 指纹范围确认：已核对…」在 LC_ALL=C 下仍识别为 scoped。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- 命令行接口与退出码不变。新增拒绝消息：G3「需求象限无效（须为 ①/②/③/④）」。

### 3.3 契约兼容性
- UTF-8 环境下结论不变；字节 locale 下由错误结论改为正确结论。已过 G3 的 Spec 不重跑 G3。

## 4. 影响面与涉及文件清单

- **新建文件**：
  - 无
- **修改文件**：
  - `template/scripts/ai-gate.sh`：象限识别与 G3 fail-closed
  - `template/scripts/ai-resume.sh`：任务编号分隔判断
  - `template/scripts/ai-state-id.sh`：指纹范围确认行匹配
  - `template/scripts/harness-selftest.sh`：字节 locale 回归
  - `docs/architecture/modules/template-mechanism.md`：locale 无关约束
  - `.knowledge/cards/K-0001.md`、`.knowledge/INDEX.md`：扩充结论
- **只读依赖契约**：
  - `template/harness/redlines.conf`

- 间接消费者 / 副作用：根目录 `scripts/` 转发到模板脚本，本仓库门禁同样受益；`bin/ai-harness` 安装与 upgrade 分发 `scripts/*.sh`；`ai-task-pool.sh` 的 `= 无`、`= 待办` 是整串比较，不受 locale 影响。
- 检索依据：`LC_ALL=C.UTF-8 grep -nP '\[[^\]]*[^\x00-\x7F][^\]]*\]' template/scripts/*.sh bin/ai-harness`，人工排除 `[ ... ]` 测试命令与 echo 文本后，剩 ai-gate.sh:51、:157，ai-resume.sh:50，ai-state-id.sh:37 四处字符类；无 locale 自检的 21 项失败全部追溯到 `quadrant()`。
- 复用检索：feat-t-000005 在 `ck_g2` 已用 index/substr 与字面量匹配处理多字节文本，本次沿用同一写法；不新增公共函数。

## 5. 对抗自审

1. 最可能错在哪：遗漏其他依赖 locale 的写法。`${#var}`、`tolower`、`sort`、`tr` 只作用于 ASCII 或成对 index/substr，不构成分歧；`[[:space:]]` 对全角空格在 C 与 UTF-8 下结论不同（初稿判断错误，独立审查实测纠正），已在步骤 1 归一化。`ai-task-pool.sh` 的 `nonblank()` 对纯全角空格的需求原话同样分歧，但不是门禁判定，记入「发现但不碰」。
2. 关键前提：「宿主可能在无 UTF-8 locale 的 shell 里跑脚本」——本机 Git Bash 环境变量里就没有 LANG/LC_*，已实测；即使宿主通常是 UTF-8，修复成本也很低。
3. 边界：象限行同时写多个符号时取第一个，与原行为一致。
4. 能否更简单：方案 B（强制 locale）更短，但已被维护者否决，原因是 locale 可用性随系统而变。
5. 回滚：`git revert` 本 Spec 提交。

- 独立设计审查：审查者：独立 subagent（未参与设计，只读）；结论：首轮「需修改」，2 项关键问题——全角空格在两种 locale 下 `[[:space:]]` 结论不同、可绕过字段非空检查（已实测复现：C 下 0、C.UTF-8 下 1）；ai-resume / ai-state-id 修复只有手工验证、无自检回归——均已改入步骤 1 与步骤 3；根因判断与修法可移植性经审查确认。
- **自审结论**：可实施。

## 6. 待确认问题
- [x] Q1：是否强制 locale → 结论：否。

## 7. 风险与回滚
- **风险**：G3 新增 fail-closed 可能拦下象限行格式不规范的在途 Spec；G1 已要求象限，正常 Spec 不受影响。
- **回滚方式**：`git revert`。
