# 任务与接力：feat-t-000036

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000036` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：只删两类东西——没有约束力的配置（秒级预算只告警，连续失败上限已管住循环成本）和永远不会被更新的记录（版本号 2.0.0 在模板改动多次后从未变过，升级时拿它找不到基线；改记脚手架提交号，`git show <提交>:template/<文件>` 能直接取到基线）。
- 改动文件：`template/scripts/ai-verify.sh`、`template/harness/redlines.conf`、`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`.gitignore`、`docs/architecture/modules/install-skill.md`、`docs/architecture/decisions/ADR-0003-three-gates-no-compat-code.md`
- 影响与风险：`ai_config_load` 只校验请求的键，根目录红线多出的 `VERIFY_MAX_SECONDS` 不影响运行；selftest 未引用该键。`.ai-harness/version` 只有 SKILL.md 与 upgrade.md 读，没有脚本读。没有存量用户，无需迁移说明。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：删除验证秒级预算
  - 对应验收：AC-01、AC-04
  - 涉及文件：`template/scripts/ai-verify.sh`、`template/harness/redlines.conf`、`docs/architecture/decisions/ADR-0003-three-gates-no-compat-code.md`
  - 验证：grep 无输出，自检通过
- [x] Task 2：接入记录改记脚手架提交号
  - 对应验收：AC-02
  - 涉及文件：`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`
  - 验证：按 SKILL.md 在临时目录接入一次，自检通过
- [x] Task 3：删除本仓库无人读取的 `.ai-harness/`
  - 对应验收：AC-03
  - 涉及文件：`.gitignore`
  - 验证：grep 与 ls

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- 根目录 `harness/redlines.conf` 仍有 `VERIFY_MAX_SECONDS=120`，无脚本读取；红线只允许人改，交维护者决定是否删。
- 本机 `process/specs/archive/2026-10/` 下 25 个只含 `reports/` 的旧版目录（被 gitignore，约 1.2MB）；删后可去掉 `.gitignore` 的 `reports/` 行，交维护者决定。
- 本机 `.dsh-ops-update-*.lock` 文件来自外部工具，`.gitignore` 对应行保留。
- T-000028（暂缓）的个人偏好去向需维护者决定。
- `skill/SKILL.md:29` 记 HEAD 提交号时未提醒脚手架工作区需干净，否则提交号与装入内容可能不一致（审查建议）。

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：全部完成，待验证与审查
- 已完成：Task 1（df43759）、Task 2、Task 3；临时目录试点接入通过（72 项断言），git show 基线取回一致
- 正在编辑的文件：
- 已排除的方案：保留 ADR 编号（改名只带来引用改动）
- 下一步：
