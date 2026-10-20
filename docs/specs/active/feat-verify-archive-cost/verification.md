# 增量验证摘要（随项目文档和 Git 交接）

- spec: feat-verify-archive-cost
- target: template/scripts/ai-verify.sh
- result: PASS
- checks: 1
- state: 2f25107fc58360d0461b0bf9bfb726db46ed0d2dbe24683fce4f000f1de7da94
- command: bash scripts/ai-verify.sh --spec feat-verify-archive-cost template/scripts/ai-verify.sh
- verified_at_utc: 2026-10-20T17:39:49Z

详细输出仅在本地 reports/；代码内容或 Git 暂存状态变化后重新验证，同一索引内容提交后仍有效。

## 本 Spec 的性能与回归证据

- 基线：同一 Windows + Git Bash 环境以临时计时副本运行 `template/scripts/harness-selftest.sh`，12 段总计约 140 秒，121/121；其中第 2 段约 27 秒、第 3 段约 64 秒、第 4 段约 17 秒。
- 试验：仅调整 G6 材料检查顺序并增加两条必要反例，同样分段计时一次，约 139 秒，123/123；第 3 段约 61 秒。检查数不同且仅各运行一次，不能推断稳定净收益；试验代码及反例已撤回。
- 最终：`bash scripts/ai-verify.sh --spec feat-verify-archive-cost template/scripts/ai-verify.sh` → PASS，完整自检 126/126、失败 0，正式检查 145 秒；120 秒提醒线仍只告警。日志仅在本机 `reports/verify-20261020-103949-1012.log`。
- 最终新增断言覆盖已归档 Spec ID 不可重用、正式验证拒绝 Spec/metrics 流程目标、路径别名拒绝；原 121 项均保留。
