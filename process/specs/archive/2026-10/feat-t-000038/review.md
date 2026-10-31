# 审查：feat-t-000038

- 审查者：独立 subagent（Claude，全新上下文，未参与实现），整合两路独立视角（需求与范围、规则正确性）的审查并逐条复核
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：873607831dfdada1108bb39f442f60cb7aaf64c95d192e1061412a41ed26c526
- 审查范围：6530988...HEAD + 工作区（未提交的 .gates 与未跟踪的 verification.md）

## 结论
- 关键问题：0
- 改进建议：7
- 人工决定：通过
- 决策来源：对话（2026-10-31），维护者原话「通过，把1到4收成下一个任务并开始执行；」；此前已呈现关键问题 0、改进建议 7 及行为变化：无「对话已拍板」例外、老问题只记录不挡门、删 knowledge_feedback、第 3 点示例为 AI 推荐（已失败或不稳定的测试会挡 g2）

AC-01~08 全部满足；没有本次改动引入或加重的缺陷，也没有被它改成错误的文档句子；「需人决定：是」判定正确，须保留。7 条建议都不阻塞，按「改善即批准」只记录。g3 现在缺的只有维护者的当次决定。

## 关键问题
无。两路审查者提出的候选逐条核对后，均降为改进建议或剔除，理由见下。

## 改进建议
按根 MEMORY.md：只记进「发现但不碰」，不当场修，不回退 g2；同模块的建议归档时合并成一条任务，经 `archive-spec.md:17` 告知维护者。
路径简写：`SKILL.md` 即 `skill/SKILL.md`；`verify.conf`、`AGENTS.md`、`00-INDEX.md` 指 `template/` 下的同名文件（`00-INDEX.md` 在 `template/docs/architecture/`）；`code-review.md`、`new-spec.md`、`archive-spec.md` 在 `template/.agents/skills/`；`guidance.md`、`install-skill.md` 在 `docs/architecture/modules/`；`tasks.md`、`requirements.md` 指本 Spec 的文件。
1. `tasks.md:46,48,50`（过程记录，归档前更新 WIP 即可，process/ 不进指纹）：:46「待正式验证与独立审查」与 :50「下一步：过 g1，按 Task 1~4 顺序改」都与 .gates（g1、g2 已过）不符，`ai-resume.sh:77-78` 会原样打印；:48 把「实测 pytest -q 退出 5」和「本机没有 pytest」并排，易读成矛盾（我用 `uvx pytest -q` 在空目录复现退出 5，应注明是临时环境）。
2. `verify.conf:6`、`SKILL.md:24`：第三个示例 `go vet ./...` 是纯静态检查，与新写的「不要只跑 lint」并存。tasks.md:42 已记「发现但不碰」（`go test ./...` 零用例退出 0，违背 verify.conf:3），该行是原有内容、没有被改成错误，故不阻塞；可日后删去这一行，或注明「仅静态检查，有测试时自行加零用例保护」。
3. `SKILL.md:24`：接入时 g2 默认改成整库测试后，存量失败或不稳定的测试会挡住所有需求，并消耗 `VERIFY_MAX_ATTEMPTS`（`ai-verify.sh:52-57`，触顶停下等人，见 `template/AGENTS.md:33`）；tasks.md:10 只记了「可能变慢」。「实际跑一次确认可用」能暴露，但没写已红怎么办，可补半句「现有测试已失败或不稳定时先问人」。这条副作用请维护者在 g3 一并确认或否决。
4. `code-review.md:21`、`:19`：「引入或加重」没有边界，新调用点把未校验输入交给既有的拼 SQL 函数这类容易被当成老问题放过，可补半句「新增调用点、扩大影响面、让老缺陷更易触发也算加重」；:19 分号后的旧半句（矛盾、过时内容、一次性经验）原本没有定级，现在紧挨着「按关键问题处理」，易被整体升级为阻塞，可拆成两条或句末补「其余记改进建议」（与 :52 不把偏好写成阻塞项一致）。老问题仍进「发现但不碰」，不会丢。
5. `code-review.md:15`：「应为是却写否」只写了拦截，没写补救路径。改成「是」后 `new-spec.md:22` 要求的编码前审方案已经错过，是补审还是由 g3 人工决定兜底？`template/AGENTS.md:17` 的 reset 是否适用？实际 `ai-gate.sh:52` 在 g3 现读 requirements.md，不 reset 也会要求人工决定，可补一句「改为「是」后由 g3 人工决定兜底」。
6. `install-skill.md:7`：两个提交号与事实经 git 核实（fee16ca 删除 `ai-verify.sh` 里的 Vitest/Pytest 关联单测探测；1e6697b 引入「能对单个文件跑的检查」），但时间顺序相反：1e6697b（06:56:37）早于 fee16ca（07:11:22），当时探测还在，「又」易读成它在后。可改为先写 1e6697b 再写 fee16ca；纯措辞。
7. `SKILL.md:18、:25`、`00-INDEX.md:8`、`archive-spec.md:6`：新项目流程第 2 步仍只说「一条真实检查命令」，「能证明行为」只写在已有项目流程 :24，可补「选法同第 2 节第 4 条」；活文档改为只写「为什么」后，试点模块由只读过代码的 AI 来写，原因写不出时可能编造，可在 :25 补「写不出原因就留空」；`archive-spec.md:6`「公共契约…写进 docs/architecture/」与新措辞的张力早就存在于它和 `template/AGENTS.md:36` 之间，已记在 tasks.md:41，可改为「登记进 00-INDEX（含公共契约入口）」。

