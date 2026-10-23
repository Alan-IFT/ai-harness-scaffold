# 代码审查报告 (Code Review): feat-t-000009

> 我没写过这段代码，只依据下面的产物判断。

- **审查者**：Claude Code G5 独立审查 subagent（Opus 5.5，新上下文，只读）
- **未参与实现**：是
- **审查时间**：2026-10-23
- **审查范围**：`git diff 8471ce8...HEAD`（含第 2 轮修复提交 431f6ba；工作区只有 `.gates` 与 `verification.md` 的门禁与验证记录变更）；design.md §4 文件清单：`template/scripts/harness-selftest.sh`、`docs/architecture/modules/template-mechanism.md`
- **CR 轮次**：2 / 4
- 审查状态：ddba6bc635204aff9b457add632f6c046880723ab5083a2380c392d48d6fd518

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：2（第 1 轮建议 1、2 仍为待办；建议 3、4 已处理）
- 判定：通过（第 2 轮；第 1 轮判定为需修复，见下）

### 第 2 轮复审结论（逐项核对上一轮待办）
1. 第 1 轮关键问题 1：已修复。`template-mechanism.md:13` 写明「feat-t-000009 最终版自检 235 项」，gawk 版本改为 5.4.1（与本机 `awk --version` 一致），并说明 macOS 未实测；三种 awk 下的 235 项结果由实现方提交（431f6ba）。我独立复核：WSL mawk 1.3.4 20260129 下最终版 t-vague 子集 6/6 通过；onetrue-awk 整套 235 项没有复测，采信实现方的记录（见审查范围限制）。
2. 建议 3（说明行残留）：已处理。`harness-selftest.sh:325` 在用例跑完后删掉该行；复跑 M1（去掉 AC 行过滤）时只有 :324 一项报出，其余用例不再连带失败。
3. 建议 4（项数与 macOS 表述）：已处理。活文档改为「4 类行为，另有一项正常 awk 对照」，并说明 macOS 未实测。
4. 建议 1：实现方计划归档后收入任务池；建议 2：仅记录，不需要处理。
5. 修复增量的其他检查：`.violations` 记录了 G5 第 1 轮回退 g4，`.gates` 在重新验证后重新写入 g4，流程合规；没有改动 ai-gate.sh，M4 变异复跑仍会报出。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
第 2 轮：无。以下是第 1 轮的问题，已修复。
1. （第 1 轮，已修复）`docs/architecture/modules/template-mechanism.md:13`：活文档写 mawk 1.3.4 与 onetrue-awk 20250116「下自检全部通过」，紧接着列出本 Spec 新增的 G2 覆盖项，读者会认为新用例也已在这两种 awk 下跑过。实际上两次跨 awk 运行都在新增用例之前，跑的是 230 项版本；当前自检是 235 项（tasks.md §4）。AC-03 要求「mawk 与 onetrue-awk 下自检 0 项未过」，但交付版本缺少 onetrue-awk 的证据。我在 WSL 用 mawk 1.3.4 20260129 只跑了 t-vague 子集（包括新增 5 项），6/6 通过；onetrue-awk 没有复测（本机没有现成镜像）。
   - 为什么阻塞：AC-03 的证据和交付版本对不上；活文档把没核实的结论写成了事实。
   - **修复指引：期望行为**：在 mawk 与 onetrue-awk 下各跑一遍当前 235 项自检，把项数和结果写进第 13 行；如果做不到，第 13 行要写明「230 项，早于 feat-t-000009 新增用例」，并按需求更新流程修订 AC-03。顺带改正 gawk 版本：本机 `awk --version` 输出是 GNU Awk 5.4.1，不是 5.3。

