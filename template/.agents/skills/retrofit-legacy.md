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

已安装项目后续获取新版脚手架时，运行 `bash <脚手架路径>/bin/ai-harness upgrade <项目路径> --dry-run` 查看计划，再运行 `upgrade <项目路径>`。安装基线记录在 `.ai-harness/manifest.tsv`；未改过的机制文件自动更新，缺失文件自动补齐。项目状态与红线不自动替换。冲突时保留原文件并输出 `.ai-harness/suggested/` 建议文件；合并一处后用 `upgrade <项目路径> --accept-custom <相对路径>` 确认其当前定制基线。旧安装若无 manifest，已有不同内容均作为冲突处理。模板已删除的托管文件（如旧版的知识卡脚本与指南）：未改动的随升级删除；本地改过或经 `--accept-custom` 定制的保留、列出并以非零退出提示人工处理，此后归项目所有，再次升级不再报告。`.knowledge/` 属项目状态，不自动删除。在途 Spec 的 `acceptance.md` 须改为每项以「通过」开头，并去掉条件委托字段，否则 G6 会拒绝。升级会改动 `scripts/ai-state-id.sh`，已过 G4 的在途 Spec 须重跑正式验证再继续。

**从 1.x 升级到 2.0（流程记录迁入 `process/`）**：
- 迁移内容：`upgrade` 把 `docs/specs/` 下的 `_templates`、`active`、`archive` 移到 `process/specs/`，把 `docs/task-pool/` 移到 `process/task-pool/`，把 `docs/metrics.md` 移到 `process/metrics.md`。Git 已跟踪的用 `git mv`（重命名会暂存），其余用 `mv`。`docs/specs/` 下项目自有的文件留在原处。
- 同步改写：`.ai-harness/manifest.tsv` 的路径列，以及 ignore 文件 managed block 中的旧路径。
- 拒绝条件：`docs/specs/active/` 下有在途 Spec（隐藏的 `.*.tmp.*` 临时目录除外）或已存在 `process/` 时拒绝，不写任何文件。先归档在途 Spec；`process/` 已存在时人工核对后合并或删除其中一份。
- `--dry-run`：只列迁移计划，迁移完成后再预演一次才能看到托管文件差异。
- 中断恢复：迁移在移动目录后中断时，再次 `upgrade` 会补齐 manifest 与 ignore 的改写。
- 需人工处理：`harness/redlines.conf` 不自动修改；若 `ALLOWED_WRITE_DIRS` 含 `docs/specs/active/`，人工改为 `process/specs/active/` 后运行 `bash scripts/ai-gate.sh baseline`。CI 或项目脚本若引用旧路径，自行改为 `process/`。迁移后提交这次重命名。
- 新版脚本在旧布局上会拒绝运行并提示 upgrade。
- 回滚：没有反向命令。重新使用 1.x 版 CLI 与脚本，`git mv process/specs/<子目录> docs/specs/<子目录>`、`git mv process/task-pool docs/task-pool`、`git mv process/metrics.md docs/metrics.md`，再把 manifest 第 3 列与 ignore managed block 中的 `process/` 前缀改回 `docs/`。

## 3. 小范围试点与扩展

1. 对首个真实小需求建 Spec，写清 AC、风险、影响文件与回滚办法，再按 G1~G7 执行。旧代码未覆盖到的模块不要求先补文档。
   先按象限分流：④停在分析移交；①低风险小改动可写单步设计；②③在编码前记录人的风险或架构决定。对旧项目特别核对后台任务、数据同步、配置、权限和跨仓库消费者。
2. 实际运行 `ai-verify.sh --spec <feat> <file>`、`harness-selftest.sh`、`ai-check-bloat.sh` 和既有 CI。确认零检查不会被当作通过、跨 IDE 可通过 `ai-resume.sh owner <feat>` 接力。
3. 只在下一次变更触及新模块时补该模块文档。多 Agent 并行时在各自 `tasks.md` 写清依赖、文件归属和集成检查点；避免并发编辑同一文件。
4. 每次归档只保留当前活文档和可复用结论；历史过程留在归档。发现文档与代码冲突时先核代码，再修文档，不追加第二份真相。

## 4. 每月看是否越用越慢

在 `process/metrics.md` 记录**可比任务**的样本：相同风险级别、相近改动范围和相同模块类型。比较中位数与慢尾（如 P90），并拆开定位/编码/测试/审查/等待时间；同时看返工次数、CI 时长、变更文件数和未归档 Spec 数。样本太少时只写事实，不给趋势结论。

若相近任务持续变慢，先查变更批次是否变大、模块耦合是否增加、测试是否变慢、文档是否失真，再针对瓶颈减法或重构。不要用增加提示词和规则掩盖代码/流程问题，也不要预设脚手架能保证恒定耗时。
