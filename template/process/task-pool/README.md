# 项目任务池

维护者直接向 AI 说需求即可，AI 会判断是独立新需求还是已有需求的补充，并自动调用任务池。每条新需求存成一个 `T-NNNNNN.md` 文件；原话留在「原始需求」，新信息追加在「补充与变更」。未开始的任务可把「队列状态」改成「暂缓」或「取消」，恢复时改回「待办」。旧优先级字段保留兼容与展示，不改变任务顺序。

常用命令：

```bash
bash scripts/ai-task-pool.sh intake "想做的事情"
bash scripts/ai-task-pool.sh update T-000001 "补充的约束"
bash scripts/ai-task-pool.sh prefer T-000001
bash scripts/ai-task-pool.sh next
bash scripts/ai-task-pool.sh start-next
bash scripts/ai-task-pool.sh archive feat-example
```

以上命令由 AI 执行，维护者无需记忆。新会话先运行 `bash scripts/ai-resume.sh owner`，有待办时再用 `start-next` 原子判断与启动。有活跃 Spec 时先续做；没有时自动按录入先后启动最早待办，空池就启动刚提出的需求。维护者可说“先做 T-000001”或用任务内容指明，AI 会记录一次性指定；当前任务完成后生效，仅在该任务启动后清除。归档由 AI 使用 `archive` 在同一任务池锁下移动 Spec，并在归档提交后启动下一项。开始任务后只存稳定 Spec ID；任务的进行中/归档状态从 Spec 目录派生。已开始的需求变化需同步修订 Spec 并回退受影响阶段。若收录成功但自动启动失败，按输出的 T-ID 恢复，不要重复提交以免产生重复任务。
