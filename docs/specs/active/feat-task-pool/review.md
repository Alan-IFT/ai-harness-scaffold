# 代码审查报告 (Code Review): feat-task-pool

- **审查者**：独立 Codex 子 Agent（independent_review）
- **未参与实现**：是
- **审查时间**：2026-10-21
- **审查范围**：`git diff 49c2fc6...602b60b`，含 `design.md` §4 文件清单；另核对未提交、暂存和未跟踪文件
- **CR 轮次**：2 / 4
- 审查状态：0b875357ce60a3c1839fd1120d240ac93be085023641d712d8c764d40de14631

## 结论

- 关键问题（必须修）：0
- 改进建议（非阻塞）：1
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）

无。首轮发现的启动失败残留、非法优先级可直接启动、空白原话和补充均已修复：`template/scripts/ai-new-spec.sh:38-85`、`template/scripts/ai-task-pool.sh:21-41,86-89,114-116,156-174`；回归样本见 `template/scripts/harness-selftest.sh:829-866`。

## 改进建议（非阻塞，改善即批准）

1. `template/scripts/harness-selftest.sh:832-835` 验证了 P0 优于 P2，但尚未用同优先级的两条待办断言 ID 升序；`template/scripts/ai-task-pool.sh:75` 已按 ID 排序，可补一条回归样本以固定 AC-02 的同级顺序契约。

## 安全六项核对

| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | `template/scripts/ai-task-pool.sh:77-179` 是本地文件 CLI，无登录态或 UID 参数 |
| 入口鉴权 | 不适用 | `template/scripts/ai-task-pool.sh:77-179` 无网络路由；仓库规则已说明本地门禁不能认证身份（`template/AGENTS.md:39`） |
| SQL / 查询参数化 | 不适用 | `template/scripts/ai-task-pool.sh:20-75` 只读取 Markdown 和 Spec 目录，无数据库查询 |
| 无敏感信息硬编码 | ✅ | 完整 `49c2fc6...602b60b` 差异仅含脚本、指南、Spec 和示例任务，无密钥、token 或密码 |
| 入参边界校验 | ✅ | `template/scripts/ai-task-pool.sh:18-21,85-89,111-116,151-158` 校验 ID、Spec ID、优先级及非空单行文本 |
| 资源归属校验 | 不适用 | `template/scripts/ai-task-pool.sh:5,22-41` 仅操作当前项目本地任务池，无用户或租户资源 |

## 需求追溯与项目知识

- 需求追溯核对：REQ-01 / AC-01 的稳定 ID、P0/P1/P2 与原话见 `template/scripts/ai-task-pool.sh:78-108`；REQ-02 的带日期追加见 `:110-119`。REQ-03 / AC-02 的活跃 Spec 优先与待办排序见 `:61-75,133-149`，owner 提示见 `template/scripts/ai-resume.sh:151-157`。REQ-04 / AC-03 的稳定 Spec 关联、目录派生状态和归档后切换见 `template/scripts/ai-task-pool.sh:43-60,151-175` 与 `template/scripts/harness-selftest.sh:852-866`。ERR-01 / ERR-02 的拒绝路径见 `template/scripts/ai-task-pool.sh:18-26,85-89,151-170`。AC-04 的模板入口、薄转发及文档见 `scripts/ai-task-pool.sh:1-3`、`template/docs/task-pool/README.md:1-14`、`template/AGENTS.md:22,77-78`。原文锚点“先续做”和“追加变化”均有对应行为；未见遗漏或超纲。
- 知识检索：`docs/architecture/00-INDEX.md` 定位模板机制、项目指南和本仓库自用模块；已核对 `docs/architecture/modules/template-mechanism.md:3`、`guidance.md:3`、`self-hosting.md:3-6` 与代码一致。`.knowledge/INDEX.md` 无候选卡，故未注入知识卡。
- AI 协作文件审查：本次改动的根目录及模板 `AGENTS.md`、`template/.agents/skills/new-spec.md`、`archive-spec.md`、`retrofit-legacy.md`、需求模板和 README 均说明任务池入口、Spec 关联及旧 INTAKE 历史；根脚本保持薄转发。未见相互矛盾或私有调试信息。
- 审查范围限制：旧项目 `retrofit` 的冲突隔离和 `--dry-run` 依据 `bin/ai-harness:149-178,254-280` 静态核对，未在外部旧项目执行；未独立重跑完整自检，采用正式验证摘要和新增断言内容作为测试证据。报告撰写期间主 Agent 更新了 `tasks.md` 的 WIP，该交接文字不属于已审实现差异。

## 验证证据

- `bash scripts/ai-resume.sh review feat-task-pool 49c2fc6` → 退出 0，当前摘要状态可核验。
- `bash scripts/ai-verify.sh --spec feat-task-pool template/scripts/ai-task-pool.sh` → `verification.md:5-9` 记录 PASS、checks 1、state `0b875357ce60a3c1839fd1120d240ac93be085023641d712d8c764d40de14631`。
- `git diff --check 49c2fc6...602b60b` → 退出 0；开始撰写报告前，未提交 / 暂存差异及未跟踪文件均为空。
