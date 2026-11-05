# 任务与接力：feat-t-000042

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000042` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：断言放进自检第 7 节，配一个会失败的 `CUSTOM_CHECK`，让私钥头走真实的失败输出路径。测试数据把 PEM 头拆开拼接，否则自检文件本身又会被 detect-private-key 拦下。`upgrade.md` 把第 2 步拆开，并新增一步复议验证命令，步骤序号顺延。
- 改动文件：`template/scripts/harness-selftest.sh`、`template/.agents/skills/upgrade.md`、`skill/SKILL.md`、`docs/architecture/modules/install-skill.md`。
- 影响与风险：搜索过「第 2 步」与 `upgrade.md` 的引用，现行文档只按文件名引用，序号顺延不影响它们。新断言用单独的 Spec 目录，不影响第 7 节的连续失败计数。`harness/verify.conf` 仍属项目状态，新步骤只提示不修改。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：私钥脱敏自检断言
  - 对应验收：AC-01
  - 涉及文件：`template/scripts/harness-selftest.sh`
  - 验证：运行自检；在临时副本里删掉规则确认自检失败
- [x] Task 2：升级与接入说明
  - 对应验收：AC-02、AC-03、AC-04、AC-05
  - 涉及文件：`template/.agents/skills/upgrade.md`、`skill/SKILL.md`、`docs/architecture/modules/install-skill.md`
  - 验证：运行 AC-02~04 的命令；在临时目录实际接入一次；正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/AGENTS.md` / 接入项目的 AI 平时读项目里那份旧 `upgrade.md`，不经过 `SKILL.md`，同样可能照旧说明升级新版本 / 改进建议，维护者确认后再收录

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 1
- 已完成：需求与方案
- 已排除的方案：直接单测 `redact` 函数（脚本被 source 时会执行主流程，端到端更贴近真实路径）
- 下一步：过 g1 后从 Task 1 开始
