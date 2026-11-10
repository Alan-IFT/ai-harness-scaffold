# 需求：feat-t-000046

- 创建时间：2026-11-09
- **需求来源**: `process/task-pool/T-000046.md`（原始需求与更新）
- 原始问题 / 原话：做，先做第一、二批（维护者 2026-11-09 对脚手架整体分析的答复；本条是第一批：任务池提速，做法与实测数据见任务文件）。
- 需人决定：否。做法（归档时任务文件随 Spec 移走）维护者已在对话中选定；任务文件只移动不删除，Git 可还原；不改门禁标准，不涉及权限、发布或不可逆操作。发新版本不在本需求内，发之前另外问维护者。

## 1. 要做什么
- 做什么：归档时把关联的任务文件随 Spec 移进归档目录，任务池只留没做完的；去掉任务池脚本里逐文件起进程的 `basename` 和查归档目录的 `find`，让耗时不再随历史任务数增长。
- 为谁做：每次接手都要运行 `ai-resume.sh owner`（内部调 `next`）的 AI 工具，以及等它出结果的维护者。
- 不做：不改任务文件格式和 `关联 Spec` 字段；不改 `start-next`、`intake` 的行为；不重写 `field()`；不处理归档 Spec 里 `需求来源` 的旧路径（任务文件就在同一目录）；不打 tag；不改接入项目。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `archive <feat>` 成功后，池里 `关联 Spec` 等于该 feat 的任务文件位于归档目录 `process/specs/archive/YYYY-MM/<feat>/`，`process/task-pool/` 里不再有它 | 自检断言「任务文件随 Spec 归档」通过 |
| AC-02 | 任务文件随 Spec 归档后，`add` 不重用它的编号，Spec 目录名不是 `feat-t-*` 时也一样 | 自检断言「归档带走的任务编号不重用」通过（任务关联到名为 `t-arch` 的 Spec，归档后 `add` 得到下一个编号） |
| AC-03 | `list` 对关联的 Spec 不在 `process/specs/active/` 的任务显示「关联异常」，不再显示「已归档」 | 自检断言「Spec 不在 active 的任务标为关联异常」通过；`grep -c '已归档' template/scripts/ai-task-pool.sh` 输出 1（只剩 `archive` 的成功提示） |
| AC-04 | `template/scripts/ai-task-pool.sh` 不再调用 `basename` 和 `find` | `grep -cE 'basename|find ' template/scripts/ai-task-pool.sh` 输出 0 |
| AC-05 | 300 个已随 Spec 归档的任务加 4 个待办时，`next`、`list`、`add` 在本机 Git Bash 下各不超过 2 秒 | 临时目录实测的三个耗时记入 tasks.md 的 WIP 区 |
| AC-06 | `archive-spec.md` 写明任务文件随 Spec 归档；`upgrade.md` 写明怎么处理池里显示「关联异常」的遗留任务文件；README 目录树与活文档 `template-mechanism.md` 同步 | `grep -n '随 Spec' template/.agents/skills/archive-spec.md docs/architecture/modules/template-mechanism.md README.md` 各命中；`grep -n '关联异常' template/.agents/skills/upgrade.md` 命中 |
| AC-07 | 本仓库池里已归档的 16 个任务文件都在各自的归档 Spec 目录里 | `ls process/specs/archive/*/*/T-*.md \| wc -l` 输出 16；`bash scripts/ai-task-pool.sh list` 不含「关联异常」 |
| AC-08 | 自检全部通过，正式验证通过 | `bash scripts/harness-selftest.sh` 失败 0 项；`bash scripts/ai-verify.sh --spec feat-t-000046 template/scripts/ai-task-pool.sh` 为 PASS |