## 证据
- 验证：verification.md `result: PASS`，target `template/.agents/skills/code-review.md`，state 同上，verified_at_utc 2026-10-31T05:11:11Z；`bash scripts/ai-state-id.sh` 现算值与之一致，`ai-gate.sh check feat-t-000038 g2` 通过；审查全程未改仓库，仅新增本文件。
- 自检与体积：`harness-selftest.sh` 72 项、失败 0（`LC_ALL=C` 复跑同为 72/0）；`ai-check-bloat.sh` 🟢；`wc -l template/AGENTS.md` 为 39（基准 40）；`git diff --check 6530988 HEAD` 无输出；`git diff --name-status 6530988 HEAD` 的新增文件只在 process/ 下。
- AC-01 满足：`code-review.md:15` 是「判据见」唯一命中，指向 `new-spec.md:12`；`grep -c -e 除外 -e 例外` 为 0。
- AC-02 满足：`code-review.md:19` 命中「改动涉及模块的活文档」；`grep -rn knowledge_feedback template skill` 无输出；该字段原是知识卡飞轮（`gc-memory.md`，459dd82 已删）的输入，base 里只剩 `code-review.md:53` 一处，`git log -S knowledge_feedback -- template/scripts scripts bin tests` 无结果，无人读取。
- AC-03 满足：`code-review.md:21` 命中「本次改动引入或加重」；:22「发现但不碰」、:23「改善即批准」保留，与根 MEMORY.md 的唯一条目一致。
- AC-04 满足：`grep -c 单个文件 skill/SKILL.md` 为 0；`SKILL.md:24` 命中「有测试就跑测试」；`verify.conf:4-5` 恰为 `npm test`、`python -m pytest -q`。零用例实测：`npm test`（默认脚本与缺脚本）退出 1，`python -m unittest discover -q` 与 `uvx pytest -q` 空目录退出 5；`node --test` 零用例退出 0，所以 verify.conf:3 的空目录实跑不可省。
- AC-05 满足：`00-INDEX.md:8` 命中「只写「为什么」与已知坑」，「职责、契约」为 0 处，与 `template/AGENTS.md:36` 一致。
- AC-06 满足：`grep -rn -e 我没写过 -e 上下文明显变慢 -e "- 正在编辑的文件：" template` 无输出；`AGENTS.md:31` 命中「进度、已排除的方案、下一步」；`code-review.md:12` 命中「按它的输出」，`ai-resume.sh:46-51` 的 review 输出仍含旧必读清单的全部项；`ai-resume.sh:104` 的同名标题来自 git，按方案保留；「未参与实现：是」仍由 `ai-gate.sh:101` 强制，删开场声明没有功能损失。
- AC-07 满足：`guidance.md:8`、`install-skill.md:7` 命中；`guidance.md:8` 的「唯一开关」「不进状态指纹」与 `ai-gate.sh:52、:109-111`、`ai-state-id.sh:15` 一致；「取自 Claude Code 团队的审查实践」未能访问原文，按 Spec 采信，不影响结论。
- AC-08 满足：用 `git archive HEAD template` 的 24 个文件在临时目录新建项目（commit=e84a140），自检 72/0、体积检查 🟢、`ai-gate.sh status` 正常；`git diff 1fe4577 HEAD` 只有 tasks.md，故 tasks.md:48 记录的试装即最终内容；template+skill 净减 65 字节、9 个文件 +14/−14 与记录一致。「ai-new-spec→g1→ai-verify→g2」一段按规定我未运行，采信 tasks.md:48。
- 夹具：在临时副本里把 `ck_g2` 改成「目标出现在 tasks.md 任意位置即可」，新旧两版 t-wiponly 夹具都在同一条断言上失败，字段名改成「下一步」后断言含义不变。
- 范围：9 个改动文件与 `tasks.md:7` 逐一相同，行级 diff 没有需求之外的改动；两份 redlines.conf、`ai-*.sh`、根目录 `scripts/` 无 diff，verify.conf 只改注释行；README、upgrade.md、new-spec.md、docs/ 对被删措辞 `git grep` 无残留。
- 活文档与记忆：根 MEMORY.md 仅一条（审查的非阻塞建议不当场修），未重蹈；`guidance.md`、`install-skill.md`、`template-mechanism.md`（:8、:10 仍成立）、`self-hosting.md` 与 ADR-0003 第 2 节逐句核对，没有一句被本次改动变假。
- 需人决定复核（判据 `new-spec.md:12`）：不涉及数据、权限、发布、不可逆操作；改的是 g3 的拦截标准（`code-review.md:21`）、何时叫人（:15）和接入时 g2 的默认取向（`SKILL.md:24`），属「架构取舍」，ADR-0003 第 2 节第 1 条把 g3 判定与「需人决定时有人的当次通过」列为架构决策，故 `requirements.md:6` 的「是」正确；改成「否」反而按 `code-review.md:15` 是关键问题。`ai-gate.sh:109-111` 因此要求本文件有人的「人工决定：通过」与「决策来源」，Agent 不得代填，现为待填。
- 请维护者在 g3 当次明确三点：(a) 删 `knowledge_feedback` 不在「补 5 删 4」里，是并行删除（`requirements.md:9`、AC-02 已写明）；(b) `verify.conf` 示例换成跑测试与 `SKILL.md:24` 是 AI 对第 3 问的推荐而非维护者指令（`requirements.md:9`），含建议 3 的副作用；(c) 「需人决定」不加「对话里已拍板」的例外，对话中的「按这 9 处改」不能替代本次决定（`requirements.md:11`）。
- 局限：按规定未运行 ai-verify、ai-new-spec、ai-task-pool、ai-gate pass/reset；没有读原文章，也没有对话里那份 9 处清单，映射以 requirements.md 为准。
