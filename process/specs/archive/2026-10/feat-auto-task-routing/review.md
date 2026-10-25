# 代码审查报告 (Code Review): feat-auto-task-routing

- **审查者**：Codex 独立子 Agent `/root/auto_routing_review_2`
- **未参与实现**：是
- **审查时间**：2026-10-22
- **审查范围**：基准 `751cd60c80e066dab8148b5fb1497e071ac92850` 至 HEAD（当前 HEAD 即基准，提交 diff 为空）、完整暂存 diff（23 个文件）、未暂存的 Spec 流程记录与核验摘要；无相关未跟踪文件。覆盖 design.md §4 的脚本、指南、README、归档技能、架构文档及任务原件。
- **CR 轮次**：4 / 4
- 审查状态: 0b0d1c8afeef901b98003213489de6b44d78fe4a4a8c877247a6e4749f735b55

## 结论

- 关键问题（必须修）：0
- 改进建议（非阻塞）：1
- 判定：通过；首轮两项关键问题仍已闭环，暂存与空白修正没有引入新的阻塞问题。

## 前两轮问题逐项复核

1. 人工指定被误清除：已修复。`template/scripts/ai-task-pool.sh:230-268` 在同一任务池锁内选择、启动，且仅当成功启动的 `task_id` 等于 `NEXT` 才清除指定；`prefer` 也持该锁（第 150–157 行）。自检 `template/scripts/harness-selftest.sh:873-883` 断言启动其他任务后保留指定、启动指定任务后清除。REQ-04 / AC-03 满足。
2. 活跃 Spec 归档与 `intake` 的时序：已修复。`intake` 通过 `start-next` 路由（`ai-task-pool.sh:97-106`），其活跃检查和领取受锁保护（第 230–268 行）；`archive` 在同一锁下移动目录（第 193–217 行）。先归档则 `start-next` 领取待办；先路由则归档指南在 G7 / 提交后继续 `start-next`（`template/.agents/skills/archive-spec.md:45-47`）。锁冲突不移动 active 的断言见 `harness-selftest.sh:870-878`。本轮完整暂存源码 diff 与第三轮相同；REQ-02 / AC-01 的原竞态闭环结论不变。

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

无。

## 改进建议（非阻塞）

- `template/.agents/skills/archive-spec.md:37-47`：提交步骤没有明确说明 `archive` 使用 `mv` 后要暂存移动产生的 Git 删除与新增。建议在提交指南中写出按本次文件范围检查并暂存的动作，避免归档内容遗漏提交；不影响脚本归档和自动路由的正确性。

## 安全六项核对

| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 Bash 文件工具，无登录态或 UID 参数；`template/scripts/ai-task-pool.sh:95-272` |
| 入口鉴权 | 不适用 | 无网络入口；文件权限由本地项目提供；`template/scripts/ai-task-pool.sh:32-46` |
| SQL / 查询参数化 | 不适用 | 无数据库查询，任务为 Markdown 文件；`template/scripts/ai-task-pool.sh:119-137` |
| 无硬编码敏感信息 | ✅ | 完整脚本、指南和归档技能 diff 未出现密钥、token、密码或内网地址 |
| 入参边界校验 | ✅ | T-ID、Spec ID、优先级、空白和换行检查见 `ai-task-pool.sh:22-30,109-118,139-157,193-196,219-253`；归档拒绝父路径 / 源目录符号链接、已有目标并核对实际路径见第 198–216 行 |
| 资源归属校验 | 不适用 | 单仓库本地文件工具，无租户或跨用户资源 API；`template/scripts/ai-task-pool.sh:5,27-30` |

## 需求追溯与项目知识

- 需求追溯核对：暂存的 `docs/task-pool/T-000002.md:9` 保留完整原话，末尾空白修正不改变需求语义；requirements.md §2.3 / §3 与 design.md §1.1 覆盖 REQ-01~05、ERR-01~02、AC-01~04。REQ-01/02 的收录、活跃续做和自动启动见 `ai-task-pool.sh:97-106,230-268`；REQ-03 与旧 `--priority` 兼容见第 65–80、107–137 行；REQ-04、ERR-01 的指定校验与消费见第 150–157、265–267 行；REQ-05 的补充与已开始任务修订由第 139–148 行及 `template/AGENTS.md:22` 指引。ERR-02 的收录后失败提示见第 99–105 行；自检覆盖空池、活跃、非空池、模板失败、锁冲突、指定消费与归档后领取（`harness-selftest.sh:832-908`）。`next`/`list` 分支无持久写入（`ai-task-pool.sh:159-192`）。
- 知识检索：查看 `docs/architecture/00-INDEX.md`、模板机制 / 指南 / 本仓库自用三篇活文档、`.knowledge/INDEX.md` 与 `.knowledge/cards/`；索引为空且卡目录仅 `.gitkeep`，无可采用卡。活文档与自然语言入口、FIFO、同锁归档契约一致。
- AI 协作文件审查：本次 diff 含 `AGENTS.md`、`template/AGENTS.md`、`template/.agents/skills/new-spec.md`、`archive-spec.md`、两处任务池 README、INTAKE、架构文档及自检脚本。`intake`、`update`、`prefer`、`start-next`、`archive` 和失败恢复的指南与实现一致；`archive-spec.md:27-31,45-47` 已改为同锁归档及归档后领取。根目录 `scripts/ai-task-pool.sh:1-3` 仍只是转发。
- 审查范围限制：本环境 `bash.exe` 执行被拒绝，无法独立运行 review 入口、G4 命令或复算状态指纹；已核对 Git 基准、完整暂存 diff、未暂存流程差异、任务原件与 `verification.md` / 本地报告摘要。未实测真实多进程交错或外部旧项目升级。`git diff --cached --check` 与 `git diff --check` 均通过。

## 验证证据（只放命令与结果摘要，不贴全文）

- `bash scripts/ai-verify.sh --spec feat-auto-task-routing template/scripts/ai-task-pool.sh` → 当前 `verification.md` 记录 result: PASS、checks: 1、state: `0b0d1c8afeef901b98003213489de6b44d78fe4a4a8c877247a6e4749f735b55`；本地 `verify-20261022-020742-1809.log` 记自检 210/210 与 `cli-upgrade: PASS`，但本审查环境无法复跑。
- `git diff 751cd60...HEAD` 为空；`git diff --cached` 覆盖 23 个暂存文件，`git diff` 含本 Spec 的 `.gates`、`.violations`、`verification.md`、`acceptance.md` 及本审查报告的流程更新；`git ls-files --others --exclude-standard` 为空。两种 diff 的 `--check` 均退出 0。
