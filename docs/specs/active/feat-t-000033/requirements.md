# 需求与验收规范 (Requirements): feat-t-000033

- **创建时间**: 2026-10-24
- **状态**: Approved
- **需求来源**: `docs/task-pool/T-000033.md`（原始需求与更新）
- 原始问题 / 原话：ADR-0002 阶段 R2，见 `docs/task-pool/T-000033.md`。ADR-0002 阶段 R2（简化指纹）：
  - 流程记录 `docs/specs`、`docs/metrics.md`、`docs/task-pool` 迁入可见顶层目录 `process/`；`ai-state-id.sh` 与 `ai-verify.sh` 只排除该目录；删除 design §4 局部清单模式。
  - upgrade 迁移下游项目：检测到活跃 Spec 或已有 `process/` 时拒绝。
  - 与 R1 同一版本发布。
  - 维护者 G6 原话「接受并归档，启动 R2」。
- 需求分级（象限）：② 人机协同·风险侧，下游目录迁移与指纹变更。原因：
  - 下游 upgrade 会移动项目的流程记录目录，属于不可轻易撤回的文件布局变更；
  - 状态指纹算法改变后，已过 G4 的在途 Spec 摘要会失效。
- 分级依据：风险在迁移与指纹，复杂度在改动面：
  - 风险来自下游目录迁移与指纹变更；
  - 改动面约 30 个文件、约 300 处路径引用，以机械替换为主，方案已由 ADR-0002 S1 决定。

## 0. 必须明确（四项，缺一项不得进入设计）

- 做什么：流程记录迁入顶层 `process/`，指纹只排除该目录并删除 scoped 模式，下游与本仓库一起迁移并发布 2.0.0：
  - 把流程记录的根从 `docs/` 下的三处改为顶层 `process/`：`process/specs/`、`process/metrics.md`、`process/task-pool/`。
  - 所有脚本、模板、指南、CLI 与自检改用新路径。
  - 状态指纹与正式验证目标检查只排除 `process/`；删除 design §4 精确清单（scoped）模式。
  - 旧路径仍存在时，脚本报错提示 upgrade。
  - `upgrade` 自动迁移下游；本仓库自身同样迁移。
  - 版本号升级并发布（含 R1）。
- 为谁做：下游项目及其 Agent、本仓库维护者：
  - 下游项目及其 Agent：流程记录集中在一处，状态指纹不再依赖排除清单；
  - 本仓库维护者。
- 关键业务规则：只迁三项、有活跃 Spec 或已有 `process/` 即拒绝、dry-run 只读：
  - 迁移只移动上述三项，不动 `docs/architecture/`、`docs/roadmap/`、`docs/INTAKE.md`、`MEMORY.md`；
  - 有活跃 Spec 或已存在 `process/` 时，upgrade 拒绝迁移且不写任何文件；
  - `--dry-run` 只报告；
  - 不修改根目录 `harness/redlines.conf`。
- 验收标准：只引用新路径、迁移回归全过、本仓库已迁移、指纹只剩全仓模式：
  - 脚本、模板、指南、CLI 只引用新路径；
  - 自检与升级回归覆盖迁移的正反路径并全部通过；
  - 本仓库已迁移且门禁正常工作；
  - `ai-state-id.sh` 只剩全仓模式。

## 1. 业务背景与目标 (Context & Goal)
- **背景**：
  - 流程记录散在 `docs/` 下三处，状态指纹靠排除清单区分；新增流程文件就要补清单（T-000014）。
  - scoped 指纹模式约 100 行，依赖 design §4 的人工确认。
  - ADR-0002 S1 决定集中到单一根并删除 scoped 模式。
- **完成后的行动与效果**：
  - 下游一次 upgrade 获得 R1 + R2；
  - Agent 只需记住「`process/` 下是流程记录，其他都计入指纹」。
  - 回访信号：`ai-state-id.sh` 行数（145）与自检行数下降，不再出现指纹排除类任务。
- **Non-Goals（本次明确不做）**：
  - 不迁移 `docs/INTAKE.md`（只读历史）与架构文档；
  - 不提供反向迁移命令，回滚方式见设计；
  - 不改任务池行为。

## 2. 结构化需求 (EARS Acceptance Criteria)

