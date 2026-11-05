# 脚手架升级与降级（由项目 AI 照做，没有命令）

升级和降级是同一套步骤，只是目标版本不同。
脚手架仓库：人给了本机路径就用它；否则把 `https://github.com/Alan-IFT/ai-harness-scaffold.git` 完整克隆到临时目录，不要浅克隆，结束前删除。
1. 先提交项目当前改动；有在途 Spec 先归档，或确认本次变化不影响它。
2. 选目标版本：人点名了版本就用它；否则先 `git -C <脚手架仓库> fetch --tags`（失败就停下问人），取 `git -C <脚手架仓库> tag --sort=-v:refname` 的第一个；没有 tag 才用 HEAD。用 `git -C <脚手架仓库> rev-parse <版本>^{commit}` 得到目标提交。再读目标版本的本说明（`git -C <脚手架仓库> show <目标提交>:template/.agents/skills/upgrade.md`），与这里不同时按它做；取不到就按这里继续。
3. 防降级：人没点名版本，且 `git -C <脚手架仓库> merge-base --is-ancestor <.ai-harness/version 的 commit> <目标提交>` 不成立时，停下问人：可能是把升级做成了降级，也可能是旧提交已取不到。
4. 比对机制文件：`AGENTS.md`、`CLAUDE.md`、`.ai-harness/LICENSE.md`、`scripts/*.sh`、`.agents/skills/*.md`、`process/specs/_templates/*.md`。逐个与目标版本 `template/` 下的同名文件比对：
   - 项目没改过的直接覆盖（基线是 `git -C <脚手架仓库> show <.ai-harness/version 的 commit>:template/<文件>`；取不到就当作改过）；
   - 项目改过的，把新版差异合并进去；
   - 目标版本新增的复制过来；目标版本已删除的删掉，项目改过的先问人。
   - 对照模板全部历史（`git -C <脚手架仓库> log --name-only --format= -- template`）列出项目里仍残留的已退役文件，交人决定。
5. 不动项目状态：`process/` 下的 Spec 与任务，`MEMORY.md`，`PREFERENCES.md`，`docs/architecture/`，`harness/verify.conf`。`harness/redlines.conf` 只由人改；用 `git -C <脚手架仓库> diff <.ai-harness/version 的 commit> <目标提交> -- template/harness/redlines.conf` 查新版的新键或新值，有差异就列给人。`.gitignore` 和 `.gitattributes` 只补缺的行。
6. 复议验证命令：核对 `harness/verify.conf` 的 `CUSTOM_CHECK`。有测试却只跑 lint 或类型检查的，不能证明行为，连同建议的命令交人决定，不要自己改。
7. 把 `.ai-harness/version` 的 `commit=` 改为目标提交，运行 `bash scripts/harness-selftest.sh` 与 `bash scripts/ai-gate.sh status`，通过后提交。
