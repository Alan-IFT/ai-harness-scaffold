# 技术架构与接口设计：feat-t-000005

- 关联需求：`requirements.md`（G1 / G2 已通过）
- 设计者：Claude Code（Opus 5.5）
- 状态：Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：项目指南 → `docs/architecture/modules/guidance.md`
- 涉及模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 契约入口（只读）：`template/scripts/ai-gate.sh`、`template/harness/redlines.conf`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-22「那按照你的建议来做吧，但我想把这个脚手架做成不绑定宿主的」；取舍：落地建议 1~4，放弃宿主专属 hook，G2 新增含糊词检查，独立设计审查与复用检索只进指南与模板不加 G3 校验；结论：同意。

## 1. 架构变更与数据流

目标项目通过 `template/` 获得指南、Spec 模板与门禁脚本；任何宿主的 Agent 都只读写项目文件并调用 Bash 脚本，所以换宿主续做不受影响。唯一的运行时变化是 `ck_g2` 在现有空单元格检查之后，扫描 `requirements.md` §3 中含 `AC-xx` 的行：用 index/substr 成对剥离「…」『…』与 `…` 包裹的片段（不用字符类，字节 locale 下也正确），删去「合理性」「及时性」复合词，再用字面量匹配内置含糊词表；英文先 tolower，用 `(^|[^a-z])词([^a-z]|$)` 判词边界（不用 `\b` 或 `\<`，gawk/mawk/BSD awk 通用）。命中则输出词与行并拒绝。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | 建议 1；②③默认独立设计审查，跨宿主换上下文 | §2 步骤 3：design.md §5、new-spec.md Step 6 | AC-02 |
| REQ-02 | 建议 2；只扫 AC 行，输出命中词 | §2 步骤 1：ai-gate.sh `ck_g2` | AC-01 |
| REQ-03 | 建议 3；捕获信号、纠正替换、晋升活文档；须随 upgrade 分发 | §2 步骤 4：AGENTS.md §3、gc-memory.md，MEMORY.md 留指针 | AC-03 |
| REQ-04 | 建议 4；复用检索三要素 | §2 步骤 3：design.md §4、new-spec.md Step 4 | AC-04 |
| ERR-01 | 引号内原文豁免，任意 locale | §2 步骤 1：index/substr 成对剥离「」『』与反引号 | AC-01 |
| ERR-02 | 已过 G2 的 Spec 不回溯 | §1：ck_g2 只在 check/pass g2 运行，pass 后续门不重跑 | AC-01 |
| AC-01 | G2 正反例 | §2 步骤 2：selftest 用例 | AC-01 |
| AC-02 | 设计审查记录位 | §2 步骤 3 | AC-02 |
| AC-03 | 记忆规则 | §2 步骤 4 | AC-03 |
| AC-04 | 复用检索字段 | §2 步骤 3 | AC-04 |
| AC-05 | 宿主无关与回归 | §2 步骤 5 与检查点 2 | AC-05 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：`template/scripts/ai-gate.sh` 的 `ck_g2` 增加含糊词扫描；词表：适当、尽量、尽可能、合理（先删「合理性」）、及时（先删「及时性」）、尽快、大概、大约、酌情、视情况、若干、等等、appropriate、reasonable、as needed、asap、etc.；「一些」「友好」因复合词误报多而不收。可运行状态：`check g2` 对本 Spec 仍通过。
2. 步骤 2：`template/scripts/harness-selftest.sh` 增加用例：裸词「尽量」被拒并显示命中词；`LC_ALL=C` 下「尽快处理。」引号内通过；Etc. 大写被拒；「合理性校验」通过；说明行（非 AC 行）的含糊词不拦。验证：`bash scripts/harness-selftest.sh`。
3. 步骤 3：`design.md` 模板 §4 增「复用检索」行、§5 增「独立设计审查」行；`new-spec.md` Step 4/6 写填写要求与跨宿主换上下文方式；`requirements.md` 模板 §3 说明 G2 含糊词规则与引号豁免；`AGENTS.md` G2 行补「无含糊词」。
4. 步骤 4：`AGENTS.md` §3 增一行记忆捕获与纠正替换规则；`gc-memory.md` 增晋升步骤；`MEMORY.md` 模板头部加一行指向这两处（MEMORY.md 不受 upgrade 管理，见 `bin/ai-harness` 的 managed_file）。
5. 步骤 5：同步 `docs/architecture/modules/guidance.md`、`template-mechanism.md`，跑体积体检、自检与正式验证。

- **检查点**：
  - 检查点 1（第 2 步后）：selftest 全绿，G2 正反例都命中预期。
  - 检查点 2（第 5 步后）：`git diff --stat` 无宿主专属文件；`ai-check-bloat.sh` 通过；正式验证 PASS。