### 2.1 正常流 (Happy Paths)
- **REQ-01**: WHEN 脚本读写 Spec、任务池或度量，THE 脚本 SHALL 使用 `process/specs/`、`process/task-pool/`、`process/metrics.md`。
- **REQ-02**: WHEN 计算状态指纹，THE `ai-state-id.sh` SHALL 只用全仓模式并排除 `process/**`，`--spec` 参数仍被接受但不改变结果。
- **REQ-03**: WHEN 正式验证的目标位于 `process/` 下，THE `ai-verify.sh` SHALL 拒绝。
- **REQ-04**: WHEN 下游执行 `upgrade` 且存在旧路径、无活跃 Spec、无 `process/`，THE CLI SHALL 把三项移入 `process/`，同步 manifest 中的托管路径与 ignore 文件中的旧路径行，再继续常规升级。
- **REQ-05**: WHEN 本 Spec 完成，THE 本仓库 SHALL 已迁移到 `process/`，`VERSION` 升到新的主版本。

### 2.2 异常与边界流 (Edge Cases & Error Handling)
- **ERR-01**: IF upgrade 时存在活跃 Spec（`docs/specs/active/` 下有目录）或已有 `process/`，THEN CLI SHALL 拒绝并说明原因，不写任何文件。
- **ERR-02**: IF 项目仍有旧路径 `docs/specs/` 而脚本已是新版，THEN `ai-gate.sh`、`ai-task-pool.sh`、`ai-new-spec.sh` SHALL 报错提示运行 upgrade，不在旧路径上继续工作。

### 2.3 语义敏感原文锚点（②③必填）
| 对应需求 ID | 来源章节 / 链接 | 原文关键短句 | 设计时必须保留的语义 |
| :-- | :-- | :-- | :-- |
| REQ-04 | T-000033 原话 | 「检测到活跃 Spec 或已有 process/ 即拒绝」 | 拒绝必须发生在任何写入之前 |
| REQ-05 | ADR-0002 §4 | 「与 R1 同一版本发布，下游只升级一次」 | 版本号在本 Spec 内升级，R1 与 R2 一起生效 |

## 3. 验收标准（什么算通过、什么算不通过）

| 编号 | 验收点 | 通过条件 | 不通过条件 | 量化指标 / 证据 |
| :-- | :-- | :-- | :-- | :-- |
| AC-01 | 新路径 | `grep -rn 'docs/specs\|docs/metrics\|docs/task-pool'` 在 `template/`、`scripts/`、`skill/`、`README.md`、`AGENTS.md` 中无命中；`bin/ai-harness` 只在迁移逻辑中出现旧路径 | 其他位置仍引用旧路径 | `grep` 输出 |
| AC-02 | 指纹简化 | `ai-state-id.sh` 不含 manifest、scope 相关函数，行数小于 145；自检覆盖：`process/` 下改动不改变指纹，`process-x/` 下改动改变指纹，`--spec` 与不带参数结果相同 | 任一项不符 | `wc -l`、自检断言 |
| AC-03 | 迁移回归 | `tests/cli-upgrade.sh` 覆盖：旧布局无活跃 Spec 时迁移成功且任务、归档、度量内容不变；有活跃 Spec 时拒绝且快照不变；已有 `process/` 时拒绝；`--dry-run` 快照不变；迁移后再次 upgrade 无冲突 | 任一用例不符 | 回归断言 |
| AC-04 | 旧路径提示 | 自检中新版脚本在仅有 `docs/specs/` 的项目里，`ai-gate.sh status` 与 `ai-task-pool.sh next` 返回非零并提示 upgrade | 继续在旧路径工作或无提示 | 自检断言 |
| AC-05 | 本仓库迁移 | 本仓库 `process/specs/`、`process/task-pool/`、`process/metrics.md` 存在，`docs/` 下三项不存在；`ai-gate.sh status`、`ai-task-pool.sh list` 正常；`bin/ai-harness` 的 `VERSION` 为 `2.0.0` | 任一项不符 | 命令输出 |
| AC-06 | 回归与审查 | 自检全部通过、CLI 回归 PASS、正式验证 PASS；独立 G5 关键问题 0 | 任一项不符 | `verification.md`、`review.md` |

## 4. 待确认问题（清零后才能过 G1）

### 4.1 产品问题
- [x] Q1：迁移哪些？→ 结论：只迁 `docs/specs`、`docs/metrics.md`、`docs/task-pool`（ADR-0002 S1）；`docs/INTAKE.md` 是只读历史，不迁。

### 4.2 技术问题
- [x] Q1：反向迁移与版本号？→ 结论：设计阶段作为人工前置决策确认。

## 5. 非功能性约束 (Security & Performance)
- **性能**：scoped 模式删除后，指纹对大仓库总是全仓计算；本仓库与常见项目规模下可接受。
- **安全与权限**：迁移前对 `process/` 与三项源路径做 `safe_path` 预检；不跟随符号链接。
- **兼容与迁移**：
  - 已过 G4 的在途 Spec 因指纹算法变化须重跑正式验证——升级已要求无活跃 Spec，因此不会发生；
  - 归档 Spec 内容原样移动。
