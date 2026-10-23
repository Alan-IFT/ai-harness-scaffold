# 代码审查报告 (Code Review): feat-t-000005

- **审查者**：独立 G5 subagent（Claude Code / Opus 5.5，新上下文，只读；我没写过这段代码，只依据产物判断）
- **未参与实现**：是
- **审查时间**：2026-10-22
- **审查范围**：`git diff 1dee735...HEAD`（5 个提交，20 个文件）+ 第 2 轮工作区增量（`git diff`：INDEX.md、ai-gate.sh:217、design.md、tasks.md §3、verification.md）；对照 design.md §4 文件清单
- **CR 轮次**：2 / 4
- 审查状态：dc9812168d538141386923f123834fdecd325186cbf7fadc622c7593c51e22b2

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：3（第 2 轮后剩余 4~6，已记入 tasks.md §3）
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无。

## 改进建议（非阻塞，"改善即批准"）
1. `.knowledge/INDEX.md:5`：摘要列「词边界不用 ，」里有一个字面 0x08 退格控制字符（`od -c` 可见 `\b`），本该是 `` `\b` ``，所以摘要读不通。卡片原文 K-0001.md 是正确的。建议改成 `` `\b` `` 字面文本。同类问题：`design.md:92` 写成了「`b` 不可移植」（反斜杠丢失）。
2. design.md 内部有两处与实现不一致（不影响行为）：§5 第 3 条说「『』未豁免，模板只承诺「」与反引号」，但 ai-gate.sh 的 strip 和 requirements 模板都豁免了『』；§2 边界样本说「合理性校验 会被拒」，但 `gsub(/合理性|及时性/…)` 会放行它（自检也按放行断言）。归档前建议改正文字。
3. `template/scripts/ai-gate.sh:217` 的拒绝提示只写了「用「」或反引号标出」，没写『』；建议与模板说法一致。
4. 子串误报与漏报（已实测，非阻塞）：「大概率失败」会被拦（命中「大概」），`ASAP_mode` 会被拦（`_` 算非字母边界）；「不合理时报错」也会被拦，可以接受，但值得在模板提示里加一个例子。英文变形 `reasonably`、`appropriately` 漏报，属于设计已知取舍。
5. `template/scripts/harness-selftest.sh:277-283`：design §2 步骤 2 承诺的「非 AC 说明行不拦」没有对应自检用例；『』豁免、未闭合引号、awk 失败时 fail-closed 也没有用例。我在沙箱里手动跑了这些（见下文），行为都正确，建议补成回归用例。
6. 词表与豁免规则在 ai-gate.sh、requirements 模板、template-mechanism.md 三处各写了一遍；以后改词表时容易漏同步，可在 template-mechanism.md 注明「以 ai-gate.sh 为准」。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 改动只涉及 Bash 门禁与 Markdown，没有用户身份 |
| 鉴权中间件 | 不适用 | 没有服务入口 |
| SQL 参数化 | 不适用 | 没有数据库 |
| 无敏感信息硬编码 | ✅ | diff 中没有密钥、token 或内网地址 |
| 入参边界校验 | ✅ | awk 只读 §3 文本并做字面匹配，没有 eval；`template/scripts/ai-gate.sh:195-215` |
| 资源归属校验 | 不适用 | 没有多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：覆盖矩阵 REQ-01~04 / ERR-01~02 / AC-01~05 逐项有实现与证据，无遗漏或超纲；明细如下。
  - REQ-02 / AC-01：`ai-gate.sh:193-219` 只扫 `AC-NN` 行，命中时输出词与行并返回 1。我从脚本里抽出 awk 程序，用 17 条用例在 `LC_ALL=C` 和 `C.UTF-8` 下、gawk 默认 / `--posix` / `--traditional` 三种模式下测试，6 组结果一致：裸词「尽量」拒绝；「尽快处理。」（含「。」与「」」共享前缀的情况）、`ASAP`、『适当』、合理性、及时性均放行；`Etc.` 拒绝、`etc` 无点放行；未闭合「时仍拒绝；非 AC 行放行。
  - ERR-01：strip 用 index/substr，在字节和字符语义下自洽（UTF-8 自同步）。英文正则只用 `[^a-z]`、`^`、`$`，没有 `\b` 或 `\<`，mawk 和 BSD awk 可以解析。本机只有 gawk，mawk 和 BSD awk 未实测。
  - fail-closed：`bad=$(printf … | awk …) || return 1`，管道退出码取 awk 的，awk 出错时会拒绝；不受 pipefail 影响。
  - ERR-02：ck_g2 只在 `check_gate g2` 中调用（`ai-gate.sh:527`）；ck_g6 只重跑 g4 和 g5（`:453-455`），已过 G2 的 Spec 不会被回溯。本 Spec 自身的 g2 在两种 locale 下都通过。
  - REQ-01 / AC-02：design 模板 §5「独立设计审查」行与说明；new-spec.md Step 4 写了跨宿主换上下文的三种方式，Step 6 第 3 条写明②③先审再 pass g3、①可省略；AGENTS G3 行已同步。
  - REQ-03 / AC-03：AGENTS §3 列出三类信号和「写纠正前先删同主题旧条目」；gc-memory Step 1.6 有晋升后删除原条目的步骤；MEMORY.md 只留指针。已核对 `bin/ai-harness:89-94` managed_file 不含 MEMORY.md，落点正确。
  - REQ-04 / AC-04：design 模板 §4「复用检索」行，以及 new-spec Step 4 的三要素说明。
  - AC-05：diff 中没有 `.claude`、`.codex` 等宿主文件；指南里的「subagent」是通用写法，并列出新会话和其他工具作为替代；没有复述 redlines 的阈值数字。
  - 超纲或遗漏：无；Non-Goals 未被实现。`.violations` 中的 reset 记录说明设计审查后按规则回退并重过了 G1~G3。
