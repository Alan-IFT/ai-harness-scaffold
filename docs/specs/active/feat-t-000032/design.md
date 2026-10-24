# 技术架构与接口设计 (Technical Design): feat-t-000032

- **关联需求**: `requirements.md`（G1 / G2 已通过）
- **设计者**: Claude Code（Opus 5.5）
- **状态**: Approved
- 追溯版本：1

## 0. 模块关联

- 主模块：模板机制 → `docs/architecture/modules/template-mechanism.md`
- 涉及模块：CLI → `docs/architecture/modules/cli.md`；项目指南 → `docs/architecture/modules/guidance.md`；本仓库自用状态 → `docs/architecture/modules/self-hosting.md`
- 契约入口（只读）：`docs/architecture/00-INDEX.md`
- 新增模块：无
- 人工前置决策：决策人：本会话维护者；来源：2026-10-24 对「下游 upgrade 时，模板里已删除的托管文件怎么处理？」选择「未改动的自动删，改过的保留并报告（推荐）」，审查者选择「本会话 subagent」；删除范围依 ADR-0002 §3.2（维护者已决定）；取舍：upgrade 自动删除哈希一致的已删除托管文件，改过的保留、报告并转为项目文件；结论：同意。

## 1. 架构变更与数据流

以删除为主，不新增机制，唯一新增逻辑是 `upgrade` 处理模板已删除的托管文件。

- **门禁**（`template/scripts/ai-gate.sh`）：
  - `ck_g1`：删除 §6 可行性解析与 `FEASIBILITY_MIN`，④ 的早退分支随之删除。
  - `ck_g2`：删除含糊词 awk。
  - `ck_g3`：删除 `delegation_fields` / `validate_delegation` 调用。
  - `ck_g4`：删除「知识检索 / 注入知识」与知识卡校验。
  - `ck_g5`：追溯字段去掉「知识检索」。
  - `ck_g6`：删除 `G6_SCAN_AWK`、`G6_PASS_RE`、`g6_scan` 与预授权委托分支。冒烟、AC 汇总、逐条 AC 三处改为取字段值（全角冒号已归一），要求以「通过」开头，后面只能是行尾、空白或标点。
    - 标点集合：全角「；，。、（」与半角 `; , . (`。
    - 「通过率」「通过了」「不通过」「`通过`」一律拒绝。
    - ②③ 缺少「人工决定：通过」时，报错追加提示：若 acceptance 为旧格式，去掉委托字段，人工决定写「通过」。
  - `cmd_pass`：删除 `--by`，记录者恒为 agent；脚本头部用法注释与用法串同步。G3 行第 5 列恒写 `none`，作为保留列，并在注释中写明，保持 5 列使 G5 审查状态绑定照常生效。
  - 保留共享函数：`sha()` 供红线基线使用，`field_value` 供 G3「边界样本」使用；`field_ok` 与 `section_body` 也保留。
  - `hash_text` 若无其他调用者一并删除；配置加载去掉 `FEASIBILITY_MIN`。
- **其他脚本**：
  - 删除 `template/scripts/ai-knowledge.sh` 与根目录转发 `scripts/ai-knowledge.sh`。
  - `ai-new-spec.sh`、`ai-resume.sh` 删除知识卡、委托与评分相关输出。
  - `template/harness/redlines.conf` 删除 `FEASIBILITY_MIN`、`KNOWLEDGE_TTL_DAYS`。
- **模板**：
  - `requirements.md` 删除 §6 评分表与含糊词提示。
  - `design.md` 删除条件委托行。
  - `tasks.md` 删除注入知识与知识检索行。
  - `acceptance.md` 改为「字段：通过；证据」格式，删除预授权委托说明与字段。
  - 删除 `knowledge-card.md`、`template/.knowledge/`。
- **指南**：
  - `template/AGENTS.md`：G1~G6 表格去掉评分、含糊词、知识卡、委托；§3「知识飞轮」压缩为记忆捕获与 `gc-memory.md` 晋升。
  - 删除 `knowledge-distill.md`；`new-spec.md`、`archive-spec.md`、`gc-memory.md`、`retrofit-legacy.md`、`harness/CI.md`、`template/MEMORY.md` 删除相应段落。
  - `code-review.md` 增加两项检查：AC 措辞含糊；验收证据与结论矛盾。同时删除审查模板中的「知识检索」字段。
  - `template/AGENTS.md`、`gc-memory.md` 中的 `knowledge_feedback` 措辞改为反馈规则与记忆。
  - `retrofit-legacy.md` 整段删除委托快照与 `cksum` 回落说明。
  - `docs/architecture/modules/cli.md` 补写 upgrade 的删除语义。
