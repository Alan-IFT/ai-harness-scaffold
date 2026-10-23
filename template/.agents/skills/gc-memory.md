# Skill: 双周上下文垃圾回收与规则下沉 (Context GC & Linter Offloading)

**使用时机**：每两周一次；或 `scripts/ai-check-bloat.sh` 报警时；或 `ai-gate.sh status` 提示红线漂移待确认时。

## Step 0: 先看体检结果
```bash
bash scripts/ai-check-bloat.sh     # AGENTS / MEMORY / active spec 体积
bash scripts/ai-knowledge.sh check # 知识卡与索引是否一致
bash scripts/ai-knowledge.sh impact <本次变更路径...> # 关联代码变更后提示复核
bash scripts/ai-knowledge.sh ttl   # 列出生效的「清理候选」（复核期限已过）
bash scripts/ai-knowledge.sh usage # 从 Spec 派生采用情况与未采用卡片
bash scripts/ai-gate.sh status     # 门禁 / 审计 / 红线基线
```

## Step 1: TTL 与证据复核（记忆会过期）
逐条过 `MEMORY.md` 与 `.knowledge/cards/*.md`，命中任一条就处理：
- **复核日期过期**（MEMORY 按 `KNOWLEDGE_TTL_DAYS`；知识卡看「复核期限」）→ 重新验证；验证不了就删或标 `#待验证`。
- **状态=待验证 且超过两周** → 要么验证，要么删；不许长期挂着"可能对"的结论。
- **与代码冲突** → 以代码为准，删除或改写该条，并在能定位到来源 spec 的 WIP 里补一行 `knowledge_feedback`。
- **置信度 <0.5 且无证据路径** → 删。
- **只能描述"当时发生了什么"而没有可复用结论** → 删（过程留在 archive）。
- 知识卡被删除 / 合并后，**同步删掉 `.knowledge/INDEX.md` 的对应行**，否则 `check` 会失败。

## Step 1.5: 清理候选处置（知识飞轮的减法）
- 到期卡片优先「改写」而不是「删」：把结论更新到当前代码状态，刷新复核期限。
- 确实过时（模块已删 / 方案已换）→ 删卡 + 删索引行。
- 被 `knowledge_feedback` 反馈过 2 次以上的卡：置信度 -0.1 并标 `#待验证`，下次再被反馈就删。
- 长期未采用的卡不是"坏卡"——先复核检索词与适用范围；同类 5 条以上时可合并，保持信噪比。不能仅凭采用数删除。

## Step 1.6: 晋升（找到更合适的位置，而不是丢弃）
- 同一主题出现多个答案 → 只留与当前代码一致的一条，其余删除（追溯看 Git）。
- `MEMORY.md` 条目或知识卡被多次验证、已成为某模块的稳定约定 → 写进该模块活文档（`docs/architecture/modules/<module>.md`）的设计决策或已知坑，删除原条目。跨模块通用的写进对应全局约定文档。
- 只记代码事实（「X 定义在 Y 文件」）的条目 → 删除；代码事实以代码和搜索为准，写进文档会随重构过期。
- 同类问题在记忆存在时仍反复出现 → 先考虑 Step 2 下沉为检查；确需新增常驻规则时只写成建议交给维护者决定，AI 不自行改 `AGENTS.md` 规则。

## Step 2: 下沉为确定性检查（能写代码就不要写文档）
扫描 `MEMORY.md`、知识卡与模块文档里的"红线规则"：
- 能由 ESLint / 类型约束 / 单测 / 架构测试拦截的，写规则、写测试。
- **写完立刻从文档里删掉该条**——代码检查是 100% 确定性的守卫，不需要再花 Token 复述。

## Step 3: 做减法（"只增不减"是反模式）
- 技能 / 角色 / 规则文档数量是否只增不减？合并同类项，删除已失效或从未用过的技能。
- 模块文档是否在重复 `00-INDEX.md` 已经表达的信息？删重复，只留模块独有的边界与红线。
- `AGENTS.md` 是否在悄悄变长？先删再考虑放宽；不要用"这条很重要"当借口。
- 某条规则如果一年没触发过，考虑降级到模块文档，而不是留在 L1。

## Step 4: 验证与收尾
1. 再跑 `bash scripts/ai-check-bloat.sh` 与 `bash scripts/ai-knowledge.sh check`，确认都通过。
2. 若本次**有意**调整了 `harness/redlines.conf`，必须由人类在交互终端执行 `bash scripts/ai-gate.sh baseline`。
3. 提交：`chore(memory): gc and offload rules to linters`。
