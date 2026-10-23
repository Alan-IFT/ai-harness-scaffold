# 代码审查报告 (Code Review): feat-t-000011

我没写过这段代码，只依据下面产物判断。

- **审查者**：独立 subagent（Claude Opus 5.5，G5 新上下文，只读）
- **未参与实现**：是
- **审查时间**：2026-10-23
- **审查范围**：`git diff d2de97e...HEAD`（第 2 轮含修复提交 4b36988）；design.md §4 文件清单：`template/scripts/ai-gate.sh`、`template/.agents/skills/retrofit-legacy.md`、`template/scripts/harness-selftest.sh`
- **CR 轮次**：2 / 4
- 审查状态：e936f9e9080840a662d1cb188cf00c03aa066ce5433dfb3e2cd26deb40f09dec

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：1（第 1 轮 3 条已全部采纳）
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无。

## 改进建议（非阻塞，"改善即批准"）
1. `template/scripts/ai-gate.sh:507`：报错写「同样重过 G3 即可」，但没有写「由人确认委托内容」。指南（`retrofit-legacy.md:21`）写了这一前提。`pass g3` 默认 `by=agent`，不强制人工（`ai-gate.sh:579-591`）。Agent 主要看报错文案，可能把这句当成机械步骤，自己重过 G3 来刷新快照。这条退路原文案「事后补写须重过 G3」本来也有，所以本次没有放宽校验。建议把文案改为「由人确认委托后重过 G3」，与指南和 `new-spec.md:37` 保持一致。
2. `template/.agents/skills/retrofit-legacy.md:21`：全角空格的例子准确。归一由 b4028d3 引入（属于 feat-t-000006，位于 feat-t-000005 归档 f0ea114 之后），包括 `delegation_fields` 的 `s/　/ /g` 和 `section_body` 的 `gsub`。文中「解析或快照算法」的概括已经覆盖其他升级情形，例如以后修改 `条件委托(决策人|来源|范围|结论)` 的匹配，或修改 `.gates` 第 5 列格式。没有提到的非升级情形：换机器后哈希工具从 sha256sum 回落到 cksum（`ai-gate.sh:70-74`），也会报同样的错。这种情况极少，可以选择补一句。
3. `template/scripts/harness-selftest.sh:511`：为了断言第二个片段，又执行了一遍同一条 `check t-delegated g6`。可以改为一次运行、两段断言，省一次门禁调用。这只涉及耗时，不影响正确性。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 Bash 门禁，无登录态 |
| 鉴权中间件 | 不适用 | 无网络入口 |
| SQL 参数化 | 不适用 | 无数据库 |
| 无敏感信息硬编码 | ✅ | diff 只改了文案，没有密钥或地址 |
| 入参边界校验 | ✅ | 入参处理未改；`ai-gate.sh` 的 diff 只有 1 行 `say` 文案 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01、REQ-02、ERR-01 与 AC-01 至 AC-04 全部有落点和证据，无遗漏、无超纲。逐项如下：
  - REQ-01 / AC-01：`ai-gate.sh:507` 的报错保留了原句，并追加升级提示。自检 `harness-selftest.sh:511` 断言输出含「刚升级过脚手架」。旧文案没有这个片段，所以断言能区分新旧文案。本地日志第 98-99 行两条都显示 ✅。
  - ERR-01 / AC-02：`git diff d2de97e...HEAD -- template/scripts/ai-gate.sh` 只有 1 行增、1 行删，改的是 `say` 字符串。第 500-506 行的 `delegation_fields`、`validate_delegation`、`recorded_delegation` 比对与 `hash_text`，以及 `cmd_pass` 的 G3 快照写入（第 608-611 行）都没有改动，也没有新增放行路径。拒绝分支仍然 `return 1`。原用例「G6 拒绝 G3 后补写的委托」照旧通过。
  - REQ-02 / AC-03：`retrofit-legacy.md:21` 写明了情形（已过 G3 的在途 Spec）、原因（解析或快照算法变化，以全角空格归一为例）、处理（由人确认后重过 G3），以及「门禁不会因升级而放宽」。
  - AC-04：verification.md 显示 result PASS；本地日志中模板自检 PASS，CLI 回归 PASS。
  - 超纲：没有发现。Non-Goals（双快照兼容、改哈希）没有实现。
