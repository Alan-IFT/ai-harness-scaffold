# 可选 CI 接入清单

本文件是跨 CI 平台的命令清单，不绑定 GitHub、GitLab 或某个 IDE。项目接入 CI 时，在自己的流水线中执行：

```bash
bash scripts/harness-selftest.sh
bash scripts/ai-check-bloat.sh
```

再按项目技术栈加入构建、单元测试、集成或冒烟测试、安全扫描；覆盖率等阈值由项目在 CI 里自己实现。CI 应把测试执行数、失败数和对应提交写进构建结果，零测试时不得显示「测试通过」。`verification.md` 是本地增量检查的可交接摘要，不能代替完整回归。

`review.md` 中的「人工决定」是人工决策记录。需要强制审批、保护分支或限制发布权限时，在项目使用的代码托管和运行环境中配置。
