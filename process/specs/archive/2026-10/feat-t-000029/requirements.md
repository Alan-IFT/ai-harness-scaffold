# 需求：feat-t-000029

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000029.md`（原始需求与更新）
- 原始问题 / 原话：现在我想把 https://github.com/multica-ai/andrej-karpathy-skills 加进来，作为每个AI干活的指导；原文都吸收吧，重复的地方以karpathy的为准
- 需人决定：否（吸收范围与冲突规则维护者已在对话中定下，只改指南文字）

## 1. 要做什么
- 做什么：把 Karpathy 准则 CLAUDE.md 原文（维护者对话中粘贴的版本）完整译成中文写进 `template/AGENTS.md` §3，删掉与之重复的旧条目。
- 为谁做：接入脚手架后每个干活的 AI。
- 不做：不引入插件、Cursor 规则、EXAMPLES.md 等其他文件；不动 §3 以外与准则无关的条目（命令速查等删减另行决定）。

## 2. 验收标准
| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | §3 含原文全部内容：开头取舍说明、四条原则（标题句与每条要点、自问句、检验标准、三个目标示例、计划格式、成功标准说明）、结尾生效标志 | 对照原文逐条阅读 `template/AGENTS.md` §3 |
| AC-02 | 旧的「简单优先」「范围纪律」「关键路径先测」三条已删除，「停下等人」等流程条目保留 | `grep -c "范围纪律\|关键路径先测" template/AGENTS.md` 输出 0 |
| AC-03 | 审查指南把「每一行改动都能直接对应到需求」列为需求检查项；README 注明出处与 MIT 许可 | `grep` 两个文件可见 |
| AC-04 | 自检与体积检查通过 | `bash scripts/harness-selftest.sh`、`bash template/scripts/ai-check-bloat.sh` |
