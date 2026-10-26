# 审查：feat-t-000036

- 审查者：subagent/general-purpose
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：89786b782e4c0752b59173d38a194065ed4189c0ba8a0ba518ca8d8f9e123389
- 审查范围：f9fe310...HEAD + 工作区（含未跟踪 verification.md）

## 结论
- 关键问题：0
- 改进建议：2
- 人工决定：不涉及（需人决定：否）
- 决策来源：requirements.md 标明需人决定为否

## 关键问题
无

## 改进建议
- skill/SKILL.md:29 写“脚手架仓库 HEAD 的完整提交号”，未提醒脚手架工作区有未提交改动时 HEAD 与实际装入内容不一致，基线可能不准；可补半句“工作区需干净”（不阻塞）。
- 根目录 harness/redlines.conf:4 仍有 VERIFY_MAX_SECONDS=120，无脚本读取；红线只允许人改，已在 tasks.md「发现但不碰」列出，交维护者决定。

## 证据
- 验证：verification.md result=PASS，state 与本文一致。
- AC-01：grep -rn VERIFY_MAX_SECONDS 排除 process 后仅剩根目录 harness/redlines.conf（不在 template/skill 内）。
- AC-02：skill/SKILL.md 无 version: frontmatter，第 29 行写 commit=；upgrade.md:6、:10 用同一 commit 键取基线并更新，两处自洽；git cat-file -t HEAD 为 commit，git show <提交>:template/<文件> 可取。
- AC-03：.gitignore 无 ai-harness 行；ls .ai-harness 不存在。
- AC-04：由 verification 的验证覆盖；ai-verify.sh 语法检查通过，DUR 仍用于成功/失败输出（:48、:73、:74），无悬空变量引用；ai_config_load 只请求 VERIFY_MAX_ATTEMPTS。
- 文档：ADR-0003 与 install-skill.md 已同步；README、template/AGENTS.md 无残留版本号引用。
