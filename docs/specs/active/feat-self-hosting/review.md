# 代码审查报告 (Code Review): feat-self-hosting

- **审查者**：Codex 独立 agent `/root/g6_review`
- **未参与实现**：是
- **审查时间**：2026-10-20
- **审查范围**：requirements.md AC-01~05、design.md §2/§4、当前 `git diff`、根目录自用入口和共享脚本全文、两项 verification.md；只依据仓库产物。
- **CR 轮次**：3 / 4

## 结论

- 关键问题（必须修）：0
- 改进建议（非阻塞）：3
- 判定：通过（代码审查与 G4 验证已完成；G6 实际验收待执行）

## 需求、架构、正确性、性能与测试证据

| AC | 审查结论与证据 |
| :-- | :-- |
| AC-01 Git 状态 | 当前 `git status --short` 显示 `main` 工作树仍有改动；现有材料缺接入前逐文件快照，不能独立证明原有改动逐项未丢，见改进建议 1。 |
| AC-02 单一机制 | 根目录 `scripts/ai-gate.sh`、`scripts/ai-resume.sh` 全文仅转发至同名 `template/scripts/`；其余入口应继续遵守同一模式。 |
| AC-03 自用流程 | `template/scripts/ai-new-spec.sh:27-48` 选择本仓库模板目录；`ai-verify.sh:14-68,193-216` 将真实检查摘要写入指定 Spec。G6/G7 实际推进尚未发生。 |
| AC-04 跨 IDE 接力 | 根目录 `AGENTS.md`、当前 `tasks.md`、`verification.md` 与 Git 保留接力状态；`template/scripts/ai-resume.sh:30-55` 读取指定 Spec 快照。 |
| AC-05 分工验收 | `template/scripts/ai-gate.sh:275-323` 将 Agent 核验与②③人工决定分开，要求全部 AC 通过与决定来源；实际 `acceptance.md` 仍为旧空模板，须在 G6 由 Agent 据真实结果更新。 |

- 架构边界：根目录脚本为薄入口，共享机制在 `template/scripts/`。当前 `bin/ai-harness` diff 是此前 retrofit 工作，非本轮 G6 代码，应独立归属和提交。
- 正确性：`template/scripts/ai-state-id.sh:19-36` 的指纹不含 HEAD，索引和工作树代码状态从暂存到提交保持稳定；已在索引、未暂存 diff、未跟踪路径三处排除流程记录 `docs/metrics.md`。`harness-selftest.sh:397-426` 覆盖代码变化、提交稳定性与度量排除。提交后 G6 的旧闭环阻塞已解除。
- 性能与资源：所审命令为短时本地文件与 Git 操作，无网络或数据库；指纹处理量随工作树大小增长。
- 测试质量：`harness-selftest.sh:369-373` 真实运行 `ai-verify.sh` 并核对 G4；`343-356` 覆盖多 AC 缺项与①自动、②人工决定；最新本地验证日志记录完整自检 91/91 通过。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

无。

## 改进建议（非阻塞）

1. `requirements.md:30` 要求 Git 前后对照；目前缺接入前 HEAD/分支/status 快照。保持“无法独立证实”，勿补造历史证据；未来接入时先保存只读摸底摘要。
2. 旧活跃 Spec 的 `reports/verify-*.log` 和旧验收格式在新 `ai-gate.sh:219-232,286-323` 下不能直接推进；给用户明确的迁移步骤和兼容性用例。
3. `design.md:33` 将 `bin/ai-harness` 标为只读，但当前工作树有其既存 retrofit diff；后续单独提交时保留来源说明。

## 安全六项核对

| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 根目录脚本为本地命令，无登录态。 |
| 鉴权中间件 | 不适用 | 无 HTTP 路由。 |
| SQL 参数化 | 不适用 | 无数据库访问。 |
| 无硬编码敏感信息 | ✅ | 本轮所审自用入口、脚本和配置 diff 未见凭证常量。 |
| 入参边界校验 | ✅ | `ai-new-spec.sh:8-28`、`ai-verify.sh:14-38` 限制名称与路径。 |
| 资源归属与 404/403 | 不适用 | 本地单工作区，无多租户 HTTP 资源。 |

## 验证证据

- `verification.md`：`feat-self-hosting` PASS / checks 1 / target `template/scripts/ai-new-spec.sh` / 2026-10-20T15:04:47Z；本地 `reports/verify-20261020-080447-37573.log` 首尾记录 `ai-verify.sh`、PASS、87s、自检 91 项断言且失败 0 项。`.gates` 已记录 G4 于 15:05:08Z 通过。
- `harness/verify.conf` 的自定义检查是目标 Bash 语法、`harness-selftest.sh` 与 `git diff --check`；审查环境无法独立启动 Bash，故结果依据仓库验证摘要与本地日志，不声称本审查者复跑。`git diff --check` 与 `git diff --cached --check` 本审查者执行均无输出。
- 静态证据来自 `git status --short`、`git diff`、所列文件全文及行号。本轮只写两份 `review.md`；G6 仍须据真实结果更新两份 `acceptance.md`。
