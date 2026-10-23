# 原子执行队列与接力：feat-t-000005

- 需求文档：`requirements.md`
- 设计文档：`design.md`
- 追溯版本：1
- 当前阶段：以 `bash scripts/ai-gate.sh status feat-t-000005` 为准。

## 0. 阶段门

由 `.gates` 和 `ai-gate.sh status` 记录，不手改。

## 1. 上下文清单

- 必读：本 Spec、`docs/architecture/00-INDEX.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`。
- 条件读：`template/scripts/ai-gate.sh` 的 ck_g2 与 cmd_pass、`template/scripts/harness-selftest.sh` 的 G2 用例。
- 明确不读：无关业务模块和归档 Spec 全文（仅 grep 其 AC 行做证伪）。
- 注入知识：无相关卡片
- 知识检索：`ai-knowledge.sh suggest guidance` 与 `suggest template-mechanism` 均返回无有效候选；已读两份模块活文档与真实模板脚本。
- 本次不变量：不修改 `redlines.conf`；不新增宿主专属文件；已过 G2 的 Spec 不受影响；G3 校验逻辑不变。

## 2. 原子任务序列

- [x] **Task 1: G2 含糊词检查与自检用例**
  - 涉及文件：`template/scripts/ai-gate.sh`、`template/scripts/harness-selftest.sh`
  - 对应需求 / 验收：REQ-02, ERR-01, ERR-02 / AC-01
  - 对应设计：design.md §2、§3.2
  - 完成判据：裸词 AC 被拒并显示命中词；引号内同词通过；自检全绿。
  - 验证命令：`bash scripts/harness-selftest.sh`

- [x] **Task 2: 设计与需求模板、澄清指南、AGENTS**
  - 涉及文件：`template/docs/specs/_templates/design.md`、`template/docs/specs/_templates/requirements.md`、`template/.agents/skills/new-spec.md`、`template/AGENTS.md`
  - 对应需求 / 验收：REQ-01, REQ-04 / AC-02, AC-04
  - 对应设计：design.md §2、§4
  - 完成判据：§4 复用检索、§5 独立设计审查字段及填写说明存在；②③默认审查与跨宿主换上下文方式写明；AGENTS 未超限。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000005 README.md`

- [x] **Task 3: 记忆捕获、纠正替换与晋升**
  - 涉及文件：`template/AGENTS.md`、`template/MEMORY.md`、`template/.agents/skills/gc-memory.md`
  - 对应需求 / 验收：REQ-03 / AC-03
  - 对应设计：design.md §2
  - 完成判据：三类信号、写纠正前删同主题旧条、晋升后删原条均写明。
  - 验证命令：`bash scripts/ai-verify.sh --quick --spec feat-t-000005 README.md`

- [x] **Task 4: 同步活文档并完成回归**
  - 涉及文件：`docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`
  - 对应需求 / 验收：REQ-01, REQ-02 / AC-05
  - 对应设计：design.md §2、§4
  - 完成判据：活文档与实现一致；体积体检、自检与正式验证通过；diff 无宿主专属文件。
  - 验证命令：`bash scripts/ai-verify.sh --spec feat-t-000005 README.md`
  - 收尾动作：阅读并执行 `template/.agents/skills/code-review.md`、`knowledge-distill.md` 与 `archive-spec.md`

## 3. 发现但不碰

- 记录：`scripts/harness-selftest.sh` / 在 LANG 为空的 Git Bash 下基线即有 21 项失败（象限、边界样本、G6 等含全角字符的 sed 用例），`LC_ALL=C.UTF-8` 下 213 项全过 / 与本 Spec 无关且改动面大 / 建议另立任务让自检自行固定 UTF-8 locale。

## 4. Current WIP & Handoff

- 当前正在执行的任务：G5 独立 CR
- 前置依赖 / 并行关系：Task 2、3 互不依赖；Task 4 依赖前三项
- 已完成的小步进展：G1~G3 已通过（独立设计审查首轮需修改，已改入设计）；Task 1 完成，自检需在 `LC_ALL=C.UTF-8` 下运行
- 正在编辑的文件：
  - `docs/architecture/modules/guidance.md`、`docs/architecture/modules/template-mechanism.md`
- 已排除的死胡同：宿主专属 hook（维护者否决）
- 上次验证与未验证改动：正式验证 PASS（LC_ALL=C.UTF-8，220s），见 verification.md
- 下一步立即执行的唯一动作：新上下文运行 `ai-resume.sh review feat-t-000005 1dee735` 写 review.md
- knowledge_feedback：无