- **CLI**（`bin/ai-harness`）：
  - `doctor` 删除 `ai-knowledge.sh check`。
  - `upgrade` 处理模板已删除的托管路径。manifest 中的 `rel` 来自磁盘，不可信，必须同时满足以下条件才处理：`managed_file "$rel"`、模板中 `[ ! -e "$TPL/$rel" ]`、两列哈希均为 64 位十六进制。
    - 在主循环前的全量预检段对这些路径做 `safe_path`，失败则整次升级不写入。不用 `-e` 代替，因为符号链接悬空时 `-e` 为假。
  - 主循环之后逐条处理：
    - 目标不存在：丢弃记录。
    - `old_source == old_local` 且当前哈希等于 `old_local`（用户从未改过）：删除文件，`--dry-run` 只打印 `- <rel>`；丢弃记录。
    - 其他情况（含 `--accept-custom` 确认过的定制文件，即 `old_source != old_local`，以及本地改动过的）：保留文件，打印 `! <rel>（模板已删除，本地有改动或已定制，已转为项目文件，请人工处理）`，计入冲突（非零返回、版本标记不更新）；丢弃记录，此后归项目所有，下一次 upgrade 不再报告。
  - 已删除文件的冲突使用单独的收尾提示，不沿用「冲突需合并」。
  - `--dry-run` 下不创建 `$tmp`，新路径也不写 manifest。
  - manifest 缺失（旧安装）时不删除任何文件。
- **自检**（`harness-selftest.sh`）：
  - 删除第 11 节（知识卡）。
  - 删除第 6 节的 `--by human` 用例，保留 baseline TTY 用例。
  - 删除第 2、3、4 节中评分、含糊词、委托与 G6 扫描样本表的用例。
  - 新增 G2「含糊词不拦」、G6 结构化结论正反用例。
- **回归**：`tests/cli-upgrade.sh` 新增已删除托管文件的用例：
  - 未改动的被删除；
  - 改动过的被保留并返回非零，再次 upgrade 不再报告；
  - `--accept-custom` 定制过的被保留；
  - `--dry-run` 不删除、不改 manifest；
  - manifest 缺失时不删除；
  - manifest 中写入非托管路径（如 `src/app.sh`）时不删除。
- **文档**：README、`docs/architecture/modules/*.md`、`docs/architecture/00-INDEX.md` 中对应描述同步删除。
- **本仓库自用状态**：
  - 删除根目录 `.knowledge/`（K-0001 内容是被删的门禁正则写法）。
  - 根目录 `harness/redlines.conf` 不动（只允许人类修改），交付时提示维护者清理两个旧键。

### 1.1 需求覆盖矩阵

| 来源 ID | 原文锚点 / 语义细则 | 设计落点 | 验证 |
| :-- | :-- | :-- | :-- |
| REQ-01 | G2 只查结构 | §1 门禁 `ck_g2` | AC-02 |
| REQ-02 | G6 三处只认行首「通过」 | §1 门禁 `ck_g6`、模板 acceptance.md | AC-02 |
| REQ-03 | G1 去掉评分 | §1 门禁 `ck_g1`、模板 requirements.md、redlines | AC-01 |
| REQ-04 | 去掉条件委托，G3 仍 5 列 | §1 门禁 `ck_g3` / `ck_g6` / `cmd_pass` | AC-01, AC-03 |
| REQ-05 | 去掉知识卡 | §1 其他脚本、模板、指南、CLI doctor | AC-01 |
| REQ-06 | 去掉 `--by` | §1 门禁 `cmd_pass` | AC-01 |
| REQ-07 | 审查清单两项检查 | §1 指南 `code-review.md` | AC-06 |
| REQ-08 | upgrade 处理已删除托管文件 | §1 CLI `upgrade` | AC-04 |
| ERR-01 | 旧格式 acceptance 被拒并提示 | §1 门禁 `ck_g6` 报错文案 | AC-02 |
| ERR-02 | 改动过的已删除文件保留并报告 | §1 CLI `upgrade` | AC-04 |
| AC-01 | 机制已删除 | §2 步骤 1~4 | AC-01 |
| AC-02 | G2 / G6 新判定 | §2 步骤 1 | AC-02 |
| AC-03 | 保留项不变 | §2 步骤 5 | AC-03 |
| AC-04 | upgrade 处理已删除文件 | §2 步骤 4 | AC-04 |
| AC-05 | 规模与耗时 | §2 步骤 5 | AC-05 |
| AC-06 | 文档一致 | §2 步骤 3 | AC-06 |

## 2. 实现顺序、垂直切片与检查点

