# 任务与接力：feat-t-000043

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000043` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：只给 `upgrade.md` 加三句，步骤序号不变；`docs/architecture/modules/install-skill.md` 补上为什么项目里的说明也要读目标版本。
- 改动文件：`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`。
- 影响与风险：第一句只对已带上新版说明的项目生效，手里还是旧说明的项目要先经 `skill/SKILL.md` 升级一次，这一点写进活文档。搜索过 `.gitattributes`，现行文档没有其他处理规则，不冲突。第 3 步已让取不到基线的情况先停下问人，所以第 5 步的 `git diff` 只在人点名版本时才可能取不到基线，那时会报错，由 AI 告诉人。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [ ] Task 1：升级说明加三句
  - 对应验收：AC-01、AC-02、AC-03、AC-04
  - 涉及文件：`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`
  - 验证：运行 AC-01~03 的命令；正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- 无

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 1
- 已完成：需求与方案
- 已排除的方案：把第一句写进 `template/AGENTS.md`（规则入口已很长，这句只在升级时才需要）
- 下一步：过 g1 后改说明
