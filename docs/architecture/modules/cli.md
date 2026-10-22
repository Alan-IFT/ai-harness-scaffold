# CLI 与安装

- **职责**：`bin/ai-harness` 负责初始化、老项目接入、安全升级、冲突隔离、候选目录扫描、体检，以及向 Codex/Claude Code 安装指向共享技能的薄入口。
- **边界**：目标项目的模块边界、公共契约和红线必须基于证据确认；目录扫描只给候选。技能安装只更新宿主、来源均匹配的管理目录，复制或写入失败须报错；Git 归属识别覆盖 `.git` 目录、worktree 的 `.git` 文件和父仓库子目录，归属无法判定时中止，不新建嵌套仓库。
- **入口**：`bash bin/ai-harness help`；分发模板来自 `template/`。
- **升级契约**：`init`/`retrofit` 在 `.ai-harness/manifest.tsv` 记录机制文件双哈希基线；`upgrade` 只更新未改动的机制文件并补缺。定制文件留原处，带版本哈希的建议文件放 `.ai-harness/suggested/`；`--accept-custom <相对路径>` 逐文件确认已合并的定制基线。旧安装无 manifest 时不覆盖不同内容。项目状态、红线和 ignore 文件不在自动替换范围；dry-run 只读，冲突时版本标记不推进。
- **验证**：语法检查、`retrofit --dry-run` 只读冒烟、`tests/cli-upgrade.sh` 新旧项目与冲突回归、临时技能目录安装正反例和 Git 归属样本。
