# 任务与接力：feat-t-000040

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000040` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：替换串改成不含 PEM 头的 `[PRIVATE KEY REDACTED]`，匹配规则不动，脱敏范围不变；模板占位行由 `- ` 改为 `- 无`；`upgrade.md` 第 2 步末尾加一句。
- 改动文件：`template/scripts/ai-verify.sh`、`template/process/specs/_templates/tasks.md`、`template/.agents/skills/upgrade.md`。
- 影响与风险：搜索过 `REDACTED`、`PRIVATE KEY`、`发现但不碰`，脚本和自检都不依赖这两处原文。已接入项目下次升级时合并，没有迁移动作；已有 Spec 的 `tasks.md` 不受影响。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：去掉两处钩子冲突写法
  - 对应验收：AC-01、AC-02
  - 涉及文件：`template/scripts/ai-verify.sh`、`template/process/specs/_templates/tasks.md`
  - 验证：运行 AC-01、AC-02 的命令
- [x] Task 2：升级说明加残留文件核对
  - 对应验收：AC-03、AC-04
  - 涉及文件：`template/.agents/skills/upgrade.md`
  - 验证：运行 AC-03 的命令与正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- 无

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无
- 已完成：Task 1、Task 2
- 已排除的方案：只改模式串不改替换串（钩子拦的是替换串里的字面量）
- 下一步：正式验证与独立审查
