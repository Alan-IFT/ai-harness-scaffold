# 技术设计：feat-task-pool

- 追溯版本：1

## 0. 模块关联
- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`；本仓库自用 → `docs/architecture/modules/self-hosting.md`
- 契约入口：`template/scripts/ai-task-pool.sh`、`template/AGENTS.md`
- 人工前置决策：决策人=用户；来源=本次会话；取舍=新增任务池并在新会话继续下一项；结论=执行。具体文件设计由 Agent 实施。

## 1. 数据与行为
`docs/task-pool/T-NNNN.md` 逐项保存标题、优先级、稳定 Spec ID、原始需求及追加更新。脚本只写任务文件；Spec 创建仍调用 ai-new-spec.sh。进行中、完成由 Spec 在 active/archive 的位置派生。旧 INTAKE 保留历史。

### 1.1 需求覆盖矩阵
| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | requirements.md §2 创建 | §1 add | AC-01 |
| REQ-02 | requirements.md §2.3 更新 | §1 update | AC-01 |
| REQ-03 | requirements.md §2.3 下一项 | §1 next 与 resume | AC-02 |
| REQ-04 | requirements.md §2 关联 | §1 start | AC-03 |
| ERR-01 | requirements.md §2 无效输入 | §3 校验 | AC-01 |
| ERR-02 | requirements.md §2 重复领取 | §3 启动检查 | AC-03 |
| AC-01 | requirements.md §3 | §2 自检 | AC-01 |
| AC-02 | requirements.md §3 | §2 自检 | AC-02 |
| AC-03 | requirements.md §3 | §2 自检 | AC-03 |
| AC-04 | requirements.md §3 | §2 文档与安装 | AC-04 |

## 2. 实现顺序与检查点
1. 建任务池脚本和模板目录，验证 add/list/next/update/start；Spec 模板先完整检查，再在临时目录生成并移入 active，任务关联写入失败则清理本次生成的 Spec。
2. 接入 owner resume 与根目录转发，增加自检；检查点：活跃 Spec 优先与归档后切换。
3. 更新指南、README、架构文档；检查点：命令和状态语义一致。
- 边界样本：非法 ID、P3、空白需求和补充、重复 start、空池、活跃 Spec 与高优先级待办并存、归档任务、并发 add 锁冲突、手工改坏优先级或队列状态、模板缺文件或需求来源占位。

## 3. 契约
`ai-task-pool.sh add [--priority P0|P1|P2] <原话>`、`update <T-ID> <补充>`、`list`、`next`、`start <T-ID> <feat-id>`。next/list 只读；start 拒绝已有关联和已存在 Spec。

## 4. 影响面与文件清单
- 新建：`template/scripts/ai-task-pool.sh`、`scripts/ai-task-pool.sh`、`template/docs/task-pool/README.md`、`docs/task-pool/README.md`、`docs/task-pool/T-000001.md`。
- 修改：`template/scripts/ai-new-spec.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`template/AGENTS.md`、`AGENTS.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/retrofit-legacy.md`、`template/docs/specs/_templates/requirements.md`、`template/docs/INTAKE.md`、`docs/INTAKE.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`。
- 只读依赖：`template/scripts/ai-gate.sh`、`bin/ai-harness`、`harness/verify.conf`。
- 间接消费者 / 副作用：init/retrofit 复制模板全树；selftest 复制模板脚本；owner resume 增加只读提示。旧项目文件保护不变。
- 检索依据：`rg -n 'INTAKE|ai-resume|ai-new-spec' template README.md bin docs/architecture`；检查 CLI、指南和转发。

## 5. 对抗自审
1. 最可能错在状态双写；只存 Spec ID，位置派生。
2. 假设使用现有 Spec 目录；空池和旧仓库需可用。
3. 无效输入及重复启动须无副作用；add 用锁分配 ID。
4. 单脚本与 Markdown 即可，不加服务。
5. 回滚脚本和指南时，任务文件仍是普通需求记录。
- 自审结论：先测路由和拒绝，再更新指南。

## 6. 待确认问题
无阻塞问题。

## 7. 风险与回滚
- 风险：旧 INTAKE 与新池混淆；文档区分历史和新入口。
- 回滚方式：回退脚本和文档，保留需求文件。
