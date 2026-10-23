# 代码审查报告 (Code Review): feat-t-000014

- **审查者**：独立 G5 subagent（Claude Code / Opus 5.5，新上下文；未参与实现、设计与设计审查）
- **未参与实现**：是
- **审查时间**：2026-10-23
- **审查范围**：`git diff d78181c...HEAD`（f17b4f9），工作区干净；design.md §4 文件清单：`template/scripts/ai-state-id.sh`、`template/scripts/ai-verify.sh`、`template/scripts/harness-selftest.sh`、`template/AGENTS.md`、`template/.agents/skills/archive-spec.md`、`template/.agents/skills/retrofit-legacy.md`、`README.md`、`docs/architecture/modules/template-mechanism.md`、`docs/architecture/modules/guidance.md`；只读核对 `template/scripts/ai-task-pool.sh`、`template/scripts/ai-gate.sh`（ck_g4/ck_g5/ck_g6）
- **CR 轮次**：1 / 4
- 审查状态：d4fa14bb50a16d85bae9317dc97be147bbc6c5e55541223e388e1110ad6f8d06

我没写过这段代码，只依据需求、设计、diff、验证摘要和我自己的沙箱实测判断。

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：4
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无。

## 改进建议（非阻塞，"改善即批准"）
1. **AC-02 的相近路径只测了未跟踪文件**（`harness-selftest.sh:779-783`）：`docs/task-pool-x/a.md` 是未跟踪新文件，只经过未跟踪 `case`；pathspec 一侧没有相近路径的反例。若将来把 pathspec 误写成 `':(exclude)docs/task-pool*'`（非 glob 魔法下 `*` 可跨 `/`），会把已跟踪的 `docs/task-pool-x/**`、`docs/task-poolz` 一起排除，现有用例抓不到。建议把相近路径文件提交后再修改一次，断言指纹变化；`docs/task-poolz` 边界样本也可顺手补上。
2. **AC-01 是间接证明**：任务原件写的是「自检覆盖 Spec 进行中 intake 后 G6 不判摘要过期」，自检只比对 `ai-state-id.sh` 指纹相等。我核对了 `ai-gate.sh` 的 `ck_g6`→`ck_g4` 链路，G6 中与代码状态相关的判断只有 `ck_g4` 的 state 比较，`ck_g5` 也只比 review.md 与 verification.md 的 state，所以推导成立，design §2 检查点也写明了理由。G6 验收时建议在 acceptance.md 写清 AC-01 依据的是这条推导，而不是端到端门禁用例。
3. **拒绝文案对任务池不完全贴切**（`ai-verify.sh:46`「归档时会移动或更新的流程文件」）：任务文件归档时不移动，只在 `start`/关联时被改写。design §5.3 已说明为保留既有断言而沿用，可接受；以后若改文案，可改成「流程记录」并同步自检断言。
4. **既有限制，非本次引入**：在大小写不敏感的文件系统（Windows / macOS 默认）上，`Docs/task-pool/T-000001.md` 这类大小写变体能通过 `ai-verify.sh` 的 `case` 检查（`docs/specs/**` 同样如此）。由于目标文件本身始终按 `target:` 单独哈希，这不会让代码改动逃过重验，只影响「目标归档后稳定」这一约定。可列入 G6 关注点，不阻塞。

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | 不适用 | 本地 Bash 门禁脚本，无用户身份 |
| 鉴权中间件 | 不适用 | 无服务入口 |
| SQL 参数化 | 不适用 | 无数据库；路径只进 `case` 模式与 git pathspec 常量，没有拼接用户文本 |
| 无敏感信息硬编码 | ✅ | diff 中无密钥、token 或内网地址 |
| 入参边界校验 | ✅ | 带斜杠目录前缀（`ai-state-id.sh:103,131-134`，`ai-verify.sh:45`）；`./` 前缀先剥离，`docs//`、`docs/./` 由既有规范化检查拒绝 |
| 资源归属校验 | 不适用 | 无多用户资源 |

