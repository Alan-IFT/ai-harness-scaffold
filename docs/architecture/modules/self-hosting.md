# 本仓库自用状态

- **任务池自用**：根目录 `scripts/ai-task-pool.sh` 是转发脚本；本仓库的新想法保存在 `docs/task-pool/`，旧 `docs/INTAKE.md` 历史保留。owner 接手输出当前 Spec 或下一项。

- **职责**：根目录 `AGENTS.md`、`MEMORY.md`、`docs/`、`harness/` 与 `.knowledge/` 记录这个源码仓库的开发状态。
- **需求与度量**：新需求在 `docs/task-pool/T-NNNNNN.md` 保存原话、补充、优先级和稳定 Spec ID；`docs/INTAKE.md` 保留旧记录。归档不改写任务文件的阶段路径；归档后 Spec ID 不可重用。`docs/metrics.md` 只记录本项目交付事实。
- **边界**：根目录 `scripts/` 是薄转发入口；脚手架机制仍只在 `template/scripts/` 维护。根目录接手也必须显式选择 `owner`、`worker` 或 `review`，薄转发脚本不复制参数解析逻辑。根目录 `harness/redlines.conf` 是本仓库自己的阈值事实，不与分发样本强制同步。当前工作区已有 Git 仓库，不能重新创建历史或覆盖未提交改动。
- **验证**：本仓库 `harness/verify.conf` 的 quick 仅做语法与 diff 检查；正式验证跑模板全自检和 diff 检查。Agent 执行 G6 核验，象限②③默认由人决定，明确条件委托仅在授权范围内生效；`.gates` 是阶段事实，门间耗时由 `ai-gate.sh metrics` 派生。
- **知识采用事实**：`.knowledge/INDEX.md` 不存手工引用次数；采用量由 Spec 中的注入记录派生。