## 改进建议（非阻塞，"改善即批准"）
1. `template/scripts/harness-selftest.sh:331`：包装 awk 的真实路径用 printf 写进双引号。路径含空格时正常（已用含空格的目录实测）；但路径里有 `"`、`$`、反引号或 `\` 会出错。另外，如果 awk 是 shell 函数，`command -v` 返回 `awk`，包装会递归调用自己。现实中 awk 的路径基本不会这样，可改用 `printf '%s'` 单独写一行变量赋值，或者记成已知限制。
2. `harness-selftest.sh:331`：`case "$*"` 匹配的是所有参数，不只是程序文本，`-v x="function strip"` 这类数据参数也会命中（已实测 rc=2）。目前 ai-gate.sh 里只有 ck_g2（`ai-gate.sh:198`）带这个字符串，不会误伤；以后有人复制这个特征时，要知道它不分程序和数据。
3. `harness-selftest.sh:323`：说明行插入后一直保留到 t-vague 用完（:335）。正常情况下无害（这行没有 `AC-xx`），但如果 AC 行过滤失效，『』用例和对照用例（:326、:335）也会一起失败，错误输出会更嘈杂。不影响用例能否发现问题。
4. 需求和设计写的是「4 项」，实际新增 5 次断言（第 5 次是 :335 的「awk 正常时通过」对照）。对照断言合理，建议把文档里的数量对齐。另外，`template-mechanism.md:13` 写的「即 BSD / macOS 系 awk」容易让人以为整套自检已在 macOS 跑过；但自检本身用了 GNU `sed -i`，在 macOS 上跑不起来，建议注明这次只验证了 awk 的行为。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | diff 只改自检 shell 和文档 |
| 鉴权中间件 | 不适用 | 没有路由 |
| SQL 参数化 | 不适用 | 没有查询 |
| 无敏感信息硬编码 | ✅ | `harness-selftest.sh:323-335` 只用沙箱 `$TMP` 路径 |
| 入参边界校验 | 不适用 | 没有新增入口 |
| 资源归属校验 | 不适用 | 没有资源访问 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01 → `harness-selftest.sh:323-324`；REQ-02 → `:325-326`；ERR-01 → `:327-328`；ERR-02 → `:329-334`，对照断言在 :335。AC-02 由我在沙箱里独立复核：把 ck_g2 的四处逻辑分别改坏，对应用例都会报出。具体是：去掉 `/AC-[0-9][0-9]/` 过滤，:324 报出；去掉『』剥离，:326 报出；未闭合时改成剥离到行尾或删掉 `break`（LC_ALL=C 下），:328 都会报出；去掉 `|| { say …检查执行失败… }`，:334 报出。基线 6/6 通过。AC-03 见关键问题 1。AC-04：verification.md 的 result 是 PASS，state 与本报告一致。没有发现超出需求的行为，门禁脚本没有改动（diff 里没有 ai-gate.sh）。
- 知识检索：采用 K-0001（awk 出错须按未通过处理；与 locale 无关）。ERR-02 用例对应这张卡；新增用例都用 `LC_ALL=C` 运行，符合卡片要求。活文档 `template-mechanism.md` 是本模块的主文档，问题见上文。
- AI 协作文件审查：本次 diff 改了模板门禁自检 `template/scripts/harness-selftest.sh` 和模块活文档，都已审查。没有改 AGENTS.md、Skill 或知识卡。
- 审查范围限制：没有在 onetrue-awk 下复测（本机没有现成镜像），这部分 235 项结果采信实现方的记录；审查者没有完整重跑 235 项自检，只在 gawk 5.4.1 和 mawk 1.3.4 下跑了最终版 t-vague 子集，均为 6/6 通过。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000009 template/scripts/harness-selftest.sh` → verification.md：result PASS / checks 1 / state ddba6bc6…d518（第 2 轮）
- 沙箱变异：从 template 复制，用 perl 改坏 ck_g2，再用自检第 1-262 行加 t-vague 段 321-335 组成迷你脚本运行。基线 6/0；M1 有 3 项失败，M2、M3a、M3b、M4 各有 1 项失败，失败的都是对应用例。
- WSL mawk 1.3.4 20260129，不设 locale，PATH 前置包装：t-vague 子集 6/6 通过。

knowledge_feedback: 第 1 轮指出 template-mechanism.md:13 的跨 awk 结论与 gawk 版本有误，第 2 轮已更正；无新反馈