1. 步骤 1：门禁与自检同步删减（D1、D2、D3、D4、D6）：改 `ai-gate.sh`、配置加载与 `template/harness/redlines.conf`，同步删改自检用例并新增 G2/G6 结构化用例（「通过；」「通过，」「通过 」「通过」「通过率」「不通过」「`通过`」七个样本）；跑自检，此时 G4 仍调用知识卡，只看被改节。
2. 步骤 2：知识卡删除（D5）：删 `ai-knowledge.sh`、根转发、模板卡片与 `.knowledge/`，改 `ck_g4`/`ck_g5`、`ai-new-spec.sh`、`ai-resume.sh`、doctor；删自检第 11 节；跑自检。
3. 步骤 3：模板与指南：requirements / design / tasks / acceptance 模板，`template/AGENTS.md`，各 skill，`code-review.md` 新增两项，`harness/CI.md`、`template/MEMORY.md`；`ai-check-bloat.sh` 通过。
4. 步骤 4：CLI `upgrade` 已删除托管文件处理与 `tests/cli-upgrade.sh` 用例；`retrofit --dry-run` 冒烟。
5. 步骤 5：README、模块活文档、00-INDEX、本仓库 `.knowledge/` 删除；`grep` 核对 AC-01 关键字；正式验证。

- **检查点**：
  - 检查点 1（步骤 2 后）：`bash scripts/harness-selftest.sh` 全部通过，第 2~5、7~10、12、13 节保留项断言仍在。
  - 检查点 2（步骤 4 后）：`bash tests/cli-upgrade.sh` PASS，`bash -n bin/ai-harness`，`retrofit --dry-run` 冒烟无写入。
  - 检查点 3（步骤 5 后）：AC-01 的 `grep` 为空，正式验证 PASS 且耗时低于 363 秒。
- **拆分自查**：每步触碰文件超过 5 个，但都属同一删除主题，且每步结束都可通过自检验证，不再细拆。
- 边界样本：G6 前缀、旧 .gates 列、已删除文件的改动 / 定制 / 篡改 / 缺失 manifest、dry-run，逐条如下：
  - G6 中 AC 行写「通过（失败 0 项）」应通过，「不通过」「通过率 80%」应被拒：前缀后须是行尾、空格或标点，「通过率」不算。
  - 旧 Spec 的 `.gates` 中 G3 第 5 列是委托哈希，新门禁不再读取，G5 仍按 5 列绑定。
  - 下游 `scripts/ai-knowledge.sh` 被本地改过或经 `--accept-custom` 定制时，保留并非零返回，第二次 upgrade 不再报告。
  - manifest 被篡改、写入非托管路径或模板仍存在的路径时，不进入删除流程。
  - manifest 缺失（旧安装）时，没有记录可比对，不删除任何文件。
  - 已删除路径在目标中是符号链接或父目录不安全：`safe_path` 预检拒绝，整次升级不写入。
  - `--dry-run` 下打印 `- <rel>`，文件与 manifest 都不变。

## 3. 接口契约与数据结构变更

### 3.1 数据库 Schema 变更
- 无。

### 3.2 核心接口 / 类型定义
- `ai-gate.sh pass <feat> <gate> [--force]`：去掉 `--by`；传入 `--by` 报「未知参数」。
- acceptance.md 字段格式：`- 冒烟或 E2E 证据：通过；<证据>`、`- 对照 AC 的检查结果：通过；<摘要>`、`- AC-xx：通过；<证据>`。
- 删除命令：`ai-knowledge.sh check|ttl|list|suggest|impact|usage`。
- `upgrade` 输出新增 `- <rel>`（已删除）与 `! <rel>（模板已删除…）`。

### 3.3 契约兼容性
- 在途 Spec：G6 对旧格式给出改写提示；需求中残留的 §6 评分表、tasks 中的知识行、design 中的委托行不再读取，不报错。
- `.gates` 旧记录（含 `human` 记录者、委托哈希）照常解析。
- 下游升级：`.knowledge/` 属项目状态，不删除，由项目自行处理；本次不改版本号（R2 统一发布）。

## 4. 影响面与涉及文件清单

- **新建文件**：
  - 无
- **修改文件**：
  - `template/scripts/ai-gate.sh`、`template/scripts/ai-new-spec.sh`、`template/scripts/ai-resume.sh`、`template/scripts/harness-selftest.sh`、`template/harness/redlines.conf`、`template/harness/CI.md`、`template/MEMORY.md`、`template/AGENTS.md`
  - `template/docs/specs/_templates/requirements.md`、`template/docs/specs/_templates/design.md`、`template/docs/specs/_templates/tasks.md`、`template/docs/specs/_templates/acceptance.md`
  - `template/.agents/skills/new-spec.md`、`template/.agents/skills/code-review.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/gc-memory.md`、`template/.agents/skills/retrofit-legacy.md`
  - `bin/ai-harness`、`tests/cli-upgrade.sh`、`README.md`
  - `docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`、`docs/architecture/modules/self-hosting.md`、`docs/architecture/modules/cli.md`、`docs/architecture/00-INDEX.md`
