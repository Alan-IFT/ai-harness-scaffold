# 代码审查报告 (Code Review): feat-task-pool

- **审查者**：独立 Codex 子 Agent（independent_review）
- **未参与实现**：是
- **审查时间**：2026-10-22
- **审查范围**：`git diff 49c2fc6...87aee8d`，含 `design.md` §4 的任务池、CLI、测试、模板与指南文件；另核对未提交、暂存和未跟踪文件
- **CR 轮次**：4 / 4
- 审查状态：cccd18d396e4159517dba3a55105a69f6392d36a26ce86591639c64dd1f7f65e

## 结论

- 关键问题（必须修）：0
- 改进建议（非阻塞）：2
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

无。本轮首审发现的升级目标父链接、Windows 盘符/反斜杠路径，以及模板枚举和哈希失败传播问题已修复。目标路径转换与祖先检查见 `bin/ai-harness:57-60,130-145,407-409`；模板列表和哈希结果检查见 `bin/ai-harness:96-113,417-424,429-440`；回归样本见 `tests/cli-upgrade.sh:85-137`。上一轮任务池问题的修复仍见 `template/scripts/ai-new-spec.sh:38-85` 和 `template/scripts/ai-task-pool.sh:21-41,86-89,114-116,156-174`。

## 改进建议（非阻塞，改善即批准）

1. `template/scripts/harness-selftest.sh:832-835` 覆盖 P0 优于 P2，尚未单独断言同优先级按 ID 升序；排序实现见 `template/scripts/ai-task-pool.sh:75`，可补回归样本固定 AC-02 的同级顺序。
2. `tests/cli-upgrade.sh:81-110` 的符号链接断言以 `[ -L ]` 为条件；本机 Git Bash 的 `ln -s` 可退化为复制，因而正式验证可能跳过这些分支。可在支持真实符号链接的 Linux CI 上固定执行路径保护回归。

## 安全六项核对

| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | `bin/ai-harness:394-487` 与 `template/scripts/ai-task-pool.sh:77-179` 均为本地文件 CLI，无登录态或 UID 参数 |
| 入口鉴权 | 不适用 | 上述入口无网络路由；本地门禁不能认证身份见 `template/AGENTS.md:39` |
| SQL / 查询参数化 | 不适用 | `bin/ai-harness:84-169,394-487` 使用文件、目录与哈希，没有数据库查询 |
| 无敏感信息硬编码 | ✅ | 完整 `49c2fc6...87aee8d` 差异未含密钥、token、密码或内网地址 |
| 入参边界校验 | ✅ | `bin/ai-harness:394-424` 校验参数、安装标记、白名单、目标和建议路径；`template/scripts/ai-task-pool.sh:18-21,85-89,111-116,151-158` 校验任务输入 |
| 资源归属校验 | 不适用 | `bin/ai-harness:84-91,394-424` 仅处理调用者指定的本地项目与明确机制白名单，无用户或租户资源 |

## 需求追溯与项目知识

- 需求追溯核对：REQ-01/02、AC-01 的稳定 ID、优先级、原话与两次追加见 `template/scripts/ai-task-pool.sh:78-119`、`template/scripts/harness-selftest.sh:829-842`；REQ-03/AC-02 的活跃 Spec 优先与待办排序见 `template/scripts/ai-task-pool.sh:61-75,133-149`；REQ-04/AC-03 与 ERR-01/02 的关联、归档派生和拒绝路径见 `template/scripts/ai-task-pool.sh:43-60,151-175`。REQ-05/AC-05 的机制白名单、安装基线、未改动更新与补缺见 `bin/ai-harness:84-169,333-337,359-364,394-487`；REQ-06 的定制建议、逐文件确认和上游再变化冲突见 `bin/ai-harness:445-469`、`tests/cli-upgrade.sh:44-64`。ERR-03 的旧安装保守分支、路径预检及 dry-run 只读见 `bin/ai-harness:405-424,429-487`、`tests/cli-upgrade.sh:37-42,66-137`。AC-04 的转发、模板及指南见 `scripts/ai-task-pool.sh:1-3`、`template/AGENTS.md:22-23,77-78`、`README.md:43-48,113-117`。原文锚点“先续做”“追加变化”“自动升级并保留定制”均有对应行为；未见遗漏或超纲。
- 知识检索：从 `docs/architecture/00-INDEX.md` 定位 CLI、模板机制、项目指南及本仓库自用文档；`docs/architecture/modules/cli.md:3-6` 的升级契约与实现一致，其他活文档对任务池入口的描述也一致。`.knowledge/INDEX.md` 无候选卡，故未注入知识卡。
- AI 协作文件审查：已核对本次差异中的根目录与模板 `AGENTS.md`、`skill/SKILL.md`、`template/.agents/skills/new-spec.md`、`archive-spec.md`、`retrofit-legacy.md`、需求模板和 README；升级指南说明旧安装无基线时保守处理、冲突合并及逐文件确认，任务池规则与 CLI 行为一致。未见私有调试信息。
- 审查范围限制：没有在真实外部旧项目执行升级；旧安装由 `tests/cli-upgrade.sh:66-75` 的临时项目模拟。符号链接回归在不支持真实链接的 Git Bash 环境会条件跳过；路径保护代码已静态审查。预检与实际写入之间的并发文件系统变动未模拟，本地脚本不提供身份认证或对抗其他进程的事务隔离。

## 验证证据

- `bash scripts/ai-resume.sh review feat-task-pool 49c2fc6` → 退出 0，当前验证状态匹配。
- `bash scripts/ai-verify.sh --spec feat-task-pool bin/ai-harness` → `verification.md:5-9` 记录 PASS、checks 1、state `cccd18d396e4159517dba3a55105a69f6392d36a26ce86591639c64dd1f7f65e`；正式检查包含任务池自检和 CLI 升级回归（`harness/verify.conf:2`）。
- `git diff --check 49c2fc6...87aee8d` → 退出 0；报告更新前未提交、暂存与未跟踪文件均为空。
