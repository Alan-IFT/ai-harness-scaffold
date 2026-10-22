# 技术设计：feat-task-pool

- 追溯版本：1

## 0. 模块关联
- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`；CLI 安装 → `docs/architecture/modules/cli.md`；本仓库自用 → `docs/architecture/modules/self-hosting.md`
- 契约入口：`template/scripts/ai-task-pool.sh`、`template/AGENTS.md`
- 人工前置决策：决策人=用户；来源=本次会话；取舍=新增任务池并在新会话继续下一项，且补充要求已安装项目自动升级；结论=执行。具体文件设计由 Agent 实施。

## 1. 数据与行为
`docs/task-pool/T-NNNN.md` 逐项保存标题、优先级、稳定 Spec ID、原始需求及追加更新。脚本只写任务文件；Spec 创建仍调用 ai-new-spec.sh。进行中、完成由 Spec 在 active/archive 的位置派生。旧 INTAKE 保留历史。

升级仅管理模板机制的明确白名单：AGENTS/CLAUDE、脚本、阶段指南、Spec 模板、任务池说明、CI 与 verify 配置示例。`init`/`retrofit` 为与模板一致的文件写入 `.ai-harness/manifest.tsv`，每行存模板哈希、项目哈希及相对路径。`upgrade` 逐路径比较：缺失则补齐；字节未改动且有旧基线才替换；已等于新版则直接记基线；定制或旧安装无基线则保留并生成带新版哈希的建议文件。人工合并后 `--accept-custom <rel>` 只确认该文件当前内容与模板版本；模板下一次变化会重新提示冲突。全量路径预检先转换 Git Bash 盘符/反斜杠路径，遍历目标绝对路径的每级祖先及受管理相对路径，阻止符号链接与非目录祖先，包含父链接与目标尾随斜杠；模板枚举和哈希必须成功才写入基线或推进版本。`--dry-run` 不写入。存在冲突时不更新版本号，返回非零。

### 1.1 需求覆盖矩阵
| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | requirements.md §2 创建 | §1 add | AC-01 |
| REQ-02 | requirements.md §2.3 更新 | §1 update | AC-01 |
| REQ-03 | requirements.md §2.3 下一项 | §1 next 与 resume | AC-02 |
| REQ-04 | requirements.md §2 关联 | §1 start | AC-03 |
| REQ-05 | 本次补充自动升级 | §1 升级白名单与基线 | AC-05 |
| REQ-06 | requirements.md §2 定制冲突 | §1 建议与逐文件确认 | AC-05 |
| ERR-01 | requirements.md §2 无效输入 | §3 校验 | AC-01 |
| ERR-02 | requirements.md §2 重复领取 | §3 启动检查 | AC-03 |
| ERR-03 | requirements.md §2 不安全/只读 | §1 路径预检和无基线保守分支 | AC-05 |
| AC-01 | requirements.md §3 | §2 自检 | AC-01 |
| AC-02 | requirements.md §3 | §2 自检 | AC-02 |
| AC-03 | requirements.md §3 | §2 自检 | AC-03 |
| AC-04 | requirements.md §3 | §2 文档与安装 | AC-04 |
| AC-05 | requirements.md §3 | §2 CLI 回归 | AC-05 |

## 2. 实现顺序与检查点
1. 建任务池脚本和模板目录，验证 add/list/next/update/start；Spec 模板先完整检查，再在临时目录生成并移入 active，任务关联写入失败则清理本次生成的 Spec。
2. 接入 owner resume 与根目录转发，增加自检；检查点：活跃 Spec 优先与归档后切换。
3. 更新指南、README、架构文档；检查点：命令和状态语义一致。
4. 给安装器加 manifest 与 upgrade，并以临时新旧项目验证无覆盖、dry-run、确认定制和重新冲突。
- 边界样本：非法 ID、P3、空白需求和补充、重复 start、空池、活跃 Spec 与高优先级待办并存、归档任务、并发 add 锁冲突、手工改坏优先级或队列状态、模板缺文件或需求来源占位；升级时目标内/父目录符号链接、目标尾随斜杠、Windows 盘符与反斜杠路径、模板枚举及哈希失败。

## 3. 契约
`ai-task-pool.sh add [--priority P0|P1|P2] <原话>`、`update <T-ID> <补充>`、`list`、`next`、`start <T-ID> <feat-id>`。next/list 只读；start 拒绝已有关联和已存在 Spec。

`ai-harness upgrade <dir> [--dry-run] [--accept-custom <relative-path>]`。旧项目缺 manifest 时，仅补齐缺失与识别已是新版文件；不同内容一律冲突。接受定制必须逐文件显式指定。已安装目标以 `.ai-harness/version` 识别。

## 4. 影响面与文件清单
- 新建：`template/scripts/ai-task-pool.sh`、`scripts/ai-task-pool.sh`、`template/docs/task-pool/README.md`、`docs/task-pool/README.md`、`docs/task-pool/T-000001.md`。
- 修改：`template/scripts/ai-new-spec.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`template/AGENTS.md`、`AGENTS.md`、`template/.agents/skills/new-spec.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/retrofit-legacy.md`、`template/docs/specs/_templates/requirements.md`、`template/docs/INTAKE.md`、`docs/INTAKE.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`。
- 新增升级影响：`bin/ai-harness`、`tests/cli-upgrade.sh`、`harness/verify.conf`、`docs/architecture/modules/cli.md`、`README.md`、`skill/SKILL.md`、`template/.agents/skills/retrofit-legacy.md`、`template/AGENTS.md`。
- 只读依赖：`template/scripts/ai-gate.sh`。
- 间接消费者 / 副作用：init/retrofit 复制模板全树并记录机制文件基线；selftest 复制模板脚本；owner resume 增加只读提示。upgrade 只管理白名单，旧项目业务文件保护不变。
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
- 风险：旧安装无基线需逐文件合并现有冲突；版本标记只在全部机制冲突确认后推进。确认定制后的本地修改或上游变化会重新触发冲突。
- 回滚方式：回退脚本和文档，保留需求文件。
