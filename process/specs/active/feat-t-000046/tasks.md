# 任务与接力：feat-t-000046

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000046` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：`archive` 在移动 Spec 目录之前，先把池里 `关联 Spec` 等于该 feat 的任务文件移进这个 Spec 目录，再整体移走；先移任务文件，是为了目录移动失败后重跑 `archive` 能接着完成。编号扫描多看一处 `process/specs/archive/*/*/T-*.md`：任务可以关联到名字不是 `feat-t-*` 的 Spec（本仓库 T-000028 关联的是 feat-t-000037），只看目录名会漏掉它的编号。`status_for` 不再查归档目录：关联的 Spec 在 active 就是「进行中」，否则「关联异常」，`spec_location` 删掉。三处 `basename` 换成参数展开。没有选「任务文件留在池里、改成一次 awk 读完」：那要重写 `pending_rows` 和 `list`，池里文件仍然越积越多；移走之后「池里只有没做完的」也更直接。
- 改动文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/upgrade.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`；本仓库 `process/task-pool/` 的 16 个任务文件移进 `process/specs/archive/`。
- 影响与风险：
  - 调用方：`ai-resume.sh` 调 `next`，`archive-spec.md` 调 `archive`，命令和输出格式都不变。搜索过「已归档」这个状态值，只有自检第 308 行的断言依赖它；README 和模板指南没有引用 `list` 的输出。
  - 已接入项目：升级后池里遗留的已归档任务文件在 `list` 里显示「关联异常」；`next` 照旧跳过它们（`关联 Spec` 不是「无」），不会被重新领取。`upgrade.md` 加一句处理办法。
  - 中途失败：任务文件移动失败时 Spec 仍在 active，重跑即可；目录移动失败时任务文件已在 Spec 目录里，重跑时一并带走。
  - 已知取舍：归档 Spec 的「需求来源」仍写着 `process/task-pool/` 下的旧路径；任务文件就在同一目录，历史 Spec 按规则不读，不为它加改写逻辑。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：任务池脚本与自检
  - 对应验收：AC-01、AC-02、AC-03、AC-04、AC-05、AC-08
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`
  - 验证：`bash scripts/harness-selftest.sh`；AC-03、AC-04 的 grep；临时目录造 300 个已归档任务测 `next`、`list`、`add` 耗时
- [x] Task 2：指南、README 与活文档
  - 对应验收：AC-06
  - 涉及文件：`template/.agents/skills/archive-spec.md`、`template/.agents/skills/upgrade.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`
  - 验证：AC-06 的 grep
- [x] Task 3：移走本仓库池里已归档的任务文件
  - 对应验收：AC-07
  - 涉及文件：`process/task-pool/`、`process/specs/archive/`
  - 验证：AC-07 的两条命令

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- 无

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无
- 已完成：需求与方案。改动前实测（2026-11-09，本机 Git Bash，临时目录）：300 个已归档任务留在池里时 `next` 38 秒、`list` 93 秒、`add` 21 秒；只把 `basename` 换成参数展开，`add` 降到 0.16 秒，`next` 仍要 28 秒。
- 已完成：Task 1。自检 76 项断言、失败 0 项（新增 2 项，改 1 项）。AC-05 实测（同一环境，用改后的脚本）：300 个任务文件已随 Spec 归档、池里 4 个待办时，`next` 0.87 秒、`list` 0.88 秒、`add` 0.17 秒，新编号接在 300 之后。AC-03 的 grep 输出 1，AC-04 的 grep 输出 0。
- 已完成：Task 2、Task 3。AC-06 的 grep 各命中；本仓库 16 个任务文件已移进 15 个归档 Spec 目录（T-000028 与 T-000037 同在 feat-t-000037），`list` 只剩 T-000046、T-000047，没有「关联异常」。
- 已排除的方案：任务文件留在池里、用一次 awk 读完（见方案）；任务一开始就移进 Spec 目录并删掉 `关联 Spec` 字段（升级后遗留的已归档任务会被当成待办，要靠人工迁移兜底）。
- 下一步：正式验证、独立审查、归档；发新版本前问维护者
