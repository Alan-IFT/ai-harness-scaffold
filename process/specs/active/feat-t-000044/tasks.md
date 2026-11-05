# 任务与接力：feat-t-000044

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000044` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：README 一句话让 AI 自己克隆，`SKILL.md` 本来就按「本文件所在目录的上一级」定位脚手架，也已能判断新项目、老项目和已接入，所以不需要新机制。只补两处：防浅克隆（否则取不到 tag，会静默退回 HEAD）和用完删除。`upgrade.md` 写上仓库地址，项目 AI 不再需要别人告诉它脚手架在哪。
- 改动文件：`README.md`、`README.en.md`、`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`。
- 影响与风险：AI 需要能访问 GitHub，写进前置条件；不能访问时用户给本机路径。地址写死后，fork 的用户要改这一行或给本机路径。手里还是旧 `upgrade.md` 的项目没有地址，要用 README 那句话升级一次。不写兼容代码。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：说明与 README
  - 对应验收：AC-01、AC-02、AC-03、AC-07
  - 涉及文件：`README.md`、`README.en.md`、`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`
  - 验证：运行 AC-01~03 的命令；正式验证
- [ ] Task 2：没看过讨论的 AI 实测
  - 对应验收：AC-04、AC-05、AC-06
  - 涉及文件：`README.md`
  - 验证：推送后用新上下文在临时目录实测，并逐项核对产物

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- 无

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 2
- 已完成：Task 1
- 已排除的方案：安装脚本（ADR-0003 不写 CLI）；把克隆放在固定用户目录（要多管一份长期状态，临时克隆用完即删更简单）
- 下一步：推送后用新上下文实测
