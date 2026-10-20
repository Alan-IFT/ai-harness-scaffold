# 知识资产索引 (Knowledge Index)

> 由 `.agents/skills/knowledge-distill.md` 蒸馏产生；`bash scripts/ai-knowledge.sh check` 机械校验索引与卡片的一致性。
> **复核期限 < 今天** 的卡片进入「清理候选」（`bash scripts/ai-knowledge.sh ttl` 列出），由 `gc-memory` 复核：删 / 改写 / 降置信度。
> **前置强注入**：先用 `ai-knowledge.sh suggest <module>` 列有效候选并在 `tasks.md` §1 记取舍；G4 校验注入的卡片存在、未过期且非 `#待验证`。相关代码变化后用 `impact <path...>` 提示复核。
> 字段：ID / 类型（技术方案·踩坑记录·经验复盘·PRD 模板）/ 模块 / 置信度 0~1 / 复核期限 / 引用次数 / 结论摘要。

| ID | 类型 | 模块 | 置信度 | 复核期限 | 引用次数 | 结论摘要 |
| :-- | :-- | :-- | :-- | :-- | :-- | :-- |