## 需求追溯与项目知识（追溯版本 1 的 Spec 必填）
- 需求追溯核对：REQ-01~02、ERR-01~02、AC-01~05 均有实现与证据，未发现超出需求的行为（未改 `redlines.conf`、未排除 `docs/INTAKE.md`、未改任务池脚本行为、未加可配置排除目录）。
  - REQ-01：全仓模式三处排除一致——`git ls-files --stage` 与 `git diff --binary` 的 `:(exclude)docs/task-pool/**`、未跟踪循环的 `case`（`ai-state-id.sh:131-134`）。沙箱另测：嵌套子目录 `docs/task-pool/sub/deep.sh` 未跟踪、暂存、提交后指纹不变；`docs/task-pool/.gitattributes` 只作用于自身子树，不影响其他文件，指纹不变。
  - REQ-02：未归属检查 `case`（`:103`）跳过任务池；四个来源（基准到 HEAD、未暂存、已暂存、未跟踪）都经过同一个 `case`。精确清单模式只哈希 SCOPE 内路径，排除只影响「是否回退全仓」，与 design §1 一致。
  - ERR-01：`ai-verify.sh:45` 加 `docs/task-pool/*`，在剥离 `./` 之后匹配。
  - ERR-02：沙箱实测 `docs/task-poolz` 计入指纹；自检覆盖 `docs/task-pool-x/a.md` 与 `scripts/ai-task-pool.sh`。
  - 变异测试（我在 scratchpad 拷贝 `template/` 独立做的，每个变异跑一遍完整自检）：去掉未归属 `case` → 1 例失败（精确清单用例）；去掉 pathspec → 5 例失败（提交、未暂存、暂存、补充提交、删除）；去掉未跟踪 `case` → 1 例失败（intake 用例）；去掉 `ai-verify.sh` 的任务池 `case` → 2 个目标拒绝用例失败（另有 1 例 G6 夹具用例失败，推测是验证在任务池目标上实际运行后改动了夹具状态引起的连锁失败，未深究）。三处排除和目标检查都由用例单独证明，与 tasks.md 记录一致。
  - 绕过重验的可能：只有让代码、构建或符号链接引用 `docs/task-pool/` 内容才能绕过；`template/AGENTS.md:58` 已写明这三处「代码与构建不得引用，也不写进 §4 清单」，design §5.3 列出 `GIT_ICASE_PATHSPECS` / `GIT_LITERAL_PATHSPECS` 的非默认配置影响（后者偏保守）。任务池脚本写入的 `.lock`、`.link.XXXXXX` 临时文件都在该目录内，同样被排除，不影响指纹。
  - 文档一致性：README、`template/AGENTS.md`、`archive-spec.md`、`template-mechanism.md`、`guidance.md`、`ai-state-id.sh` 头注释对流程记录的三项范围表述一致；`retrofit-legacy.md` 的升级说明与 design §3.3 一致（`scripts/ai-state-id.sh` 在两种模式都计入，升级后在途 Spec 须重验）。
- 知识检索：`ai-knowledge.sh suggest 模板机制` 只给出 K-0001（多字节匹配），本次改动只是 ASCII 路径前缀，不适用；tasks.md 的判断成立。
- AI 协作文件审查：改动了 `template/AGENTS.md` 验证口径与两个技能（`archive-spec.md`、`retrofit-legacy.md`）。新增内容是确定性约束（不得引用、不写进 §4），与脚本行为一致，没有与其他规则冲突，也没有私有调试信息。
- 审查范围限制：没有在本仓库重跑无变异的完整自检，以 verification.md 的 PASS（state d4fa14bb…8d06，`ai-gate.sh check g4` 本次复核通过）和 tasks.md 记录的两种 locale 下 258/258 为准；变异测试只在默认 locale 下运行；未在 macOS / Linux 上实测大小写与 pathspec 行为。

## 验证证据（只放命令与结果摘要，不贴全文）
- `bash scripts/ai-gate.sh check feat-t-000014 g4`：通过（当前指纹与摘要 state 一致）
- 四个变异版本的 `harness-selftest.sh`：均失败，失败项与对应排除逐一对应（见需求追溯核对）
- 沙箱 Git 仓库：嵌套任务池文件、子树 `.gitattributes`、`docs/task-poolz` 三类边界按预期计入或排除

knowledge_feedback: 无