- **删除文件**：
  - `template/scripts/ai-knowledge.sh`、`scripts/ai-knowledge.sh`、`template/.agents/skills/knowledge-distill.md`、`template/docs/specs/_templates/knowledge-card.md`、`template/.knowledge/INDEX.md`、`template/.knowledge/cards/.gitkeep`、`.knowledge/INDEX.md`、`.knowledge/cards/K-0001.md`
- **只读依赖契约**：
  - `template/scripts/ai-config.sh`
  - `template/scripts/ai-verify.sh`
  - `template/scripts/ai-state-id.sh`

- 间接消费者 / 副作用：下游项目 upgrade 后门禁放宽（含糊词、G6 措辞不再机器拦截），由 `code-review.md` 两项检查承接；在途 Spec 的 acceptance.md 需改写；Codex / Claude 薄技能（`skill/`）经检索不引用知识卡、委托或含糊词，无需改动；`hash_text` 只被委托逻辑调用，随之删除。
- 检索依据：`grep -rlI` 关键字 `含糊词`、`G6_SCAN|G6_PASS|g6_scan`、`FEASIBILITY|可行性`、`委托|delegation`、`ai-knowledge|知识卡|.knowledge|KNOWLEDGE_TTL|knowledge-distill|注入知识|knowledge_feedback`、`--by` 于 `template bin skill scripts tests README.md AGENTS.md docs/architecture harness`；`managed_file()` 确认被删托管文件为 `scripts/ai-knowledge.sh`、`.agents/skills/knowledge-distill.md`、`docs/specs/_templates/knowledge-card.md`。
- 复用检索：upgrade 已删除文件处理复用现有 `safe_path`、`file_hash`、manifest 三列格式与 `COPIED/SKIPPED/CONFLICTS` 计数，不新增元数据文件。

## 5. 对抗自审

1. 最可能错在哪：删除时误伤保留项（如 `hash_text` 被红线基线使用、`field_ok` 被多处共用）。对策：删除前 `grep` 每个函数的调用者；检查点 1 逐节核对保留项断言。
2. G6 前缀判定再次变成自然语言边角：只判断前缀与紧随字符集合，不解析证据；用例只覆盖前缀，不为措辞补豁免。
3. `knowledge_feedback` 是 review / tasks 中的通用反馈字段，非知识卡专属——保留为「反馈」字段还是删除？按 ADR 只删知识卡机制，`knowledge_feedback` 改名风险大于收益，保留原名并说明它反馈规则与记忆。
4. upgrade 删除文件不可逆：只删与 manifest 本地哈希一致（即用户没改过）的托管文件，且 dry-run 先预演；Git 可恢复。
5. 能否更简单：upgrade 只打印已删除文件让人手删——但「下游只升级一次」要求本次完成，且旧 `knowledge-distill.md` 残留会继续指导 Agent 建卡，选择自动删除未改动文件。

- 独立设计审查：
  - 审查者：本会话独立 subagent（新上下文、只读，未参与编写；维护者指定）。
  - 结论：通过，附 1 项须在实施前补进的安全问题——upgrade 删除条件未排除 `--accept-custom` 定制文件（`old_source != old_local`），且 manifest 路径不可信，缺少 `managed_file` 与模板不存在的校验。已改入 §1 CLI 与 §2 边界样本。
  - 采纳的非阻塞建议：
    - `safe_path` 放入全量预检；
    - 已删除文件冲突使用单独提示；
    - dry-run 不写 `$tmp`；
    - G6 标点集合与七个样本；
    - 旧格式提示；
    - 第 5 列注释为保留列；
    - 保留 `sha` / `field_value`；
    - 用法注释、`code-review.md` 知识检索字段、`knowledge_feedback` 措辞、`retrofit-legacy.md` 委托段、`cli.md` 删除语义；
    - AC-04 落点统一为 `tests/cli-upgrade.sh`；
    - AC-05 以行数为硬指标、耗时只记录；
    - 步骤 1 只看被改节。
- **自审结论**：可实施。

## 6. 待确认问题
- 无（前置决策见 §0）。

## 7. 风险与回滚
- **风险**：门禁放宽后含糊措辞与矛盾证据漏到交付；由 G5 清单与人工 G6 承接。upgrade 误删：限于哈希一致的托管文件。
- **回滚方式**：`git revert`；下游重新 upgrade 会按模板恢复文件。
