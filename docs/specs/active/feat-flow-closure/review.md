# 代码审查报告 (Code Review): feat-flow-closure

- **审查者**：Codex 独立 agent `/root/g6_review`
- **未参与实现**：是
- **审查时间**：2026-10-20
- **审查范围**：当前 `git diff` 与变更文件全文、requirements.md AC-01~07、design.md §2/§4、两份 verification.md；只依据仓库产物和契约。
- **CR 轮次**：2 / 4

## 结论

- 关键问题（必须修）：0
- 改进建议（非阻塞）：3
- 判定：通过（代码审查与 G4 验证已完成；G6 实际验收待执行）

## 需求、架构、正确性、性能与测试证据

| AC | 审查结论与证据 |
| :-- | :-- |
| AC-01 | `template/docs/INTAKE.md` 与 requirements 模板保存原话、决定和 Spec 链接；`template/scripts/ai-gate.sh:122` 拒绝缺原话。 |
| AC-02 | `ai-gate.sh:168-190,317-320` 处理①单步、②③前置决策和④停开发；`harness-selftest.sh:276-306` 有正反例。 |
| AC-03 | `ai-gate.sh:180-183` 校验间接消费者和检索依据；`harness-selftest.sh:301-306` 有缺字段反例。 |
| AC-04 | `ai-gate.sh:233-251` 拒绝注入过期或待验证知识卡；`harness-selftest.sh:491-524` 覆盖推荐、影响与拒绝路径。 |
| AC-05 | `template/docs/specs/_templates/acceptance.md:23-28` 与 `template/docs/metrics.md` 提供发布、反馈和等待时间记录。 |
| AC-06 | `template/AGENTS.md:3,18-20,54` 使用项目文档和 Git 接力；根目录 `scripts/ai-gate.sh:1-3` 只转发。 |
| AC-07 | `ai-gate.sh:275-323` 要求 Agent 核验、全部 AC 逐条通过，②③另有人的决定和来源；`harness-selftest.sh:329-356` 覆盖①、②及遗漏 AC 的正反例。两份实际 `acceptance.md` 仍待 G6 填写，不能视为验收完成。 |

- 架构边界：机制集中在 `template/scripts/`，根目录入口只转发。`bin/ai-harness` 的现存 diff 属于此前 retrofit 工作，不计入本轮 G6 实现。
- 正确性：原先 HEAD 纳入指纹导致提交后 G6 失效；现 `template/scripts/ai-state-id.sh:19-36` 以索引、未暂存补丁和未跟踪内容计算，并在三条路径排除流程记录 `docs/metrics.md`。`harness-selftest.sh:397-426` 检查代码变化使指纹变化、暂存到提交后保持稳定，以及交付度量不使指纹过期。
- 性能与资源：本地脚本无网络、数据库或常驻句柄；指纹计算随仓库文件与 diff 大小增长，符合本地增量门禁用途。
- 测试质量：`harness-selftest.sh:85-108` 的通用 fixture 手写 PASS 摘要，故不能单凭它证明真实检查；`369-373` 另有真实 `ai-verify.sh` 路径，`397-426` 覆盖 Git 时序和度量排除。最新本地验证日志确认完整自检 91/91 通过。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

无。

## 改进建议（非阻塞）

1. `ai-gate.sh:219-232,286-323` 对旧活跃 Spec 的旧报告和验收格式不兼容；为升级者写出迁移到 `verification.md` 与新 `acceptance.md` 的步骤，并增一项旧 Spec 用例。
2. `ai-gate.sh:303-309` 机械检查每个 AC 有“通过”行，但无法证明所写证据真实；独立审查与 G6 实际核验应核对命令、环境和结果，不把文本校验当身份或事实认证。
3. `design.md` §4 把 `bin/ai-harness` 列为只读，而当前工作树有既存 retrofit diff；后续单独提交时保留其独立归属说明。

## 安全六项核对

| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | `ai-gate.sh:1-18` 是本地门禁，无登录态。 |
| 鉴权中间件 | 不适用 | `ai-gate.sh:317-324` 是本地命令分派，无 HTTP 路由。 |
| SQL 参数化 | 不适用 | 所审脚本仅操作文件和 Git。 |
| 无硬编码敏感信息 | ✅ | 本轮所审脚本与配置 diff 未见密钥或令牌。 |
| 入参边界校验 | ✅ | `ai-gate.sh:56-63`、`ai-verify.sh:14-38` 限制 Spec 名和目标路径。 |
| 资源归属与 404/403 | 不适用 | 本地单工作区，无多租户 HTTP 资源。 |

## 验证证据

- `verification.md`：`feat-flow-closure` PASS / checks 1 / target `template/scripts/ai-gate.sh` / 2026-10-20T15:04:46Z；本地 `reports/verify-20261020-080446-37535.log` 首尾记录 `ai-verify.sh`、PASS、86s、自检 91 项断言且失败 0 项。`.gates` 已记录 G4 于 15:05:04Z 通过。
- `harness/verify.conf` 的自定义检查是目标 Bash 语法、`harness-selftest.sh` 与 `git diff --check`；审查环境无法独立启动 Bash，故结果依据仓库验证摘要与本地日志，不声称本审查者复跑。`git diff --check` 与 `git diff --cached --check` 本审查者执行均无输出。
- 静态证据来自 `git status --short`、`git diff`、变更文件全文和上述行号。本轮只写两份 `review.md`；G6 仍须据真实结果更新两份 `acceptance.md`。
