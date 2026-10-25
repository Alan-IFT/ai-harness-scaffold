# 原子执行队列与跨工具接力棒: feat-single-source-of-truth

- **需求文档**: `docs/specs/archive/2026-10/feat-single-source-of-truth/requirements.md`
- **设计文档**: `docs/specs/archive/2026-10/feat-single-source-of-truth/design.md`
- **当前阶段**: G1~G7 已通过并归档；权威门记录见本目录 `.gates`（脚本维护）。

## 0. 阶段门
按根 `AGENTS.md` 和 `template/scripts/ai-gate.sh` 执行 G1~G7；阈值数值只查本项目 `harness/redlines.conf`。G4 需当前状态 PASS 的验证摘要；G5 需独立上下文审查；G6 由 Agent 跑客观检查并记录 维护者 的结果决定；G7 归档。

## 1. 上下文清单
- **必读**：本 Spec、`docs/architecture/00-INDEX.md`、模板机制/项目指南/自用状态模块文档、`template/harness/redlines.conf`。
- **条件读**：`bin/ai-harness` 安装和 retrofit 部分；与配置键命中的脚本、指南、模板。
- **明确不读**：`docs/specs/archive/**` 的历史细节、示例业务模块内部实现、大段旧报告。
- 注入知识：无相关卡片；`.knowledge/INDEX.md` 目前无卡片。
- 知识检索：已运行 `bash scripts/ai-knowledge.sh suggest template-mechanism`，输出「无有效候选；仍须检查模块活文档和真实代码」；因此无卡片注入。
- **本次不变量**：根 `scripts/` 只转发；不改阈值数值；正常完整配置的门禁语义不变；状态保存在项目内与 Git。

## 2. 原子任务序列
- [x] **Task 1: 配置加载器与 gate 接入**
  - **涉及文件**: `template/scripts/ai-config.sh`、`template/scripts/ai-gate.sh`
  - **对应需求 / 验收**: REQ-01、ERR-01 / AC-01
  - **完成判据**: 缺失或非法必要键清楚报错，完整配置下 G1/G5 语义不变。
  - **验证命令**: `bash -n template/scripts/ai-config.sh template/scripts/ai-gate.sh`; `bash scripts/harness-selftest.sh`
- [x] **Task 2: 其他脚本接入同一加载器**
  - **涉及文件**: `template/scripts/ai-verify.sh`、`template/scripts/ai-check-bloat.sh`、`template/scripts/ai-knowledge.sh`
  - **对应需求 / 验收**: REQ-01、ERR-01 / AC-01、AC-05
  - **完成判据**: 受支持阈值不再有内置回退值，异常配置显式失败。
  - **验证命令**: `bash -n template/scripts/*.sh`; `bash scripts/harness-selftest.sh`
- [x] **Task 3: 指南与模板只引用键**
  - **涉及文件**: `template/AGENTS.md`、`template/MEMORY.md`、相关 `template/.agents/skills/*.md`、`template/docs/specs/_templates/{requirements,tasks}.md`、`skill/SKILL.md`
  - **对应需求 / 验收**: REQ-01 / AC-02
  - **完成判据**: 描述阈值时引用配置键；没有与配置竞争的数字副本。
  - **验证命令**: `rg -n '120|150|180|≥60|≤4|<60' template/AGENTS.md template/MEMORY.md template/.agents/skills template/docs/specs/_templates skill/SKILL.md`
- [x] **Task 4: 自检正反例与安装样本**
  - **涉及文件**: `template/scripts/harness-selftest.sh`、`README.md`
  - **对应需求 / 验收**: REQ-02、ERR-03 / AC-03、AC-05
  - **完成判据**: 修改配置生效、缺失/非法配置拒绝、模板脚本独立可运行、根转发审计通过。
  - **验证命令**: `bash scripts/harness-selftest.sh`; `bash bin/ai-harness retrofit . --dry-run --skip-doctor`
- [x] **Task 5: 状态文案与活文档收尾**
  - **涉及文件**: `docs/INTAKE.md`、`docs/architecture/modules/{template-mechanism,guidance,self-hosting}.md`、`template/scripts/{ai-verify,ai-gate}.sh`
  - **对应需求 / 验收**: REQ-03、ERR-02 / AC-04
  - **完成判据**: 归档链接正确，验证指纹说明准确，根目录和模板的所有权明确。
  - **验证命令**: `bash scripts/ai-verify.sh --spec feat-single-source-of-truth template/scripts/ai-config.sh`; `git diff --check`

## 3. 发现但不碰
- 现有脚本各自执行少量 Bash 配置 `source`；本次只合并重复阈值读取与必要键校验，不创建外部配置服务。

## 4. Current WIP & Handoff Scratchpad
- **当前正在执行的任务**: 无；维护者 已批准，G7 已通过并归档。
- **前置依赖 / 并行关系**: Task 1 → Task 2 → Task 4；Task 3 可在加载器稳定后进行。
- **已完成的小步进展**: 两项前置 Spec 已归档；配置加载器、文档和夹具改造完成。临时安装项目在 CR 上限、重试上限、可行性阈值均与模板不同的情况下完整自检 100/100 通过；本仓库最终 `ai-verify.sh` PASS、100/100，自检报告见 `reports/verify-20261020-084159-151.log`；G4 和独立 G5 已通过。逐条 AC 的 Agent 证据见 `acceptance.md`。
- **正在编辑的文件**: `template/scripts/harness-selftest.sh` 已修复；现无继续编辑的实现文件。
- **已排除的死胡同 / 错误方案**: 根目录复制第二套机制；把不同项目配置强制共用。
- **上次验证与未验证改动**: `verification.md` 的 PASS 和状态指纹属于最终夹具修复后版本；之后仅更新本 Spec 的交接文案，无实现代码改动。
- **下一步立即执行的唯一动作**: 无待执行开发动作；下游项目接入后的反馈按 `docs/metrics.md` 回访。
- **knowledge_feedback**: 暂无。
