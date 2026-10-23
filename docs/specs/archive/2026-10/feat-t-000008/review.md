# 代码审查报告 (Code Review): feat-t-000008

- **审查者**：Claude Code 独立 subagent（Opus 5.5，新上下文，只读审查）
- **未参与实现**：是
- **审查时间**：2026-10-23
- **审查范围**：第 1 轮为 `git diff 3e3b4ba...HEAD`（当时 HEAD=b18beba）；第 2 轮复审修复增量 `git diff b18beba..0ffc3dd`，完整范围仍以 3e3b4ba 为基准（`git diff` / `git diff --cached` 为空，无未跟踪文件）；design.md §4 文件清单：`template/docs/specs/_templates/requirements.md`、`template/scripts/harness-selftest.sh`，只读契约 `template/scripts/ai-gate.sh`
- **CR 轮次**：2 / 4
- 审查状态：95c084c5fa8ffd81e2f74c0ae91b53c1526e28a16005f4fb2f8f8954d502289a

声明：我没写过这段代码，只依据下面产物判断。

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：1
- 判定：通过

### 第 2 轮结论（复审 0ffc3dd）
逐项核对上一轮待办，全部关闭（沙箱用 mktemp 抽出 awk 程序单独运行，在默认 locale、C、C.UTF-8 下均输出 `OK 4`）：
- 关键 1（AC-02 例子数）：已关闭。`harness-selftest.sh` 的 END 输出 `OK <checked>`，ok_msg 显示「模板 4 个含糊词例子都在 ai-gate.sh 词表中」。
- 建议 1（子串漏报）：已关闭。只取 `split("…"` 引号内的词，建成 `vocab` 集合后精确比对。实测例子写「大概」、词表只留「大概率」时报出 `大概`；例子写 `split` 时报出 `split`。
- 建议 2（大小写）：已关闭。两侧都用 `tolower`，实测「ASAP」→ `OK 4`。
- 建议 3（awk 出错）：已关闭。命令替换后加 `|| vague_check="检查执行失败…"`，文件缺失时 gawk rc=2，进入该分支，走 ng_msg。
- 建议 4（空词表提示）：已关闭。`listed` 为 0 时报「未读到 ai-gate.sh 词表」，实测如此。
- 门禁判定：增量只改自检，没有触及 `ai-gate.sh`。
- 新增改进建议（非阻塞）：词表里的 `as_needed` 在门禁中按「as needed」匹配，自检则按字面 `as_needed` 比对。将来模板例子如果写成「as needed」会被误报，需要时再归一下划线即可。
- 判定：关键问题 0，改善即批准，通过。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
第 2 轮：无（第 1 轮的问题已在 0ffc3dd 修复，下方保留原记录）。
1. [已修复] `template/scripts/harness-selftest.sh:305` 与 AC-02 不符。AC-02 的通过条件是「自检新增检查通过并列出核对的例子数」，但通过时只输出固定文案「模板含糊词例子都在 ai-gate.sh 词表中」。awk 里已经统计了 `checked`（:298），却没有输出，所以 AC-02 的证据列（自检输出）无法给出例子数。它会阻塞，原因是 AC 的明确通过条件没有满足，G6 也无法按 AC 表逐项判通过。
   **修复指引（期望行为）**：通过时的输出带上核对数，例如 `✅ 模板含糊词例子都在 ai-gate.sh 词表中（4 个）`。做法是让 awk 在 END 中另行输出 checked（或由 shell 计数），失败分支保持不变。如果维护者认为不需要计数，就把 AC-02 的通过条件改掉并回退相应的门，不能让 AC 和实现不一致却照样放行。

## 改进建议（非阻塞，"改善即批准"）
第 1 轮的 1~4 条均已在 0ffc3dd 修复；第 2 轮仅剩上文 as_needed 一条。
1. `harness-selftest.sh:294,300` 把含 `split("` 的整行（含代码）当作词表，再做子串匹配，会漏报。沙箱实测有两种情况：其一，从词表删掉「大概」只留「大概率」，模板例子写「大概」时检查仍通过，但门禁对「大概」已不再拦截；其二，例子写成 `split`、`zh` 这类代码片段时也会通过。建议只取 `split("…"` 引号内的内容，按空格拆成词集合后做精确相等比较。当前 4 个例子不受影响。
2. `harness-selftest.sh:300` 不区分大小写。门禁把英文转小写后再匹配（ai-gate.sh:212），而这里是逐字节比对，实测模板例子写「ASAP」时会误报。建议比较前对英文例子用 `tolower`。
3. `harness-selftest.sh:293-305` 没有检查 awk 的退出码。实测 gawk 打不开文件时会 fatal、rc=2、stdout 为空，于是走 `ok_msg`，误判为通过。这与 K-0001「awk 出错须按未通过处理」不一致。沙箱中这两个文件必然存在，所以当前不会触发。建议用 `|| vague_missing="（awk 出错）"` 兜底。
4. 第一个文件为空时，`FNR == NR` 会把模板行也当作词表行读进去。实测输出「（未抽到任何例子）」并判未通过，方向正确，但提示有误导。可以改为同时检查 words 是否为空，单独报「未读到词表」。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 只改自检与模板说明，无身份入口 |
| 鉴权中间件 | 不适用 | 无路由 |
| SQL 参数化 | 不适用 | 无查询 |
| 无敏感信息硬编码 | ✅ | diff 中无密钥、token 或内网地址 |
| 入参边界校验 | 不适用 | 自检只读取沙箱里的固定路径 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01 / AC-01 通过。`template/docs/specs/_templates/requirements.md:50` 含「完整词表以 `scripts/ai-gate.sh` 的 G2 检查为准」，4 个例子「适当」「尽量」「及时」「etc.」都在，符合方案 A（requirements §4、T-000008 补充）。REQ-02 已实现（:293-305），第 1 轮缺 AC-02 的「列出例子数」，第 2 轮已补（输出 `OK 4`）。ERR-01 / AC-03 通过：沙箱在 C locale 下删「及时」输出 `及时`，删 `etc` 输出 `etc`。AC-04 依据 verification.md 的 result: PASS。字节 locale、C.UTF-8 和默认环境下的抽取结论一致（第 2 轮均为 `OK 4`）。门禁判定不变：diff 没有触及 `ai-gate.sh`。没有发现超纲行为。
- 知识检索：采用 K-0001。抽取逻辑只用 `split` / `index` / `substr` 的字面量，没有多字节字符类，符合该卡。awk 出错按未通过处理这一条未落实，见建议 3。活文档 `template-mechanism.md:11` 描述的是门禁行为，与本次改动不冲突，无需更新。
- AI 协作文件审查：模板 `requirements.md` 只多了半句说明，与脚本一致，`ai-new-spec.sh` 新建的 Spec 会带上这句。本次 diff 没有改 AGENTS.md、Skill 或知识卡。
- 审查范围限制：本机只有 GNU Awk 5.4.1，mawk / BSD awk 没有实测。`FNR == NR` 与多字节字面量作 `split` 分隔符都是 POSIX 写法，按推理可移植。未复跑全量自检，以 verification.md 为准。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000008 template/scripts/harness-selftest.sh` → 第 1 轮 PASS（state ca99c925…）；第 2 轮 verification.md 为 PASS / state 95c084c5…
- 沙箱（mktemp，抽出自检里的 awk 程序单独运行）：基线无输出；删「及时」→ `及时`；删 `etc` → `etc`；空词表文件 → `（未抽到任何例子）`；缺失文件 → gawk fatal rc=2、stdout 为空；「大概」与 `split` 漏报；「ASAP」误报。