- **拆分自查**：每步 ≤5 文件；步骤 3 跨模板与指南但同属文本规则，不含运行时逻辑。
- 边界样本：AC 行写「尽量 2 秒内返回」应拒绝；写 按钮文案为「尽快处理」 应通过；写 `ASAP` 于反引号内应通过；写 Etc. 大写应拒绝；说明文字（非 AC 行）出现「尽量」不应拒绝；「合理性校验」应通过（先删复合词「合理性」「及时性」）。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- `ai-gate.sh check <feat> g2` 退出码语义不变：通过 0、拒绝非 0；新增拒绝消息「AC 含含糊词：<词>（加引号表示原文或改成可判定条件）」及所在行。

### 3.3 契约兼容性
- 已过 G2 的 Spec 不重跑 G2（pass 只读 `.gates`）；未过 G2 的在途 Spec 在 `status` 预检下一门时会显示新的阻断原因，修改 AC 或给被测原文加引号即可。模板写明豁免只用于被测文案原文，不能整格加引号绕过。

## 4. 影响面与涉及文件清单

- **新建文件**：
  - 无
- **修改文件**：
  - `template/scripts/ai-gate.sh`：ck_g2 含糊词扫描
  - `template/scripts/harness-selftest.sh`：G2 正反例
  - `template/docs/specs/_templates/requirements.md`：§3 规则说明
  - `template/docs/specs/_templates/design.md`：§4 复用检索、§5 独立设计审查
  - `template/.agents/skills/new-spec.md`：Step 4 / Step 6
  - `template/MEMORY.md`：指向 AGENTS §3 与 gc-memory 的一行
  - `template/.agents/skills/gc-memory.md`：晋升步骤
  - `template/AGENTS.md`：G2 行、§3 记忆捕获行
  - `docs/architecture/modules/guidance.md`：结果说明
  - `docs/architecture/modules/template-mechanism.md`：G2 行为说明
- **只读依赖契约**：
  - `template/harness/redlines.conf`
  - `template/scripts/ai-config.sh`

- 间接消费者 / 副作用：`bin/ai-harness` 安装与 upgrade 会把模板分发到目标项目，upgrade 对定制文件走冲突合并；根目录 `scripts/` 转发到模板脚本，本仓库自身 Spec 同样受新 G2 约束；`README.md` 未描述 G2 细则（grep「G2」无命中），无需改。
- 检索依据：`grep -n "ck_g2" template/scripts/*.sh`、`grep -n "G2\|含糊" README.md`、`grep -rn "适当|尽量" template/scripts template/docs/specs/_templates`（仅 requirements.md 的「含糊时」说明命中，非 AC 行）。
- 复用检索：搜 `template/scripts/ai-gate.sh` 中已有的 AC 行 awk 扫描（ck_g2 空单元格检查）与 `section_body`；复用 `section_body` 取 §3，按同一「含 AC-xx 的行」口径扫描，不新建函数库。

## 5. 对抗自审

1. 最可能错在哪：子串误报，例如「合理性」「一些列」「等等待」；词表偏中文，英文 AC 覆盖有限。
2. 关键前提：「含糊词会让 AI 把 AC 做通过」——来自博客经验，未在本仓库测量；低成本证伪：回看已归档 12 个 Spec 的 AC 行有无这些词，若历来为零，规则价值有限但成本也近零。已执行：12 个归档 Spec 的 AC 行剥离引号后零命中——不误拦现有写法，本仓库收益未证实，价值主要在下游项目。
3. 边界：AC 行跨多行的表格不存在（Markdown 表格单行）；「」『』与反引号都豁免；未闭合的引号不豁免。
4. 能否更简单：不做可配置词表，内置保守列表；不加 G3 校验。
5. 回滚：回退 ai-gate.sh 与 selftest 两个文件即可，模板文字独立。

- 独立设计审查：审查者：独立 subagent（未参与设计，只读）；结论：首轮「需修改」，3 项关键问题——字节 locale 下引号剥离失效（已实测复现）、`\b` 不可移植、MEMORY.md 不随 upgrade 分发（已核对 `bin/ai-harness` managed_file）——均已改入本设计；采纳删「一些」「友好」、补『』、写明豁免边界、status 预检影响等建议。
- **自审结论**：可实施；误报靠引号豁免与模板提示缓解。

## 6. 待确认问题
- [x] Q1：是否给独立设计审查加 G3 校验 → 结论：不加，先观察。

## 7. 风险与回滚
- **风险**：下游在途 Spec 首次 pass g2 时被新规则拦下。
- **回滚方式**：`git revert` 本 Spec 的提交。
