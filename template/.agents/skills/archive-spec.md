# Skill: 归档与交接下一项

**前置条件**：`bash scripts/ai-gate.sh status <feat>` 显示三道门全部通过。

## Step 1: 复核活文档与记忆
- 新增模块、公共契约或红线已在验证前写进 `docs/architecture/`；本次被纠正的做法、反复尝试才解决的问题已写进 `MEMORY.md`。没有可复用结论可以为 0 条。
- 归档时若还要改非流程文件，先 `ai-gate.sh reset <feat> g2`，改完重新验证和审查，不要沿用旧摘要。

## Step 2: 记一行度量（`process/metrics.md`）
运行 `bash scripts/ai-gate.sh metrics <feat>` 取门间耗时，再写返工原因与交付状态。缺少证据写「未知」，未发布写「待观察」，不把测试通过写成用户效果。

## Step 3: 归档
```bash
bash scripts/ai-task-pool.sh archive <feat>
```
与 `start-next` 共用任务池锁；锁冲突时归档失败、active 不移动，稍后重试。`reports/` 只留本机：提交前用 `git ls-files process/specs/archive/YYYY-MM/<feat>/reports/` 检查，有输出就 `git rm --cached -r` 取消跟踪。

## Step 4: 提交与交接
1. `bash scripts/ai-check-bloat.sh` 确认体积在预算内，然后提交。
2. 运行 `bash scripts/ai-task-pool.sh next`；有待办就由 AI 调用 `start-next` 开始下一项，任务池为空则结束。审查里的改进建议只作为候选告诉维护者，维护者确认后再收录。
