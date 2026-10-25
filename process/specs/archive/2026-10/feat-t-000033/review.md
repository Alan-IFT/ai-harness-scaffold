# 代码审查报告 (Code Review): feat-t-000033

我没写过这段代码，只依据下面产物判断。

- **审查者**：独立 subagent（Claude Opus 5.5，新上下文）
- **未参与实现**：是
- **审查时间**：2026-10-25
- **审查范围**：`git diff 254adf3...HEAD`（`bin/ai-harness`、`template/scripts/*.sh`、`tests/cli-upgrade.sh`、`template/` 指南与模板、`README.md`、`docs/architecture/**`）+ design.md §4 文件清单；`process/` 下纯重命名用 `git diff -M --diff-filter=R --summary` 核对为 100% 相同（仅 `.gates`、`requirements.md`、`tasks.md` 及三个设计模板有内容变化）
- **CR 轮次**：1 / 4
- 审查状态：63820c0e14995db88bdbdc4ea97b1f57229cc772eb610aba7cc9e3bb97035ea9

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：4
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无。逐项核对约束：
- 根目录 `harness/redlines.conf` 未改：`git diff --stat 254adf3 -- harness/redlines.conf` 为空。
- 拒绝先于写入：`bin/ai-harness` `migrate_process_layout` 先判 `process/` 存在（含符号链接）、再判活跃 Spec，之后才 `mkdir`；`cmd_upgrade` 在调用前只有 `say`。`tests/cli-upgrade.sh` 的 `expect_refusal` 比对前后快照。
- dry-run 只读：`stage_legacy_refs` 在 DRY 下只 `cmp`，不 `mktemp`；`migrate_process_layout` DRY 分支无写入；用例比对快照。
- 版本 `VERSION="2.0.0"`；无反向迁移命令（回滚仅文档步骤）；下游红线只经 `legacy_hints` 提示。
- `git mv` / `mv` 分流与逆序回滚：`move_item` / `undo_moves` 的 `MOVED` 头插、`from/to` 对调正确。
- 实跑：`bash tests/cli-upgrade.sh` → `cli-upgrade: PASS`；`bash scripts/harness-selftest.sh` → 214 项断言失败 0；`bash -n bin/ai-harness` 通过；`ai-state-id.sh` 34 行（< 145）；AC-01 的 grep 在 template/scripts/README/AGENTS 只剩迁移相关命中。
- 另做一次临时目录实测（旧布局 + `active/stray.txt`）：迁移成功、再次 upgrade 无冲突。

## 改进建议（非阻塞，"改善即批准"）
1. `bin/ai-harness:392-399`（`commit_legacy_refs`）：多文件落盘中途失败时，已 `mv -f` 的文件保持新前缀，而 `undo_moves` 把目录移回旧位置，出现短暂不一致。重跑 upgrade 会再次判定旧布局并幂等改写，可自愈，但失败提示可补一句「重跑 upgrade 即可」。
2. `bin/ai-harness:326`/`stage_legacy_refs` 用 `mktemp` 生成临时文件后 `mv -f` 覆盖，在 POSIX 上会把 ignore 文件与 manifest 权限变成 0600（原 manifest 临时文件写法同样如此）。建议落盘前对齐原文件模式，避免 CI 容器多用户读取失败。
3. ERR-01 原文是「`active/` 下有目录」即拒绝，实现豁免隐藏目录（`! -name '.*'`，对应 `ai-new-spec.sh` 的 `.feat.tmp.*` 残留）。已在 `retrofit-legacy.md:26` 写明，但 requirements.md ERR-01 未同步措辞，建议补「隐藏临时目录除外」以免与原文歧义。
4. `ai_require_process_layout` / `legacy_layout` 判据（四个标记）在两处各写一份，改动时需同步；已有注释互指，可后续加一条自检断言两者一致。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用（本地 CLI/脚本，无身份概念） | — |
| 鉴权入口 | 不适用 | — |
| SQL 参数化 | 不适用（无数据库） | — |
| 无敏感信息硬编码 | ✅ | diff 无密钥/token/内网地址 |
| 入参边界校验 | ✅ | `bin/ai-harness` `migrate_process_layout` 对每个迁移项与 `process` 做 `safe_path`、拒绝符号链接；`ai-verify.sh:47` 拒绝 `process/*` 目标 |
| 资源归属校验 | 不适用 | 迁移不跟随符号链接，不越出目标根 |

## 需求追溯（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01~05、ERR-01/02 与 AC-01~06 均能在 diff 与自检/回归中找到对应；§2.3 两条锚点（拒绝先于任何写入、2.0.0 与 R1 同版发布）满足。无超纲行为；未实现反向迁移与 `docs/INTAKE.md` 迁移，符合 Non-Goals。
- AI 协作文件审查：本次 diff 含 `template/AGENTS.md`、`template/.agents/skills/{archive-spec,code-review,new-spec,retrofit-legacy}.md`、根 `AGENTS.md`、`MEMORY.md`；仅路径与指纹说明改动，未见矛盾或私有调试信息；`retrofit-legacy.md` 的拒绝条件、回滚步骤与 CLI 行为一致。
- 审查范围限制：未在真实 Linux/macOS 上验证文件权限（建议 2）；未逐一审阅 `process/specs/archive/**` 中约 200 个纯重命名文件的正文，仅核对相似度 100%。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash tests/cli-upgrade.sh` → `cli-upgrade: PASS`
- `bash scripts/harness-selftest.sh` → 214 项断言，失败 0
- `bash scripts/ai-verify.sh --spec feat-t-000033 template/scripts/ai-state-id.sh` → `verification.md`：result PASS / checks 1 / state 63820c0e…

knowledge_feedback: 无
