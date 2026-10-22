# 项目任务池

每条新需求存成一个 `T-NNNNNN.md` 文件。原始需求留在「原始需求」，新信息追加在「补充与变更」；优先级可改为 P0、P1 或 P2。未开始的任务可把「队列状态」改成「暂缓」或「取消」，恢复时改回「待办」。

常用命令：

```bash
bash scripts/ai-task-pool.sh add --priority P1 "想做的事情"
bash scripts/ai-task-pool.sh update T-000001 "补充的约束"
bash scripts/ai-task-pool.sh next
bash scripts/ai-task-pool.sh start T-000001 feat-example
```

新会话先运行 `bash scripts/ai-resume.sh owner`。有活跃 Spec 时先续做；没有时 `next` 按 P0 → P1 → P2、同级 ID 升序选择。开始任务后只存稳定 Spec ID；任务的进行中/归档状态从 Spec 目录派生。归档完成后再次运行 `next` 即可拿到下一项。若已开始的需求发生变化，先追加补充，再修订 Spec 并按 `ai-gate.sh reset` 回退受影响阶段。
