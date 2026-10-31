# 需求：feat-t-000038

- 创建时间：2026-10-30
- **需求来源**: `process/task-pool/T-000038.md`（原始需求与更新）
- 原始问题 / 原话：「阅读文章https://claude.dev/blog/solving-code-review-at-anthropic/，你觉得有值得本脚手架学习的点吗？本脚手架是独立的，不依赖宿主的；只取用好用的功能、必要的功能，不要学习会使脚手架变得臃肿、累赘的功能，根据今天的AA排行榜，能关注到最新的大模型的能力，有些功能在AI发展到当前阶段，可能已经不需要了，所以也要避免过时的功能；文章阅读要文字和图片都进行阅读，进行深入理解和学习」；AI 提出 9 处改动后：「1.按这9处改；2，接受副作用；3.推荐怎么做？什么时候做？」
- 需人决定：是，改的是审查的拦截标准和什么时候叫人（架构取舍），g3 要维护者对结果的当次决定

## 1. 要做什么
- 做什么：按 Claude Code 团队的审查实践补 5 处（审查者按实际改动复核「需人决定」、审查对照 `MEMORY.md` 与模块活文档、关键问题只算本次引入或加重的、接入时选能证明行为的验证命令、模块活文档只写「为什么」），删 4 处过时或重复的文字（审查开场声明、上下文上限提醒、WIP 里手写的「正在编辑的文件」、审查指南里与 `ai-resume.sh review` 输出重复的必读清单），并删掉无人读取的 `knowledge_feedback` 行；第 3 问按 AI 的推荐一并做（维护者问的是推荐，g3 前可否决）：`verify.conf` 前两个示例换成跑测试的命令。
- 为谁做：接入脚手架后按 `AGENTS.md`、`code-review.md`、`skill/SKILL.md` 干活的 AI，以及在 g3 拍板的维护者。
- 不做：不加文件、脚本、配置键；不改门禁脚本逻辑与红线；不做多代理审查、风险分级、度量、快速通道；不删 `template/CLAUDE.md`；「需人决定」不加「对话里已拍板」的例外（维护者已接受这个副作用）。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `code-review.md` 需求条目写明：按实际改动「需人决定」应为「是」却写「否」的按关键问题处理，判据只引用 `new-spec.md`，没有例外条款 | `grep -n "判据见" template/.agents/skills/code-review.md` 命中 1 行；`grep -c -e "除外" -e "例外" template/.agents/skills/code-review.md` 为 0 |
| AC-02 | `code-review.md` 规则与文档条目要求对照 `MEMORY.md` 与改动涉及模块的活文档，重蹈已记录的坑或让其中某句不再成立的按关键问题；`knowledge_feedback` 在 `template/` 与 `skill/` 中不再出现 | `grep -n "改动涉及模块的活文档" template/.agents/skills/code-review.md` 命中；`grep -rn knowledge_feedback template skill` 无输出 |
| AC-03 | `code-review.md` 的关键问题定义限定为「本次改动引入或加重的」 | `grep -n "本次改动引入或加重" template/.agents/skills/code-review.md` 命中 |
| AC-04 | `skill/SKILL.md` 验证命令一步要求能证明行为的检查（有测试就跑测试，不要只跑 lint），不再出现「单个文件」；`template/harness/verify.conf` 前两个示例为 `npm test` 与 `python -m pytest -q` | `grep -c "单个文件" skill/SKILL.md` 为 0；`grep -n "有测试就跑测试" skill/SKILL.md` 命中；`grep -n -e "npm test" -e "pytest -q" template/harness/verify.conf` 命中 2 行 |
| AC-05 | 模板 `00-INDEX.md` 写「只写「为什么」与已知坑」，不再要求写职责、契约 | `grep -n "只写「为什么」与已知坑" template/docs/architecture/00-INDEX.md` 命中；`grep -c "职责、契约" template/docs/architecture/00-INDEX.md` 为 0 |
| AC-06 | 已删：审查开场声明、`template/AGENTS.md` 的「上下文明显变慢…」、tasks 模板的「正在编辑的文件」（`AGENTS.md` 括号改为「进度、已排除的方案、下一步」，自检夹具同步）、`code-review.md` 第 2 步第 1 条的必读清单（改为按 `ai-resume.sh review` 的输出读） | `grep -rn -e "我没写过" -e "上下文明显变慢" -e "- 正在编辑的文件：" template` 无输出；`grep -n "进度、已排除的方案、下一步" template/AGENTS.md` 命中；`grep -n "按它的输出" template/.agents/skills/code-review.md` 命中 |
| AC-07 | 本仓库模块活文档补「为什么」：`guidance.md` 一条（审查的三处改动）、`install-skill.md` 一条（验证命令要能证明行为） | `grep -n "复核「需人决定」" docs/architecture/modules/guidance.md` 命中；`grep -n "证明行为" docs/architecture/modules/install-skill.md` 命中 |
| AC-08 | 自检失败 0；体积检查通过；`template/AGENTS.md` 由 40 行变 39 行；不新增文件；提交后按 `skill/SKILL.md` 在临时目录实际接入一次新项目，接入后的自检、体积检查与门禁状态都通过 | `bash scripts/harness-selftest.sh`；`bash scripts/ai-check-bloat.sh`；`wc -l template/AGENTS.md`；`git diff --stat --diff-filter=A 6530988 -- template skill docs` 无输出；接入记录写进 tasks.md WIP 区 |
