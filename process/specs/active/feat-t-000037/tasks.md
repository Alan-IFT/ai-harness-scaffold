# 任务与接力：feat-t-000037

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000037` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：通用偏好放用户目录 `~/.ai-harness/PREFERENCES.md`（Windows 即 `%USERPROFILE%\.ai-harness\`），任何能读 `AGENTS.md` 的工具照规则去读，不依赖宿主的注入机制；与项目已有的 `.ai-harness/` 同名，一看就知道属于脚手架。项目根 `PREFERENCES.md` 保留给只对本项目生效的个人习惯，冲突时项目优先、项目约定再优先。只改说明，不加脚本。
- 改动文件：`template/AGENTS.md`、`template/PREFERENCES.md`、`skill/SKILL.md`、`README.md`、`AGENTS.md`、`docs/architecture/modules/guidance.md`
- 影响与风险：文件在仓库外，不进状态指纹，改偏好不会让验证过期；不存在时跳过，已接入项目无需迁移。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：模板与接入说明写明通用偏好位置
  - 对应验收：AC-01、AC-02、AC-04
  - 涉及文件：`template/AGENTS.md`、`template/PREFERENCES.md`、`skill/SKILL.md`、`README.md`
  - 验证：自检与体积检查
- [x] Task 2：本仓库自用入口与活文档同步
  - 对应验收：AC-03
  - 涉及文件：`AGENTS.md`、`docs/architecture/modules/guidance.md`
  - 验证：读文件

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- T-000028 的偏好原文可由维护者确认后搬进 `~/.ai-harness/PREFERENCES.md`，与 AGENTS.md 重复的工程原则建议删去。

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：全部完成，待验证与审查
- 已完成：
- 正在编辑的文件：
- 已排除的方案：脚手架仓库内放偏好（目标项目不知道脚手架路径）；宿主各自的用户级配置（绑定宿主、要维护多份）
- 下一步：
