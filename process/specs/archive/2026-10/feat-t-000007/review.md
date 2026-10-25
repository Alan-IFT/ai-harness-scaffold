# 代码审查报告 (Code Review): feat-t-000007

- **审查者**：独立 subagent（Claude Code / Opus 5.5，新上下文；我没写过这段代码，只依据下面产物判断）
- **未参与实现**：是
- **审查时间**：2026-10-22
- **审查范围**：`git diff d7a07b4...HEAD`（第 2 轮增量 `git show 0c7aed8`；工作区仅 .gates/verification.md 待提交）；design.md §4 文件清单：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`、`docs/architecture/modules/template-mechanism.md`
- **CR 轮次**：2 / 4
- 审查状态：5360c59245f592d8615d343cbf466b2400d6b078e186e9949fdfa48f27b7f4b7

## 结论（第 2 轮）
- 关键问题（必须修）：0
- 改进建议（非阻塞）：0（第 1 轮 4 条全部关闭）
- 判定：通过

## 第 2 轮复审：上一轮待办逐项核对
1. 已关闭。etc 恢复右边界（`ai-gate.sh:216-217`）。沙箱实测 `config.etc.json`、`etc.d`、`etc.1` 放行；`Etc.`、`etc.,`、`etc.。`、`etc...`、`(etc.)` 仍拦，无 locale、C、C.UTF-8 下结论一致。`etc.1` 改为放行的取舍已写进 design §5.3。
2. 已关闭。`harness-selftest.sh:282` 改用 `ASAP_mode`、`my_etc.`、`config.etc.json`，旧脚本和第 1 轮脚本都会在这条用例上失败。
3. 已关闭。`harness-selftest.sh:289-291` 新增「大概」反向用例，断言命中「大概」且不出改写示例。
4. 已关闭。`template-mechanism.md:11` 补写了 etc 须带句点、句点后同样判词边界。
- knowledge_feedback 已处理：K-0001 statement 的词边界写法已更新为 `[^a-z0-9_]`，与代码一致，不再降权。
- 增量其余部分：`.violations` 记录了按流程回退 g4 及之后的门，g4 已重新通过；没有越出 Spec 范围的改动。
- 第 2 轮验证：沙箱自检在无 locale 和 `LC_ALL=C` 下都是 229 项断言、失败 0 项。用 d7a07b4 的 ai-gate.sh 跑新自检，失败 3 项。

## 结论（第 1 轮）
- 关键问题（必须修）：0
- 改进建议（非阻塞）：4
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无

## 改进建议（非阻塞，"改善即批准"）
1. `template/scripts/ai-gate.sh:217`：`etc[.]` 去掉了右边界后，`config.etc.json` 这类点号分隔的文件名片段**新增**被拦（旧脚本放行，沙箱实测），和 design §3.3「只减少标识符误拦，不新增拦截」的说法不一致。这和 design §5.3「`etc.1` 仍拦」是同一个取舍，影响面小，加反引号就能绕开。建议在 design §3.3 / 活文档里写明这个例外，或者把右边界改成 `etc[.]([^a-z0-9_.]|$)`，但要接受 `etc.1` 不再被拦。
2. `template/scripts/harness-selftest.sh:282`：`etc2` 在新旧脚本下都不会被拦（旧规则本来就要求有句点），所以这一半用例区分不出新旧行为。建议换成 `my_etc.`，旧脚本拦、新脚本放行，已实测。
3. `template/scripts/harness-selftest.sh:286-288`：缺少反向用例「`大概` 单独出现时不输出改写示例」。现在由 `ai-gate.sh:224` 的 case 精确匹配保证，沙箱实测也成立，但自检里没有对应断言。
4. `docs/architecture/modules/template-mechanism.md:11`：「按词边界匹配（字母、数字、下划线算词内字符）」对 etc 不完全准确。etc 必须带句点才算命中，句点右侧不设边界。建议补半句说明。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 Bash 门禁脚本，无用户身份 |
| 鉴权中间件 | 不适用 | 无网络入口 |
| SQL 参数化 | 不适用 | 无数据库 |
| 无敏感信息硬编码 | ✅ | diff 只改词表、正则和提示文案 |
| 入参边界校验 | ✅ | awk 出错按未通过处理（`ai-gate.sh:220` 保留） |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01/AC-02 成立，独立的 `ASAP`、`asap,`、`(asap)`、`asap。`、`（asap）`、`标记asap处理`、行首、行尾、`ASAP-mode`、`Etc.` 都被拒；ERR-01/AC-01 成立，`ASAP_mode`、`mode_asap`、`asap2`、`2asap`、`my_etc.` 都放行；REQ-02/AC-03 成立，`大概率成功` 和单独的 `大概率` 都报「含糊词：大概率」并附改写示例（`ai-gate.sh:210,224`），`大概成功` 只报「大概」、不附示例，`尽快 大概率` 按词表顺序报「尽快」；§2.3「继续拦截」得到保留，`ai-gate.sh:207` 的放行复合词仍只有「合理性|及时性」，「大概率」没有被放行；AC-04 成立，30 条用例在无 locale、`LC_ALL=C`、`LC_ALL=C.UTF-8` 下结论逐条一致，沙箱自检 228 项断言、失败 0 项；没有发现超出需求范围的行为，例外见建议 1。
- 知识检索：采用 K-0001（locale 无关写法）。新增的 `[^a-z0-9_]` 只含 ASCII，符合该卡要求，三种 locale 实测一致。活文档 `template-mechanism.md` 已同步，偏差见建议 4。
- AI 协作文件审查：本次 diff 无 AGENTS.md、Skill 或知识卡改动；模板门禁脚本与自检已审，见上文。
- 审查范围限制：只在本机 GNU Awk 5.4.1 上实测，没有覆盖 mawk 和 BSD awk。新正则只用 ERE 基本语法，理论上可移植。

## 验证证据（只放命令与结果摘要，不贴全文）
- `verification.md` 记录：result PASS / checks 1 / state 58f6d5e7…cec1
- 沙箱用新的 `harness-selftest.sh` 跑新的 `ai-gate.sh`：228 项断言，失败 0 项
- 沙箱用新的 `harness-selftest.sh` 跑 `git show d7a07b4:template/scripts/ai-gate.sh`：失败 3 项，即「不拦标识符里的英文片段」「报出完整的大概率」「给出改写示例」。新用例能区分新旧行为，「仍拦独立 ASAP」是回归守护
- 沙箱 30 条边界用例：新脚本在三种 locale 下输出一致；与旧脚本相比，只有标识符片段改为放行、「大概率」改报完整词，以及建议 1 的 `config.etc.json` 新增被拦

第 1 轮 knowledge_feedback（第 2 轮已处理）：K-0001 statement 中词边界写法 `(^|[^a-z])词([^a-z]|$)` 已被本 Spec 改为 `[^a-z0-9_]`（标识符片段不算命中），复核时更新。