- 语义一致性：新文案先写「事后补写须重过 G3」，再在括号里说明升级是另一种原因，处理方式「同样」是重过 G3。它没有暗示升级后可以跳过校验，与原意一致。措辞建议见改进建议 1。
- 知识检索：`ai-knowledge.sh suggest` 的候选只有 K-0001（locale 匹配写法）。新断言沿用了已有的中文片段 grep 方式，没有引入 locale 问题，因此排除这张卡。`docs/architecture/modules/guidance.md`、`template-mechanism.md` 都没有引用这条报错文案，无需更新。
- AI 协作文件审查：本次改动了受管理指南 `template/.agents/skills/retrofit-legacy.md`，内容准确，与 `new-spec.md:37` 的「事后修改须重过 G3」一致，没有私有调试信息。`template/AGENTS.md` 未改。
- 审查范围限制：没有重跑全量自检，采信本地 `reports/verify-20261023-013205-568.log` 与 verification.md。没有在真实的旧版安装上做升级复现。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000011 template/scripts/ai-gate.sh` → result PASS / checks 1 / state 13a73787…e317
- 本地日志：「✅ G6 拒绝 G3 后补写的委托」「✅ G6 快照不一致时提示升级后重过 G3」；模板自检 PASS (211s)；CLI 回归 PASS
- `git log -S'gsub("　", " ")' -- template/scripts/ai-gate.sh` → 只有 b4028d3（feat-t-000006）

## 第 2 轮复审（增量：`git show 4b36988`）
- 上一轮建议 1（报错写明须由人确认委托）：已采纳。`ai-gate.sh:507` 新增「须由人确认委托内容后再重过 G3，Agent 不得自行重做授权」，与 `retrofit-legacy.md:21` 一致。
- 上一轮建议 2（cksum 回落情形）：已采纳。`ai-gate.sh:507` 补了「换了哈希工具」，`retrofit-legacy.md:21` 写明缺少 sha256sum / shasum 时回落为 cksum，内容与 `ai-gate.sh:70-74` 一致。
- 上一轮建议 3（只调用一次门禁）：已采纳。`harness-selftest.sh:511-513` 只调用一次 `check t-delegated g6`，对同一份输出断言三点：非零退出、「授权快照不一致」、「刚升级过脚手架」及「须由人确认委托内容」。旧文案不含后两段，断言能区分新旧文案。
- ai-gate.sh 范围：`git diff d2de97e...HEAD -- template/scripts/ai-gate.sh` 只有 1 增 1 删，都在第 507 行的 `say` 字符串内。第 500-506 行的比对、`hash_text`，以及第 608-611 行的 G3 快照写入都没有改动，没有新增放行路径。
- 门记录：`.violations` 记录了第 1 轮后回退 g4 的原因；g4 已重新通过（工作区 `.gates`），与修复后重新验证的时序一致。
- 新增改进建议（非阻塞）：`harness-selftest.sh:512-513` 调用 `ng_msg` 时没有传第二个参数 `$deleg_out`，断言失败时不会打印报错片段，诊断不如原来的 `expect_fail`。建议补上该参数。
- 验证证据：本地 `reports/verify-20261023-014401-1916.log` 显示 238 项断言、失败 0 项；第 98-99 行两条委托断言均为 ✅；模板自检 PASS，CLI 回归 PASS。verification.md 中 state 为 e936f9e9…f09dec。
- 第 2 轮判定：关键问题 0 个，判定通过。
