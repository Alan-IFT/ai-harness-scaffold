# 代码审查报告 (Code Review): feat-t-000010

- **审查者**：独立 G5 审查 subagent（Claude Opus 5.5，新上下文，只读）
- **未参与实现**：是
- **审查时间**：2026-10-23
- **审查范围**：`git diff 7de1640...HEAD`（`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh` 与本 Spec 文档）；工作区与暂存区干净、无未跟踪文件；对照 design.md §4 文件清单一致
- **CR 轮次**：1 / 4
- 审查状态：b49bb88fb762c233ddf811664fd9a6ef21ed8fe741671aae26ab6e2a51e09c85

我没写过这段代码，只依据下面产物判断。

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：3
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无

## 改进建议（非阻塞，"改善即批准"）
1. `template/scripts/harness-selftest.sh:937`：add 用例放在「收集第一条需求 T-000001」之前，旧行为下空任务占用 T-000001，后续用例连锁失败、噪声大。可在其后追加 `next` 仍为「暂无待办」的断言，或把该用例移到编号断言之后，使回归时只报出本项。
2. 缺少 REQ-01 在 `LC_ALL=C` 下的正向用例：如 `env LC_ALL=C ... add "　有文字　"` 应成功。沙箱实测新函数在 C 下对 `　a　`、`　中` 判非空（正确），但自检未固化。
3. 其他 Unicode 空白（U+00A0、U+2003）仍随 locale 分歧：沙箱实测 C 下判非空、C.UTF-8 下判空。超出本需求（只针对全角空格，K-0001 同口径），可作为后续任务记录。另 design.md §4 写调用点第 117、144 行，实际因新增注释为 `ai-task-pool.sh:118`、`:145`，仅文档偏差。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 CLI 脚本，无身份概念 |
| 鉴权中间件 | 不适用 | 无网络入口 |
| SQL 参数化 | 不适用 | 无数据库 |
| 无敏感信息硬编码 | ✅ | diff 仅函数体与两行用例 |
| 入参边界校验 | ✅ | `ai-task-pool.sh:28` 收紧空白判断，`:118`、`:145` 拒绝 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：ERR-01/AC-01 → `ai-task-pool.sh:28` + `harness-selftest.sh:937,949`；沙箱 `LC_ALL=C` 下 add `　　` 与 update `　 　` 均报「不能为空」rc=1。AC-02 → 沙箱把 nonblank 换回旧版，两条命令均 rc=0（收录 T-000001、追加成功），expect_fail 各自独立报出；连锁失败源于空任务占号（后续 ID 顺延），解释成立，且不掩盖新用例有效性（两项判定只看自身退出码）。REQ-01 → 沙箱 add `有　文字` 成功。一致性：C、C.UTF-8、en_US.UTF-8 与无 locale 下，纯全角、全角+tab、全角+换行、全角+半角均判空，含文字均判非空，结论一致；E3 80 80 是 UTF-8 完整前导序列，字节 locale 下不会误匹配其他字符的片段。无超纲行为，Non-Goals 未触碰。
- 知识检索：K-0001（全角空格先归一、不强制 LC_ALL、自检用显式 `LC_ALL=C` 复跑）采用；实现与 `ai-gate.sh:101-102` 的归一做法同义（参数替换 vs sed），符合卡片。
- AI 协作文件审查：本次 diff 改动模板门禁自检 `harness-selftest.sh` 两行，用例描述与断言清晰，无私有调试信息；未改 AGENTS.md / Skill / 知识卡。
- 审查范围限制：未在 macOS bash 3.2 上实测；`${var//pat/rep}` 自 bash 2.0 起可用、`[[ =~ ]]` 本次未改，判断为兼容但无实机证据。未跑完整自检，依据 verification.md 与 tasks.md 记录（237/237）。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-verify.sh --spec feat-t-000010 template/scripts/ai-task-pool.sh` → verification.md：result PASS / checks 1 / state b49bb88f…9c85
- 沙箱函数对比（C / C.UTF-8 / en_US.UTF-8 / 无 locale，14 种输入）→ 新函数四种 locale 结论一致；旧函数在 C 下对纯全角输入判非空
- 沙箱任务池（新/旧 nonblank）→ 新：两项拒绝；旧：收录 T-000001 并追加 T-000002
