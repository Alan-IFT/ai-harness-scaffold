# Skill: 功能完结后的合并、蒸馏与防膨胀归档 (Spec Merge, Distill & Archive)

**前置条件**：`bash scripts/ai-gate.sh status <feat>` 显示 G1~G6 全绿；实现相关活文档、知识卡与路线图已在最后一次正式 G4 验证前同步，G6 后不再改动这些文件。
**产出**：已复核的活文档与知识卡 + 归档目录 + 度量行 + 一个干净的 commit。
正式 G4 的验证目标须选归档后路径不变的项目文件；`docs/specs/**`、`docs/metrics.md` 和 `docs/task-pool/**` 是流程记录，不计入状态指纹，也不能作为正式目标；Spec 进行中收录或补充任务不会使验证摘要过期。

象限④是分析与人工移交，不走本技能的 G6/G7 交付归档：在关联任务文件记录人工接管决定；若已经建立 Spec，G1 后将其移到 `docs/specs/archive/YYYY-MM/`，不写交付度量行。保留需求和分析作为依据，但不让它长期占用 active 名额。

## Step 1: 复核「活态真相区」(`docs/architecture/`)
1. 对照 `design.md` §3 / §4，确认新增模块、公共契约、核心数据表和红线已在最后一次正式 G4 验证前同步。
2. 如仍须修改模块活文档或 `00-INDEX.md`，先修改并按门禁回退、重跑正式验证与后续门；不要在 G6 后悄悄使验证摘要过期。
3. 任务文件只存稳定 Spec ID，物理归档时不更新路径或阶段；由 `ai-gate.sh status <feat>` 定位。旧 `docs/INTAKE.md` 历史无需迁移。

## Step 2: 复核知识卡与路线图
1. 可复用结论应已在最后一次正式 G4 前按 `.agents/skills/knowledge-distill.md` 蒸馏，至多 3 条；没有可复用结论可为 0 条。此时只核对 `.knowledge/cards/` 与 `.knowledge/INDEX.md`。
2. `bash scripts/ai-knowledge.sh check` 必须通过，并用 `bash scripts/ai-knowledge.sh impact <本次变更路径...>` 复核关联卡。
3. 若本次涉及里程碑，核对 `docs/roadmap/ROADMAP.md` 已在最后一次正式 G4 前更新。
4. 若 G5 审查或 G6 核验产生必须写入知识卡、路线图或其他非流程文件的新结论，先按门禁规则回退并重跑正式 G4 与后续门；不能在归档时补写后仍沿用旧摘要。

## Step 3: 记录度量（`docs/metrics.md` 追加一行）
先运行 `bash scripts/ai-gate.sh metrics <feat>`，从 `.gates` 自动得到门间耗时；再从关联任务文件（或旧 `docs/INTAKE.md`）、当前 Spec、`review.md`、`.violations` 和本地 `reports/` 补充非门禁事实。不要另算一份时间或美化；缺少时间戳写「未知」：
- 需求提出 → G1、G3 → G4、G4 → G6 的耗时；人工或外部依赖等待只记有证据的时间。
- 遗漏的间接影响与返工、交付形态及实际反馈；待发布或未观察写清状态。
- 若 G7 时仍待发布，在 `acceptance.md` 留回访时间；发布后补记结果并更新 `docs/metrics.md` 对应行，不把「测试通过」写成用户效果。
- CR 轮次、验证失败次数、门禁回退次数可留在备注或月度分析，不必为凑数伪造。

## Step 4: 同锁物理归档
```bash
bash scripts/ai-task-pool.sh archive <feat>
```
本命令与 `start-next` 共用任务池锁；锁冲突时归档失败、active 不移动，稍后重试，不能把失败当作已归档。归档前后的详细 `reports/` 只留本机，不入 Git。提交前用 `git ls-files docs/specs/archive/YYYY-MM/<feat>/reports/` 检查，若有输出，用 `git rm --cached -r -- docs/specs/archive/YYYY-MM/<feat>/reports/` 取消跟踪（`--cached` 保留本机文件）。可交接的结果仍以 `verification.md` 摘要为准。
> `docs/specs/archive/**` 已被 `.cursorignore` / `.claudeignore` 屏蔽，归档后不再进入任何 AI 会话的检索范围。

## Step 5: 记录归档门
1. `bash scripts/ai-gate.sh pass <feat> g7`（此时 spec 已在 archive，g7 校验依赖这一点）。

## Step 6: 收尾体检与提交
1. `bash scripts/ai-check-bloat.sh`：确认 AGENTS.md / MEMORY.md / active spec 数量都在预算内。
2. `bash scripts/ai-knowledge.sh check`：确认知识库索引一致。
3. 提交，建议拆成两个 commit：
   - `docs(archive): merge living docs and archive <feat>`
   - `chore(memory): distill reusable lessons from <feat>`
4. 若发现 archive 里还有未走完流程的 spec：**不要顺手删**，记入新 spec 的「发现但不碰」并告知人类。

## Step 7: 交接下一项

提交后运行 `bash scripts/ai-task-pool.sh next`；若显示待办，立即由 AI 调用 `bash scripts/ai-task-pool.sh start-next` 创建下一项 Spec。这个动作与 intake 在归档时看到的活跃状态相衔接；下一会话再按 owner 接手继续。任务池为空则结束，不让维护者记忆命令。

若 `acceptance.md` 的「后续动作」有基于证据的候选下一问，仅保留为候选并在交接时说明；维护者提出或确认要做后，再按新需求收录。不要把候选问题当作现有待办自动入队。
