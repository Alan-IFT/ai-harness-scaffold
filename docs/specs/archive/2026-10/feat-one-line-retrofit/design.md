# 技术架构与接口设计：feat-one-line-retrofit

- 关联需求：requirements.md
- 设计者：Codex
- 状态：Approved

## 0. 模块关联
- 主模块：CLI 与安装 → `docs/architecture/modules/cli.md`
- 涉及模块：项目指南 → `docs/architecture/modules/guidance.md`
- 契约入口：`bin/ai-harness` 的 `install-skill` / `retrofit`；`skill/SKILL.md` 的发现元数据与接入指引
- 人工前置决策：决策人 维护者；依据本会话原话「为什么不做成skill或轻量工具呢？这样我直接给AI简单说一句就行」。取舍为保留已有 CLI 作执行器，选择共享技能加两个薄宿主入口；结论是按跨 IDE 与单一事实来源约束实现一句话接入。

## 1. 架构变更与数据流
用户对 Claude Code/Codex 说「把 <路径> 的老项目接入 ai-harness」；宿主按薄入口 frontmatter 发现技能，读取本仓库 `skill/SKILL.md`，再读 `template/.agents/skills/retrofit-legacy.md` 并按需调用 `bin/ai-harness retrofit`。目标项目内状态仍由 AGENTS、Spec、活文档与 Git 维护。薄入口仅存源路径，不复制步骤或脚本。

`install-skill --host codex|claude` 默认分别写到 `${CODEX_HOME:-$HOME/.codex}/skills/ai-harness-scaffold` 和 `$HOME/.claude/skills/ai-harness-scaffold`；`--dest` 指定完整技能目录供测试。旧无参数的 DSH 安装保持原样。管理标记含 host 与 source，同源重装可更新；已有非管理内容或异源标记拒绝覆盖。Git 归属用 `git -C <dir> rev-parse --is-inside-work-tree` 判断，兼容 `.git` 文件与父仓库。

## 2. 实现顺序、切片与检查点
1. 缩短共享技能入口，老项目细则仍在现有普通 Markdown 指南；更新 README 的一句话使用方式。
2. 扩展 CLI 安装器并验证 Codex/Claude 临时目录的薄入口、幂等、冲突拒绝；保留 DSH 路径。
3. 修复旧项目 Git 归属判断，用临时 worktree/父仓库样本验证；正式全量自检及独立审查。
- 检查点：第 2 步后确认只有一份流程正文；第 3 步后确认目标项目原文件和 Git 均未受意外覆盖。
- 边界样本：空目标、重复安装、异源标记、陌生技能目录、含空格源路径、`.git` 文件 worktree、父仓库子目录、已有 `.git` 目录、旧 DSH 安装。
- 拆分自查：安装与 Git 判断分切片；不扩展成插件或宿主服务。

## 3. 接口契约与兼容性
- `bash bin/ai-harness install-skill` 保持 DSH 默认；新增 `--host codex|claude`，`--dest` 含义保持“完整技能目录”。
- `bash bin/ai-harness retrofit <dir>` 参数不变，只修复已有 Git 判断；无 Git 时仍按原规则初始化。
- 生成的 SKILL.md 只用通用 frontmatter `name`、`description`，不写宿主私有规则；正文只有共享技能路径与读取指令。

## 4. 影响面与涉及文件清单
- 新建文件：无（全局薄入口由安装器生成，不入本仓库）。
- 修改文件：
  - `bin/ai-harness`：宿主技能安装与 Git 归属判断。
  - `skill/SKILL.md`：共享短入口，指向现有老项目指南。
  - `README.md`：一次安装和一句话用法。
  - `docs/architecture/modules/cli.md`：CLI 契约。
  - `docs/architecture/modules/guidance.md`：跨宿主单一流程来源。
  - `docs/INTAKE.md`：本需求原话和一次处理决定。
- 只读依赖契约：
  - `template/.agents/skills/retrofit-legacy.md`：渐进接入细则。
  - `template/scripts/harness-selftest.sh`：原有门禁自检。
  - `harness/verify.conf`：正式验证命令。
- 间接消费者 / 副作用：旧 DSH 使用者、Claude/Codex 用户技能目录、目标 Git worktree、单仓子目录；不改目标业务代码。
- 检索依据：已查 `bin/ai-harness` 的安装/retrofit 分支、`skill/SKILL.md`、README、模板指南与官方 Claude/Codex 技能路径说明。

## 5. 对抗自审
1. 最可能错在把薄入口复制成第二份流程；入口只保存元数据与源路径。
2. 默认假设源码仓库可从目标宿主读取；不可读时入口明确报源路径并让用户重新安装，不凭空执行。
3. 旧技能目录不能清理；管理标记不足以证明目录完全属于本工具时不得递归删除。
4. 不引入新的状态数据库、插件或服务，重用现有 Bash CLI。
5. 回滚提交并重新安装原 DSH 技能；Codex/Claude 薄入口可按标记手动移除。
- 自审结论：采用一个共享技能、两个薄适配器和既有 retrofit CLI。

## 6. 待确认问题
- [x] Q1：宿主安装是自动执行还是只提供命令？→ 先用临时目录验证，之后在本机按用户的一句话目标安装；不得覆盖现有陌生技能。

## 7. 风险与回滚
- 风险：本机全局技能指向本仓库绝对路径，移动仓库后需重装；旧工作区权限可能阻止宿主读取共享文件。
- 回滚方式：回退 CLI/技能提交；只删除带本工具标记的薄入口，保留目标项目文件。
