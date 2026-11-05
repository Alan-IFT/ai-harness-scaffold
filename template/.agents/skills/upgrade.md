# 脚手架升级与降级（由项目 AI 照做，没有命令）

升级和降级是同一套步骤，只是目标版本不同。
1. 先提交项目当前改动；有在途 Spec 先归档，或确认本次变化不影响它。
2. 目标版本是脚手架仓库的某个提交，默认 HEAD。机制文件是 `AGENTS.md`、`CLAUDE.md`、`scripts/*.sh`、`.agents/skills/*.md`、`process/specs/_templates/*.md`。逐个与目标版本 `template/` 下的同名文件比对：
   - 项目没改过的直接覆盖（基线是 `git -C <脚手架仓库> show <.ai-harness/version 的 commit>:template/<文件>`；取不到就当作改过）；
   - 项目改过的，把新版差异合并进去；
   - 目标版本新增的复制过来；目标版本已删除的删掉，项目改过的先问人。
   - 对照模板全部历史（`git -C <脚手架仓库> log --name-only --format= -- template`）列出项目里仍残留的已退役文件，交人决定。
3. 不动项目状态：`process/` 下的 Spec 与任务，`MEMORY.md`，`PREFERENCES.md`，`docs/architecture/`，`harness/verify.conf`。`harness/redlines.conf` 只由人改；新版需要新键或新值时列给人。`.gitignore` 只补缺的行。
4. 把 `.ai-harness/version` 的 `commit=` 改为目标提交，运行 `bash scripts/harness-selftest.sh` 与 `bash scripts/ai-gate.sh status`，通过后提交。
