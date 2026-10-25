# 脚手架升级与降级（由项目 AI 照做，没有命令）

升级和降级是同一套步骤，只是目标版本不同。
1. 先提交项目当前改动；有在途 Spec 先归档，或确认本次变化不影响它。
2. 机制文件是 `AGENTS.md`、`CLAUDE.md`、`scripts/*.sh`、`.agents/skills/*.md`、`process/specs/_templates/*.md`。逐个与目标版本 `template/` 下的同名文件比对：
   - 项目没改过的直接覆盖（以 `.ai-harness/version` 记录版本对应的模板为基线；判断不了就当作改过）；
   - 项目改过的，把新版差异合并进去；
   - 目标版本新增的复制过来；目标版本已删除的删掉，项目改过的先问人。
3. 不动项目状态：`process/` 下的 Spec 与任务，`MEMORY.md`，`docs/architecture/`，`harness/verify.conf`。`harness/redlines.conf` 只由人改；新版需要新键或新值时列给人。`.gitignore` 只补缺的行。
4. 按下面的版本说明处理目录与格式变化。
5. 把 `.ai-harness/version` 的 `version=` 改为目标版本，运行 `bash scripts/harness-selftest.sh` 与 `bash scripts/ai-gate.sh status`，通过后提交。

## 版本说明
- 1.x → 2.0：
  - 流程记录迁到 `process/`：用 `git mv` 把 `docs/specs/{_templates,active,archive}` 移到 `process/specs/`，`docs/task-pool` 移到 `process/task-pool`，项目脚本里的旧路径改为新路径。
  - 门禁从 G1~G7 改为三道门：在途 Spec 先按旧版收尾归档再升级；`design.md`、`acceptance.md` 不再使用。
  - 删除不再使用的文件：`.ai-harness/manifest.tsv`、`.cursorrules`、`.cursorignore`、`.claudeignore`、`harness/CI.md`、`harness/verify.conf.example`、`process/task-pool/README.md`、旧版知识卡脚本与指南；`.knowledge/` 属项目状态，保留与否由人定。
  - `harness/redlines.conf` 只保留模板里的 5 个键，其余键由人删掉；`harness/.redlines.baseline`、`process/metrics.md`、`docs/metrics.md` 与 Spec 下的 `reports/` 不再使用，可删除。
- 降级：反向执行目标版本之后各条说明。
