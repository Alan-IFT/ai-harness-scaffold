# 本仓库自用状态

- **任务池自用**：根目录 `scripts/ai-task-pool.sh` 是转发脚本；维护者直接向 AI 提需求，由 AI 用 `intake` 自动收录与路由，人工指定通过 `prefer` 持久化。owner 接手输出当前 Spec 或下一项。

- **职责**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/` 与 `harness/` 记录这个源码仓库的开发状态。
- **需求与度量**：新需求在 `process/task-pool/T-NNNNNN.md` 保存原话、补充和稳定 Spec ID；默认按 ID 先后处理，`process/task-pool/NEXT` 可一次性覆盖。归档不改写任务文件的阶段路径；归档后 Spec ID 不可重用。`process/metrics.md` 只记录本项目交付事实。
- **边界**：根目录 `scripts/` 是薄转发入口；脚手架机制仍只在 `template/scripts/` 维护。薄转发脚本不复制参数解析逻辑。根目录 `harness/redlines.conf` 是本仓库自己的阈值事实，不与分发样本强制同步。当前工作区已有 Git 仓库，不能重新创建历史或覆盖未提交改动。
- **验证**：本仓库 `harness/verify.conf` 调用 `tests/verify-repo.sh`：先做双区 diff 的低成本拒绝，再计时运行模板全自检。`.gates` 是阶段事实，门间耗时从其时间戳计算。