- 知识检索：候选只有本次新增的 K-0001（模板机制）。卡片结论我逐条核实为真：「。」是 E3 80 82，「」」是 E3 80 8D；gawk 中 `\b` 是退格；mawk 和 BSD awk 没有 `\<`；`close` 是内置函数。结论可以复用，`ai-knowledge.sh check` 通过。索引行的控制字符问题见建议 1。活文档 guidance.md 和 template-mechanism.md 新增的两段与实现一致。
- AI 协作文件审查：template/AGENTS.md 88 行，未超过 120 行上限（`ai-check-bloat.sh` 显示 🟢）；new-spec、gc-memory、design 与 requirements 模板、MEMORY.md 之间没有互相矛盾；没有私有调试信息。
- 审查范围限制：mawk 和 BSD/onetrue awk 未实测，只在 gawk 的 posix/traditional 模式下做了近似验证。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000005 template/scripts/ai-gate.sh` → verification.md：result PASS / checks 1 / state dc981216…（第 2 轮重验 2026-10-23T01:10:02Z）
- `LC_ALL=C.UTF-8 bash scripts/harness-selftest.sh` → 213 项断言，失败 0 项（含 3 条新 G2 用例）
- `bash scripts/ai-check-bloat.sh` → Context Budget OK
- 沙箱 awk 用例矩阵（2 种 locale × 3 种 gawk 模式 × 18 行）→ 6 组结果一致，符合上文预期

knowledge_feedback: .knowledge/INDEX.md K-0001 摘要含 0x08 控制字符，与卡片原文不一致

## 第 2 轮复审（增量）
- 上一轮待办逐项核对：
  - 建议 1 ✅：`.knowledge/INDEX.md:5` 已改为字面 `\b`；`grep -cP '\x08'` 在 INDEX.md 与 design.md 中均为 0；design.md:92 已恢复为 `\b`；`ai-knowledge.sh check` 一致。
  - 建议 2 ✅：design.md §2 边界样本已改为「合理性校验应通过」，§5 第 3 条已改为「」『』与反引号都豁免、未闭合的不豁免，与 ai-gate.sh strip 和第 1 轮实测一致。
  - 建议 3 ✅：`template/scripts/ai-gate.sh:217` 提示已补『』；改动只涉及文案，`bash -n` 通过；自检断言的子串「含糊词：尽量」仍是前缀，不受影响。
  - 建议 4~6：按「改善即批准」记入 `tasks.md` §3「发现但不碰」，本轮不要求修改。
- 修复增量审查：无新增行为、无范围外改动；`.violations` 记录了 reset g4，g4 已用新状态指纹重新 pass；verification.md state 已更新为 dc981216…，与本报告「审查状态」一致。
- 第 2 轮结论：关键问题 0，判定通过。
