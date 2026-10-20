# Skill: 功能完结后的合并、蒸馏与防膨胀归档 (Spec Merge, Distill & Archive)

**前置条件**：`bash scripts/ai-gate.sh status <feat>` 显示 G1~G6 全绿、无未提交改动。
**产出**：活文档更新 + 至多 3 条可复用知识 + 归档目录 + 一个干净的 commit。

## Step 1: 把增量变更同步到「活态真相区」(`docs/architecture/`)
1. 对照 `design.md` §3 / §4，检查是否新增模块、改变公共契约、修改核心数据表、新增模块专属红线。
2. 打开 `@docs/architecture/00-INDEX.md` 对应的模块文档，**精简覆盖**（原地更新当前状态，不写历史流水账），并更新 `last_updated`。
3. 新增业务模块时，在 `00-INDEX.md` 补一行路由映射；删掉已下线模块的映射。

## Step 2: 蒸馏知识（只留可跨需求复用的结论，每次至多 3 条）
逐项问自己「下个需求真的会用到吗？不用会踩坑吗？」——两个都否就**不要记**。
- **方案骨架**（分层 / 事务边界 / 可复用接口形状）→ 并入对应模块活文档。
- **重复出现的 CR 问题** → 写成一条 `@MEMORY.md` 条目（触发条件 + 结论 + 证据 + 复核日期 + 状态 + 置信度）；
  能写成 Linter / 类型 / 测试的，写代码而不是写文档。
- **需求澄清里的通用追问** → 只在这确实是通用问题时补进 `requirements.md` 模板，不要每个 feature 都往里加。
- **一次性的过程细节 / 谁改了什么** → 不蒸馏，归档里留着即可。

## Step 3: 物理归档
```bash
# 有 git 用 git mv，没有就 mv
mkdir -p docs/specs/archive/$(date +%Y-%m)
git mv docs/specs/active/<feat> docs/specs/archive/$(date +%Y-%m)/
```
> `docs/specs/archive/**` 已被 `.cursorignore` / `.claudeignore` 屏蔽，归档后不再进入任何 AI 会话的检索范围。

## Step 4: 记录归档门 + 更新路线图
1. `bash scripts/ai-gate.sh pass <feat> g7`（此时 spec 已在 archive，g7 校验依赖这一点）。
2. 如涉及里程碑，勾选 `@docs/roadmap/ROADMAP.md` 对应条目。

## Step 5: 收尾体检与提交
1. `bash scripts/ai-check-bloat.sh`：确认 AGENTS.md / MEMORY.md / active spec 数量都在预算内。
2. 提交，建议拆成两个 commit：
   - `docs(archive): merge living docs and archive <feat>`
   - `chore(memory): distill reusable lessons from <feat>`
3. 若发现 archive 里还有未走完流程的 spec：**不要顺手删**，记入新 spec 的「发现但不碰」并告知人类。
