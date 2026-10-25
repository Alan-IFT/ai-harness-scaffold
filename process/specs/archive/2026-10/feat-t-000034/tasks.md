# 任务与接力：feat-t-000034

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000034` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：门禁收紧两处、任务池三处、加个人偏好文件、补四处说明，全部并进现有脚本与文档：
  - 门禁（`ai-gate.sh`）：g1 双向核对 requirements 的 AC 编号与 tasks.md 里出现的 AC 编号；g2 要求验证目标以反引号路径出现在 tasks.md。
  - 任务池（`ai-task-pool.sh`）：`archive` 先确认 `.gates` 有 g1~g3，再跑一次 `ai-gate.sh check <feat> g3`（它会复核 g2 的状态指纹），任一失败就拒绝；删 `update`、`prefer`、`NEXT`，改为任务文件里可选的 `- 优先: 是` 字段，排序时优先；编号取任务文件与 `process/specs/{active,archive/*}/feat-t-*` 目录中的最大值加一。
  - 个人偏好：模板新增 `PREFERENCES.md`，模板与本仓库 `.gitignore` 用 `/PREFERENCES.md` 忽略（个人的、不入库，也就不进状态指纹）；`AGENTS.md` 接手时读、记忆规则里分流。
  - 文档：code-review 模板加「审查范围」；SKILL.md 两句；upgrade.md 删版本说明；模块活文档补「为什么」。
- 改动文件：见各任务。
- 影响与风险：`archive` 变严后，自检任务池一节的归档用例要先让 Spec 过门或改为手动移动；g1/g2 变严后 mk_spec 样例要补「对应验收」；`prefer` 删除后本仓库与模板文档里的引用全部改掉（已 grep：只有 `template/AGENTS.md` 与自检）。

## 2. 任务
- [x] Task 1：门禁 g1/g2 收紧
  - 对应验收：AC-01、AC-02
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`
  - 验证：自检
- [x] Task 2：任务池：归档校验门、删命令改字段、编号避撞
  - 对应验收：AC-03、AC-04、AC-05
  - 涉及文件：`template/scripts/ai-task-pool.sh`、`template/scripts/harness-selftest.sh`、`template/AGENTS.md`
  - 验证：自检
- [x] Task 3：个人偏好文件
  - 对应验收：AC-06
  - 涉及文件：`template/PREFERENCES.md`、`template/.gitignore`、`.gitignore`、`template/AGENTS.md`、`AGENTS.md`
  - 验证：grep 与接入试点
- [x] Task 4：审查模板、接入与升级说明、活文档
  - 对应验收：AC-07、AC-08、AC-09
  - 涉及文件：`template/.agents/skills/code-review.md`、`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`
  - 验证：grep
- [x] Task 5：整体验证与接入试点
  - 对应验收：AC-10
  - 涉及文件：无新增
  - 验证：自检、体积检查、临时目录接入

## 3. 发现但不碰
- `template/scripts/ai-gate.sh` g1 反向核对扫整份 tasks.md，「发现但不碰」里提到别的 AC 编号会被误拒；宜只扫「对应验收」行（审查建议）
- 同文件 g2 目标核对对 tasks.md 全文 grep，WIP 区出现路径也算通过，弱于「涉及文件」（审查建议）
- `template/.agents/skills/upgrade.md` 删版本说明时连带删了「降级：反向执行」，标题与 README 仍写降级（审查建议）
- 模板忽略 `PREFERENCES.md` 没有自检断言（审查建议）
- 任务文件为 CRLF 时字段值带 ``，`- 优先: 是` 会被静默忽略；既有字段同样受影响（审查建议）
- 本机 `process/specs/archive/2026-10/` 下有旧版留下、已被 gitignore 的 `reports/` 日志目录，占用了 feat-t-000032/33；属维护者本机文件，不删。

## 4. WIP 接力区
- 当前任务：无（待审查）
- 已完成：Task 1~5；试点接入通过（新项目自检 69 项全过）
- 正在编辑的文件：无
- 已排除的方案：`.gates` 加哈希签名、钩子守卫（违背不写 CLI / 跨工具取向）
- 下一步：独立审查 g3
