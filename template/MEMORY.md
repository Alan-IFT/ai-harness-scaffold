# Project Dynamic Memory & Quirks (跨工具踩坑记录池)

> ⚠️ **防膨胀红线**：行数上限以 `harness/redlines.conf` 的 `MEMORY_MAX_LINES` 为准（`scripts/ai-check-bloat.sh` 强制）。
> 只记录**非直觉、可跨需求复用**的结论；能变成 Linter / 类型 / 测试的立刻下沉并删除本条。
>
> **条目格式**（缺字段的条目在双周 GC 时降权或删除）：
> `- [触发条件] 结论（证据：路径/commit/issue；复核：YYYY-MM-DD；状态：已验证/待验证；置信度：0~1）`
>
> 复核日期到期（按 `harness/redlines.conf` 的 `KNOWLEDGE_TTL_DAYS`）必须重新验证或删除。与代码冲突时**以代码为准**，
> 并在对应 spec 的 WIP 里记 `knowledge_feedback`，GC 时据此降权。

## 1. 构建与测试环境怪癖 (Build & Test Quirks)
暂无记录。

## 2. 第三方依赖避坑指南 (Third-Party Gotchas)
暂无记录。

## 3. 待下沉为 Linter 的临时规则 (Pending Linter Offload)
暂无记录。
