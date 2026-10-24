# 本仓库自用状态

- **任务池自用**：根目录 `scripts/ai-task-pool.sh` 是转发脚本；维护者直接向 AI 提需求，由 AI 用 `intake` 自动收录与路由，人工指定通过 `prefer` 持久化。本仓库的新想法保存在 `docs/task-pool/`，旧 `docs/INTAKE.md` 历史保留。owner 接手输出当前 Spec 或下一项。

- **职责**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/` 与 `harness/` 记录这个源码仓库的开发状态。
- **需求与度量**：新需求在 `docs/task-pool/T-NNNNNN.md` 保存原话、补充、兼容性优先级信息和稳定 Spec ID；默认按 ID 先后处理，`docs/task-pool/NEXT` 可一次性覆盖。`docs/INTAKE.md` 保留旧记录。归档不改写任务文件的阶段路径；归档后 Spec ID 不可重用。`docs/metrics.md` 只记录本项目交付事实。
- **边界**：根目录 `scripts/` 是薄转发入口；脚手架机制仍只在 `template/scripts/` 维护。根目录接手也必须显式选择 `owner`、`worker` 或 `review`，薄转发脚本不复制参数解析逻辑。根目录 `harness/redlines.conf` 是本仓库自己的阈值事实，不与分发样本强制同步；其中的 `FEASIBILITY_MIN`、`KNOWLEDGE_TTL_DAYS` 已无脚本读取，待维护者清理。当前工作区已有 Git 仓库，不能重新创建历史或覆盖未提交改动。
- **验证**：本仓库 `harness/verify.conf` 调用 `tests/verify-repo-quick.sh` 做目标 Shell/CLI 语法、指南标题与上下文体积和双区 diff 短检查；正式验证调用 `tests/verify-repo.sh`，先做双区 diff 的低成本拒绝，再逐阶段计时运行模板全自检和 CLI 回归。quick 不生成 G4 摘要。Agent 执行 G6 核验，象限②③由人当次决定；`.gates` 是阶段事实，门间耗时由 `ai-gate.sh metrics` 派生。
