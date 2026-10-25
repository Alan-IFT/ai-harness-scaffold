# 技术设计：feat-self-hosting

- 关联需求：requirements.md 的 REQ-01~03 与 AC-01~04
- 设计者：Codex
- 状态：实现中

## 0. 模块关联
- 主模块：本仓库自用状态 → docs/architecture/modules/self-hosting.md
- 涉及模块：模板机制 → docs/architecture/modules/template-mechanism.md
- 涉及模块：项目指南 → docs/architecture/modules/guidance.md
- 契约入口：bin/ai-harness、template/scripts/*.sh、根目录 scripts/*.sh
- 新增模块：无；只为既有源码仓库建立本仓库的架构索引。
- 人工前置决策：决策人=仓库维护者 维护者（用户要求本仓库自用并处理 Git）；风险取舍=发现 main、已有 HEAD 和未提交改动后保留现有仓库，不重新初始化或覆盖；结论=只补本仓库状态与薄入口。G6 的检查和记录由 Agent 做，维护者只决定关键风险与结果。

## 1. 架构与状态流
根目录 AGENTS.md 和 CLAUDE.md 给 Agent 提供同一规则入口。根目录 scripts/*.sh 转发到 template/scripts/*.sh；这些脚本以仓库根目录为工作目录，把 Spec、知识和红线状态写入根目录。template/ 保持可分发的单一机制源码。Git 记录可交接状态。

## 2. 实现顺序与检查点
1. 先读取 Git 状态与目录布局，确认既有仓库、分支、HEAD 和未提交改动，不执行 git init 覆盖。
2. 建根目录 AGENTS、架构索引、知识索引、红线与验证配置，再写根目录薄转发脚本。
3. 调整新建 Spec 脚本，让自用入口引用 template/ 的模板目录；建立本 Spec 并跑门禁、自检、验证。
- 检查点：第 2 步后检查 scripts/ 是否只有转发逻辑，template/ 是否仍是唯一机制源码。
- 检查点：第 3 步后复核 Git 状态与验证摘要；Agent 向维护者呈现需判断事项并记录其决定，由 Agent 推进 G6。

## 3. 契约与兼容性
- 根目录命令保持标准调用形式：bash scripts/ai-resume.sh、bash scripts/ai-new-spec.sh、bash scripts/ai-verify.sh。
- 目标项目仍通过复制 template/ 使用完整脚手架；环境变量 AI_HARNESS_TEMPLATE_DIR 只给本仓库自用入口选择模板目录。
- 不改已有 Git 历史、分支或远端配置。

## 4. 影响面与文件清单
- 新建：根目录 AGENTS.md、CLAUDE.md、MEMORY.md、scripts/*.sh、harness/redlines.conf、harness/verify.conf、.knowledge/INDEX.md、docs/architecture/*、docs/specs/active/feat-self-hosting/*。
- 修改：template/scripts/ai-new-spec.sh 加模板目录覆盖入口；.gitignore 忽略本地报告、失败计数和红线基线。
- 只读依赖：bin/ai-harness、template/scripts/ai-gate.sh、template/scripts/ai-verify.sh、现有 .git 及其历史。
- 间接消费者 / 副作用：根目录全部 `scripts/*.sh` 调用方、`template/scripts/ai-new-spec.sh` 的模板路径选择、根目录 `harness/verify.conf`、`docs/specs/` 和现有 Git 工作树；分发给其他项目的 `template/` 不应转向根目录状态。
- 检索依据：在 `AGENTS.md`、`README.md`、`bin/`、`scripts/`、`template/`、`harness/`、`docs/architecture/` 有界搜索 `AI_HARNESS_TEMPLATE_DIR|template/scripts|docs/specs/_templates|ai-new-spec.sh`；核对根目录转发脚本全文、`git branch --show-current`、`git rev-parse HEAD` 与当前 `git status --short`。

## 5. 对抗自审
1. 最大风险是根目录复制模板机制并形成双份真相；因此只用转发脚本，模板目录仍唯一。
2. 新建 Spec 脚本可能在根目录找不到模板；用显式环境变量选 template/docs/specs/_templates，并做真实创建验证。
3. 门禁内部按 scripts/ 路径调用同级脚本；根目录薄入口提供这些路径并用自检验证。
4. Git 已初始化；重复 git init 没有必要，避免触及分支与已有改动。
- 自审结论：完成真实命令与 Git 状态复核后才能把这次自用配置视为可接力。

## 6. 待确认问题
- 已确认：现有 Git 仓库保留；维护者 维护者 已明确自身负责关键结果和风险判断，Agent 负责运行检查、留痕与机械推进。

## 7. 风险与回滚
- 风险：根目录入口与 template/ 实现路径不一致，造成自用命令失败。
- 回滚方式：撤销本次新建的根目录自用文件及模板脚本的一处覆盖入口改动；不修改既有 Git 历史。
