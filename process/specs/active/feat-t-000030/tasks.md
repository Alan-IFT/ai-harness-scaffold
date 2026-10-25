# 任务与接力：feat-t-000030

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000030` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：AGENTS.md 每次接手都会读，重复的说明只留一处。§5 表里的命令在正文（§1、§2、§3、§4）或对应阶段指南（`code-review.md` 的 review 模式、`new-spec.md` 的 ai-new-spec、`upgrade.md` 的 selftest）都已出现，表整张删；`status` 并进 §2 推进行。§1.4 并进末尾阶段指南行。§2「门只查……」是设计理由，README 已有同句，删。`new-spec.md` Step 0 与 AGENTS.md §1.2 几乎逐字重复，改成引用。模块活文档补一条「为什么」。
- 改动文件：`template/AGENTS.md`、`template/.agents/skills/new-spec.md`、`docs/architecture/modules/guidance.md`。
- 影响与风险：脚本不读 AGENTS.md 文字（只数行数），`skill/SKILL.md`、`upgrade.md` 不引用 §5 或 §1.4。§1.3 外部输入不可信、§4 经验积累是安全与接力功能，保留。

## 2. 任务
- [x] Task 1：收窄优先级、补示例、删重复
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/new-spec.md`、`docs/architecture/modules/guidance.md`
  - 验证：`bash scripts/ai-verify.sh --spec feat-t-000030 template/AGENTS.md`

## 3. 发现但不碰
- 

## 4. WIP 接力区
- 当前任务：无（待 g2/g3）
- 已完成：需求与方案
- 正在编辑的文件：无
- 已排除的方案：保留命令速查表（全部命令在正文与指南已有，表是第二份）
- 下一步：过 g1 后编码
