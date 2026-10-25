# 本仓库任务池

维护者直接说需求，AI 自动调用 `bash scripts/ai-task-pool.sh intake "原话"`。有活跃 Spec 时新需求入队；没有时启动人工指定或最早录入的待办，空池则启动当前需求。补充已有需求由 AI 用 `update <T-ID> "补充"` 追加；维护者说“先做某项”时由 AI 用 `prefer <T-ID>` 指定下一项，跨会话有效且仅在该项启动后清除。新会话先运行 `bash scripts/ai-resume.sh owner`，再用 `start-next` 原子选取与启动。旧优先级字段仍可读写但不改变先来先做顺序。原话和补充只放在对应 `T-NNNNNN.md`；Spec 引用该文件。
