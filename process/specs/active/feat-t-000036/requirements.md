# 需求：feat-t-000036

- 创建时间：2026-10-25
- **需求来源**: `process/task-pool/T-000036.md`（原始需求与更新）
- 原始问题 / 原话：把应该删除的删除掉，不要让脚手架变得臃肿、累赘，但不要删除好用的和必要的功能；其他的你来决策吧，拿不准的，就交给我来决策，但要给我讲清楚详细情况，方便我做决策
- 需人决定：否，只删无人读取、永远不更新的内容；红线配置、本机历史文件与个人偏好去向列给人决定，本 Spec 不碰

## 1. 要做什么
- 做什么：删除只告警、无实际约束力的验证秒级预算；把接入记录从永远不更新的版本号换成脚手架提交号，并删掉 frontmatter 版本号；删掉本仓库根目录无人读取的 `.ai-harness/` 及其忽略行。
- 为谁做：维护者与接入项目的 AI，少维护一个会过期的数字。
- 不做：不改根目录 `harness/redlines.conf`（只允许人改）；不删本机旧验证日志与外部工具锁文件；不处理 T-000028。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `template/` 与 `skill/` 下不再出现 `VERIFY_MAX_SECONDS` | `grep -rn VERIFY_MAX_SECONDS template skill` 无输出 |
| AC-02 | `skill/SKILL.md` 无 `version:` frontmatter，收尾写 `commit=<脚手架提交>`；`upgrade.md` 以该提交取基线模板并在升级后更新它 | 读两份文件 |
| AC-03 | 根目录 `.gitignore` 无 `.ai-harness/` 行，本机 `.ai-harness/` 已删 | `grep -n ai-harness .gitignore` 无输出；`ls .ai-harness` 报不存在 |
| AC-04 | 自检全部通过 | `bash scripts/harness-selftest.sh` |
