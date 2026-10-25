# CLI 与安装

- **职责**：`bin/ai-harness` 负责初始化、老项目接入、安全升级、冲突隔离、候选目录扫描、体检，以及向 Codex/Claude Code 安装指向共享技能的薄入口。
- **边界**：目标项目的模块边界、公共契约和红线必须基于证据确认；目录扫描只给候选。技能安装只更新宿主、来源均匹配的管理目录，复制或写入失败须报错；Git 归属识别覆盖 `.git` 目录、worktree 的 `.git` 文件和父仓库子目录，归属无法判定时中止，不新建嵌套仓库。
- **入口**：`bash bin/ai-harness help`；分发模板来自 `template/`。
- **升级契约**：`init`/`retrofit` 在 `.ai-harness/manifest.tsv` 记录机制文件双哈希基线；`upgrade` 只更新未改动的机制文件并补缺。定制文件留原处，带版本哈希的建议文件放 `.ai-harness/suggested/`；`--accept-custom <相对路径>` 逐文件确认已合并的定制基线。旧安装无 manifest 时不覆盖不同内容。模板已删除的托管文件：manifest 记录有效、路径是托管路径且模板中不存在时才处理——与安装基线一致（未改动、未定制）则删除，否则保留、报告并以非零退出，记录一律从 manifest 移除，此后归项目所有。项目状态、红线和 ignore 文件不在自动替换范围；dry-run 只读，冲突时版本标记不推进。
- **2.0 布局迁移**：`upgrade` 遇到 1.x 旧布局（`docs/specs/{active,archive,_templates}` 或 `docs/task-pool/README.md`）时，先把流程记录移到 `process/`（已跟踪用 `git -C mv`），再常规同步。有在途 Spec 或已有 `process/` 时在任何写入前拒绝。manifest 与 ignore 的改写先写临时文件，目录移动或落盘失败就逆序移回。改写本身幂等，每次 upgrade 都执行，所以移动后中断也能在下次自愈。旧布局下的 dry-run 只列迁移计划，不比对托管文件。红线文件不改，只提示。
- **验证**：语法检查、`retrofit --dry-run` 只读冒烟、`tests/cli-upgrade.sh` 新旧项目、冲突与已删除托管文件回归、临时技能目录安装正反例和 Git 归属样本。
