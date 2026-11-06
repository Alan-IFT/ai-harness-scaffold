# 审查：feat-t-000045

- 审查者：独立 subagent / Claude Sonnet 5.5 / 新会话
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：c32d3742a132190ef6aaae8b800b8e831147873a2b407ec53b432f09daac0d6c
- 审查范围：06419cb...HEAD + 工作区（工作区干净）

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：不适用（需人决定：否，按实际改动核对：只改说明文档，同意）
- 决策来源：requirements.md 第 5 行

## 关键问题
无

## 改进建议
1. `README.md:112` 「验收标准无空格」易误读为不能有空格，脚本实际检查的是验收标准表「无空单元格」（`template/scripts/ai-gate.sh:64`）。建议改为「无空单元格」。
2. `README.en.md` 全文 101 行（`wc -l`），AC-05 要求正文不超过 100 行。去掉头部徽章块后正文远低于 100，按字面算属边界，不阻塞；以后加内容就会超。
3. `README.md:162-187` 目录树未列 `.gitignore`、`.gitattributes`（`git ls-tree` 显示它们在 `template/` 下），也没说 `docs/architecture/modules/` 是接入时试点才建，不在模板里。树是「接入后」的结构，不算错，可在注释里一句带过。

## 证据
- 验证：verification.md 的 result: PASS / state: c32d3742...（与上方审查状态一致）
- 脚本表：`template/scripts/*.sh` 的 9 个脚本全在表中，子命令与各脚本用法一致（`ai-task-pool.sh:7-14`、`ai-gate.sh:7-11`、`ai-resume.sh:4`）。
- 配置表：`redlines.conf` 4 个键、`verify.conf` 的 `CUSTOM_CHECK` 全覆盖，默认值 120/150/3/4 与模板一致；「不配置时 g2 过不去」与 `template/harness/verify.conf:2` 一致。
- 三道门描述对照 `ai-gate.sh` 的 ck_g1/g2/g3（行 51-112）：条件均一致；状态指纹对照 `template/scripts/ai-state-id.sh`（全仓、排除 `process/`）一致。
- 设计取舍「七道门约 3500 行、只留误报」对照 ADR-0003 第 16 行一致；CI `windows-latest` 对照 `.github/workflows/selftest.yml` 一致；根 `harness/`、`docs/architecture/decisions/ADR-0003-*` 存在。
- AC-04：已在 GitHub 上打开 README.md 与 README.en.md 两个页面，每页 2 张 Mermaid 图都渲染为 viewscreen mermaid iframe（高度 749/989 与 773/1061 px），页面无「Unable to render」或「Parse error」文本；这是 DOM 检查，没有逐图肉眼复核截图，实现者另有截图记录。已关闭我打开的页面。
- AC-01：README.md 九个二级标题加「目录」齐全，目录锚点与标题一致。
- AC-06 隐私：对 README、AGENTS.md、guidance.md 以及 process 新增内容搜索本机路径和邮箱，只有公开 GitHub 链接，无非公开项目名、本机路径、私人邮箱。
- 范围：除 README、根 AGENTS.md 一行、guidance.md 一行外，未改脚本、模板和 skill，符合需求「不做」项。
