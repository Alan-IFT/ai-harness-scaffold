# 可选 CI 接入清单

本文件是跨 CI 平台的命令清单，不绑定 GitHub、GitLab 或某个 IDE。项目接入 CI 时，在自己的流水线中执行：

```bash
bash scripts/harness-selftest.sh
bash scripts/ai-check-bloat.sh
bash scripts/ai-knowledge.sh check
```

再按项目技术栈加入构建、单元测试、集成或冒烟测试、安全扫描。若采用 `harness/redlines.conf` 中的 `COVERAGE_MIN`、`MUTATION_SCORE_MIN`，须在项目 CI 中明确读取并裁决；仅填写阈值不会自动形成门禁。

CI 应把测试执行数、失败数和对应提交写进构建结果，零测试时不得把“未执行”显示为“测试通过”。`verification.md` 是本地增量检查的可交接摘要，不能代替完整回归结果。

G6 的 `acceptance.md` 是人工决策记录。需要强制审批、保护分支或限制发布权限时，在项目使用的代码托管和运行环境中配置。
