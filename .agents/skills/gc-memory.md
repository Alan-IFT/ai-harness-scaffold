# Skill: 双周上下文垃圾回收与规则下沉 (Context GC & Linter Offloading)

**使用时机**：每两周一次；或 `scripts/ai-check-bloat.sh` 报警时；或 `ai-gate.sh status` 提示红线漂移待确认时。

## Step 0: 先看体检结果
`bash scripts/ai-check-bloat.sh` 与 `bash scripts/ai-gate.sh status`，确认是哪个文件/哪条规则在超预算。

## Step 1: TTL 与证据复核（记忆会过期）
逐条过 `@MEMORY.md`，命中任一条就处理：
- **复核日期过期**（默认 90 天）→ 重新验证；验证不了就删。
- **状态=待验证 且超过两周** → 要么验证，要么删；不许长期挂着"可能对"的结论。
- **与代码冲突** → 以代码为准，删除或改写该条，并在能定位到来源 spec 的 WIP 里补一行 `knowledge_feedback`。
- **置信度 <0.5 且无证据路径** → 删。
- **只能描述"当时发生了什么"而没有可复用结论** → 删（过程留在 archive）。

## Step 2: 下沉为确定性检查（能写代码就不要写文档）
扫描 `@MEMORY.md` 与模块文档里的"红线规则"：
- 能由 ESLint / 类型约束 / 单测 / 架构测试拦截的，写规则、写测试。
- **写完立刻从文档里删掉该条**——代码检查是 100% 确定性的守卫，不需要再花 Token 复述。

## Step 3: 做减法（"只增不减"是反模式）
- 技能 / 角色 / 规则文档数量是否只增不减？合并同类项，删除已失效或从未用过的技能。
- 模块文档是否在重复 `00-INDEX.md` 已经表达的信息？删重复，只留模块独有的边界与红线。
- `AGENTS.md` 是否在悄悄变长？先删再考虑放宽；不要用"这条很重要"当借口。
- 某条规则如果一年没触发过，考虑降级到模块文档，而不是留在 L1。

## Step 4: 验证与收尾
1. 再跑 `bash scripts/ai-check-bloat.sh`，确认回到预算内。
2. 若本次**有意**调整了 `harness/redlines.conf`，必须由人类在交互终端执行 `bash scripts/ai-gate.sh baseline`。
3. 提交：`chore(memory): gc and offload rules to linters`。
