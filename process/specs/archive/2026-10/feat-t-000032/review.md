# 代码审查报告 (Code Review): feat-t-000032

- **审查者**：独立 G5 subagent（Claude Code / Opus 5.5，新上下文、只读；维护者指定「本会话 subagent」）
- **未参与实现**：是
- **审查时间**：2026-10-24
- **审查范围**：`git diff 745e8d4...HEAD`（G3 基准至 dba461d），按 `code-review.md` 七维审查
- **CR 轮次**：1 / 4
- 审查状态：0421a6a095d97897dd3f24903d0099f3f37e5d78e5bae01788af66f89e97bfba

我没写过这段代码，只依据需求、设计、diff、测试输出与 ADR-0002 判断。

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：4
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无。

## 改进建议（非阻塞，"改善即批准"）
1. `verdict_ok` 中「通过」之后只接受半角空格，不接受 Tab。这只会更严格，不会误放。
2. `tests/cli-upgrade.sh` 的 `ret-legacy` 用例（manifest 缺失）中，「不删除」本来就是必然结果，这条断言偏弱。
3. 根目录 `harness/redlines.conf` 仍有两个旧键。`self-hosting.md` 已注明待维护者清理，不在 AC-01 扫描范围内。
4. AC-05 要求把正式验证耗时记录在验收中，需在 acceptance.md 补上。

## 重点核对
- **`ai-gate.sh`**：
  - **G1**：保留四项必答、象限、④ 人工接管与分级依据，没有悬空变量。
  - **G3**：保留边界样本，只删除了委托分支。
  - **G4**：只做验证摘要与指纹比对。
  - **G5**：`.gates` 的 g3 行恒为 5 列，第 5 列为 `none`，审查状态绑定照常生效，旧的 5 列哈希行也兼容。
  - **共享函数**：`sha()` 保留，`hash_text` 已无调用者，已删除。
  - **`verdict_ok`**：「通过率」「通过了」「不通过」「`通过`」都被拒绝；标点、空白与行尾放行。判定按字节前缀进行，LC_ALL=C 与默认 locale 结果一致。
  - **②③ 的 G6**：仍要求「人工决定：通过」，并给出旧格式提示。
  - **`--by`**：会报「未知参数」。
- **`bin/ai-harness upgrade`**（约 426-438 行、485-499 行）：
  - **处理范围**：只处理同时满足以下条件的记录：3 列、两个 64 位十六进制哈希、`managed_file` 命中、模板中不存在。
  - **路径预检**：`safe_path` 在任何写入和 `mktemp` 之前执行。
  - **删除条件**：`old_source=old_local`，当前哈希与之一致，且是普通文件。
  - **保留与冲突**：其他情况保留文件、计入冲突并以非零退出；这些记录不写回 manifest，下次不再报告。
  - **dry-run**：删除操作被跳过，前后快照一致。
  - **已知取舍**：如果 manifest 被伪造成「托管路径 + 哈希一致」，会删掉内容一致的那份文件。这是 manifest 可信边界内的设计行为。
- **`tests/cli-upgrade.sh`**：在 `set -euo pipefail` 下，新增断言都是独立命令或 `if … exit 1`，确实生效。覆盖 clean、edited、accepted、重复运行、dry-run、legacy、forged 七种情形。
- **`harness-selftest.sh`**：保留项断言仍在；G6 样本覆盖设计所列，并补了旧格式提示、预授权被拒、指名 AC-02 报错。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 无用户身份处理 |
| 鉴权中间件 | 不适用 | 无服务入口 |
| SQL 参数化 | 不适用 | 无数据库 |
| 无敏感信息硬编码 | ✅ | diff 中无密钥、token 或密码 |
| 入参边界校验 | ✅ | manifest 记录格式、哈希长度与字符集、`managed_file` 白名单（`bin/ai-harness:426-431`）；`safe_path` 预检（`:435-438`） |
| 资源归属校验 | ✅ | 只删除哈希一致的普通托管文件，其余保留并报告（`bin/ai-harness:485-499`）；dry-run 只读 |

## 需求追溯
- 需求追溯核对：AC-01~AC-06 逐条满足（AC-05 耗时待 acceptance 记录），证据如下：
  - AC-01：关键字 grep 在 `template`、`bin`、`scripts`、`README.md` 中为空。
  - AC-02：`harness-selftest.sh:265`；`:404-428` 的样本在两种 locale 下各跑 11 例。
  - AC-03：保留项断言均在，215 项全绿。
  - AC-04：`tests/cli-upgrade.sh` 覆盖 6 种情形以上。
  - AC-05：行数 636 < 821、917 < 1161，耗时待在 acceptance 中记录。
  - AC-06：文档 grep 干净，`code-review.md` 已新增两项检查。
- AI 协作文件审查：`template/AGENTS.md`、`archive-spec.md`、`gc-memory.md`、`new-spec.md`、`retrofit-legacy.md`、`code-review.md`、`template/MEMORY.md` 与代码一致，没有矛盾、私有调试信息或过时事实。`retrofit-legacy.md:21` 对退役文件与旧 acceptance 格式的迁移提示准确；`.knowledge/` 在下游属于项目状态，不自动删除，文档已说明。
- 审查范围限制：未在真实旧项目上跑 upgrade 等三项，见下：
  - 没有在真实旧项目上跑 upgrade，只依据回归用例。
  - Spec 文档没有逐字审校。
  - K1~K16 按自检断言计数核对，没有逐条对照 ADR 原文。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-resume.sh review feat-t-000032 745e8d4`：正常
- `bash template/scripts/harness-selftest.sh`：215 项断言，失败 0 项（约 4 分 26 秒）
- `bash tests/cli-upgrade.sh`：`cli-upgrade: PASS`（约 2 分 20 秒）
- `bash scripts/ai-gate.sh check feat-t-000032 g4`：通过

knowledge_feedback: 无
