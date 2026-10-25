# 任务与接力：feat-t-000029

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000029` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：§3 拆成「Karpathy 四原则」与「流程纪律」两块；原则逐句意译，冲突与重复以原则为准。原文「发现无关死代码要提出来」落到本脚手架的「发现但不碰」。审查指南只补一句检验标准，README 设计取舍加一行出处。
- 改动文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`README.md`。
- 影响与风险：脚本只按行数检查 AGENTS.md（`ai-check-bloat.sh`），自检用临时文件，不依赖具体文字；`new-spec.md` 的澄清步骤与原则 1 一致，不需改。

## 2. 任务
- [x] Task 1：吸收原文并删除重复条目
  - 涉及文件：`template/AGENTS.md`、`template/.agents/skills/code-review.md`、`README.md`
  - 验证：`bash scripts/ai-verify.sh --spec feat-t-000029 template/AGENTS.md`

## 3. 发现但不碰
- template/AGENTS.md §5 命令速查、§2「门只查骗不过的信号」、§1.4、开头引用块半句：与正文重复，是否删除待维护者决定。

## 4. WIP 接力区
- 当前任务：无（待 g2/g3）
- 已完成：Task 1
- 正在编辑的文件：无
- 已排除的方案：装 Claude Code 插件（不跨工具）；保留英文原文（与全文语言不一致）
- 下一步：过 g1 后编码
