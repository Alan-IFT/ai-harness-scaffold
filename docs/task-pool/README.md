# 本仓库任务池

新需求用 `bash scripts/ai-task-pool.sh add [--priority P0|P1|P2] "原话"` 收集；用 `update <T-ID> "补充"` 追加变化。新会话运行 `bash scripts/ai-resume.sh owner`，先续做活跃 Spec；完成归档后运行 `bash scripts/ai-task-pool.sh next`。任务原话和补充只放在对应 `T-NNNNNN.md`；Spec 引用该文件，不复制一份需求。
