# 老项目渐进接入指南（跨 IDE 普通项目文件）

适用：已有代码、CI 和团队约定的项目。以现有可运行系统为基线；只给**接入后的新变更**使用 Spec 与 G1~G7，不为历史提交补造 Spec 或验证记录。

## 1. 只读摸底

1. 记录 Git 分支、HEAD、未提交改动与现有构建/测试/CI 命令；不要清理或覆盖工作区。
2. 读已有 `AGENTS.md` / `CLAUDE.md`、README、构建文件、测试目录和架构索引。按目录与依赖关系列候选模块；目录名不自动等于模块边界。
3. 选一个低风险、边界清楚、能验证的小改动做试点。记录当前完成这类改动的耗时构成：定位、编码、验证、审查、等待；没有基线就标「未知」。
4. 先跑 `bash <脚手架路径>/bin/ai-harness retrofit <项目路径> --dry-run`。它只展示计划，不应写任何目标文件。

## 2. 最小落地

1. 用 `retrofit <项目路径> --skip-doctor` 复制缺失文件；冲突留在 `.ai-harness/suggested/`，逐个合并，不覆盖现有规则。已有未提交改动保持原样。
   `process/task-pool/` 是新需求的轻量入口；已有需求系统继续使用，只在 Spec 的「原始问题 / 原话」保留链接与原意，不复制历史需求池。旧 `docs/INTAKE.md` 可保留历史。
2. `AGENTS.md` 只留项目入口、真实验证命令、接力文件位置和必要禁令；`CLAUDE.md` 可作为薄导入入口。项目文档与 Git 是状态来源。
3. 从 `.ai-harness/suggested/module-candidates.md` 选**一个**真实模块，确认职责、代码路径和公共契约，写一篇活文档并登记 `docs/architecture/00-INDEX.md`。其他候选暂不建空文档。
4. 审核 `.ai-harness/suggested/harness/allowed-write-dirs.txt`；由有权限的人决定是否合并进 `harness/redlines.conf` 并更新基线。不要把目录扫描结果当权限事实。
5. 接入一条能运行的增量检查到 `harness/verify.conf`，沿用现有 CI 的完整测试；`verification.md` 只记录本地增量结论。

## 升级与降级（不提供命令，由项目 AI 照做）

升级和降级是同一套步骤，只是目标版本不同。
1. 先提交项目当前改动；有在途 Spec 先归档，或确认本次变化不影响它。
2. 机制文件是 `AGENTS.md`、`CLAUDE.md`、`.cursorrules`、`scripts/*.sh`、`.agents/skills/*.md`、`process/specs/_templates/*.md`、`process/task-pool/README.md`、`harness/CI.md`、`harness/verify.conf.example`。逐个与目标版本 `template/` 下的同名文件比对：
   - 项目没改过的直接覆盖（以 `.ai-harness/version` 记录版本对应的模板为基线；判断不了就当作改过）；
   - 项目改过的，把新版差异合并进去；
   - 目标版本新增的复制过来；目标版本已删除的删掉，项目改过的先问人。
3. 不动项目状态：`process/` 下的 Spec、任务与度量，`MEMORY.md`，`docs/architecture/`，`harness/verify.conf`。`harness/redlines.conf` 只由人改；新版需要新键或新值时列给人。ignore 文件只替换 `ai-harness managed block` 之间的内容。
4. 按下面的版本说明处理目录与格式变化。
5. 把 `.ai-harness/version` 的 `version=` 改为目标版本，运行 `bash scripts/harness-selftest.sh` 与 `bash scripts/ai-gate.sh status`，通过后提交。

**版本说明**
- 1.x → 2.0：
  - 流程记录迁到 `process/`：用 `git mv` 把 `docs/specs/{_templates,active,archive}` 移到 `process/specs/`，`docs/task-pool` 移到 `process/task-pool`，`docs/metrics.md` 移到 `process/metrics.md`；ignore 文件与项目脚本里的这些旧路径改为新路径；由人把 `redlines.conf` 的 `ALLOWED_WRITE_DIRS` 改为 `process/specs/active/` 后运行 `bash scripts/ai-gate.sh baseline`。
  - 删除 `.ai-harness/manifest.tsv`（不再使用）；旧版的知识卡脚本与指南随模板删除，`.knowledge/` 属项目状态，保留与否由人定。
  - 在途 Spec 的 `acceptance.md` 每项改为以「通过」开头并去掉条件委托字段；`scripts/ai-state-id.sh` 变了，已过 G4 的在途 Spec 重跑正式验证。
- 降级：反向执行目标版本之后各条说明。

## 3. 小范围试点与扩展

1. 对首个真实小需求建 Spec，写清 AC、风险、影响文件与回滚办法，再按 G1~G7 执行。旧代码未覆盖到的模块不要求先补文档。
   先按象限分流：④停在分析移交；①低风险小改动可写单步设计；②③在编码前记录人的风险或架构决定。对旧项目特别核对后台任务、数据同步、配置、权限和跨仓库消费者。
2. 实际运行 `ai-verify.sh --spec <feat> <file>`、`harness-selftest.sh`、`ai-check-bloat.sh` 和既有 CI。确认零检查不会被当作通过、跨 IDE 可通过 `ai-resume.sh owner <feat>` 接力。
3. 只在下一次变更触及新模块时补该模块文档。多 Agent 并行时在各自 `tasks.md` 写清依赖、文件归属和集成检查点；避免并发编辑同一文件。
4. 每次归档只保留当前活文档和可复用结论；历史过程留在归档。发现文档与代码冲突时先核代码，再修文档，不追加第二份真相。

## 4. 每月看是否越用越慢

在 `process/metrics.md` 记录**可比任务**的样本：相同风险级别、相近改动范围和相同模块类型。比较中位数与慢尾（如 P90），并拆开定位/编码/测试/审查/等待时间；同时看返工次数、CI 时长、变更文件数和未归档 Spec 数。样本太少时只写事实，不给趋势结论。

若相近任务持续变慢，先查变更批次是否变大、模块耦合是否增加、测试是否变慢、文档是否失真，再针对瓶颈减法或重构。不要用增加提示词和规则掩盖代码/流程问题，也不要预设脚手架能保证恒定耗时。
