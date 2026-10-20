# Project Dynamic Memory & Quirks (跨工具踩坑记录池)

> ⚠️ **防膨胀红线**：150 行以内（`scripts/ai-check-bloat.sh` 强制）。
> 只记录**非直觉、可跨需求复用**的结论；能变成 Linter / 类型 / 测试的立刻下沉并删除本条。
>
> **条目格式**（缺字段的条目在双周 GC 时降权或删除）：
> `- [触发条件] 结论（证据：路径/commit/issue；复核：YYYY-MM-DD；状态：已验证/待验证；置信度：0~1）`
>
> 复核日期到期（默认 90 天）必须重新验证或删除。与代码冲突时**以代码为准**，
> 并在对应 spec 的 WIP 里记 `knowledge_feedback`，GC 时据此降权。

## 1. 构建与测试环境怪癖 (Build & Test Quirks)
- [本地单测] 单测不需要 Docker，但涉及 Redis 的集成测试需先设 `MOCK_REDIS=true`（证据：待补；复核：2026-10-19；状态：待验证；置信度：0.6）

## 2. 第三方依赖避坑指南 (Third-Party Gotchas)
- [日期处理] 统一用 `dayjs`，不要引入 `moment`，也不要用原生 `Date.parse()` 解析非 ISO 字符串（证据：待补；复核：2026-10-19；状态：待验证；置信度：0.7）

## 3. 待下沉为 Linter 的临时规则 (Pending Linter Offload)
- [控制器层] 禁止直接导入 ORM 实例（待编 ESLint `no-restricted-imports` 后删除本条；复核：2026-10-19；状态：待验证；置信度：0.6）
