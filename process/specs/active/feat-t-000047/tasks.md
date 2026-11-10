# 任务与接力：feat-t-000047

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000047` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：都是在现有句子里加半句或一句，不加文件、脚本和配置键，脚本一行不改；`template/AGENTS.md` 只在原有的行里加，行数不变。逐项写法：
  - 记忆（`template/AGENTS.md` §4「同一件事只留一个当前答案。」之后）：「AI 工具自带的记忆不作来源，换工具就读不到：要记的写进上述文件，不宜入库的项目事实写进本项目的 `PREFERENCES.md`。」`template/PREFERENCES.md` 的说明同步成「记你自己的习惯……；不宜入库的项目事实（如涉及非公开信息）也记在这里」。不新开文件：不入库又每次接手都会读的位置只有它。
  - 暂缓与取消（`template/AGENTS.md` §1 第 2 条，「加一行 `- 优先: 是`」之后）：「，说暂缓或不做了，把 `队列状态` 改成 `暂缓` 或 `取消`」。脚本早就认这两个值，只是没有文档提到。
  - 小改动（同一条末尾）：「只有源码注释和说明文档（README、`docs/`）里不改变意思的错别字与措辞可以直接改完提交、不进任务池，前提是没有活跃 Spec；拿不准就收录。」只列放行的，不列排除的：规则、指南、配置、模板和脚本里的字符串都不在列。
  - README：「安全与局限」加一条，说明装了 WSL 的机器上 PowerShell 里的 `bash` 是 WSL，门禁与指纹两边一致（靠 `.gitattributes` 统一换行），`CUSTOM_CHECK` 在调用它的那个环境里运行，WSL 里的 `~` 不是 Windows 用户目录；并写明 WSL 下只是实测一致，CI 只在 Git Bash 上跑。前置条件那一行指向这条说明，英文版加一句。「只支持 Windows」不动。
  - 换行注释：两个 `.gitattributes` 的注释改成「统一 LF 换行：CRLF 会破坏 shell 脚本；Git Bash 与 WSL 的默认换行设置不同，统一后两边算出的状态指纹才一致」。
- 改动文件：`template/AGENTS.md`、`template/PREFERENCES.md`、`template/.gitattributes`、`.gitattributes`、`README.md`、`README.en.md`、`docs/architecture/modules/guidance.md`、`MEMORY.md`；本机不入库的 `PREFERENCES.md`。
- 影响与风险：
  - 依据（2026-11-09 实测）：本机 PowerShell 里的 `bash` 是 WSL；自检在 Git Bash 与 WSL（bash 5.3、git 2.53）下都是 76 项、失败 0 项；有 `* text=auto eol=lf` 时两边指纹一致，没有时不一致。本仓库 `MEMORY.md` 只有 1 条，而 Claude Code 的记忆目录有 6 条，其中 2 条只存在那里。
  - 小改动出口会减少走门的改动。判断仍由 AI 做，所以只列得出的才放行，并加「拿不准就收录」；有活跃 Spec 时不放行，因为状态指纹按全仓算，一次小改动就会让它的验证过期。
  - `template/AGENTS.md` 第 7 行和第 37 行本来就长，这次再加约 150 个字；行数上限管不到单行长度，是否值得由维护者在 g3 看最终措辞决定。
  - 搜索过：README 第 75、169 行和 `skill/SKILL.md` 第 32 行提到 `PREFERENCES.md` 的说法与新说明不矛盾，不改。
- 方案审查（2026-11-09，独立 subagent 上下文，只读）：初版有三条「必须改」，都已采纳。
  - 平台范围：初版把「只支持 Windows」改成按 Bash 写、CI 加 `ubuntu-latest`。审查指出「宿主」在本仓库一直指 AI 工具，原话推不出要支持 Linux，这类歧义按 `new-spec.md` 该先问人。现已移出本需求，另行问维护者。
  - 小改动出口：初版写「错别字、注释、说明文档的措辞；`AGENTS.md`、指南与 `harness/` 除外」。审查指出「文档」会带出 `MEMORY.md`、Spec 模板等规则级文件，「注释」会带出脚本里的字符串，有活跃 Spec 时会让验证过期，也没有拿不准时的退路。现改成只列放行项的写法。
  - 缺配置的报错文案：审查指出在子目录里运行 `bash scripts/…` 根本到不了这条报错。连同括号开头原话的误报一起砍掉，两项在归档 Spec 里都没出现过。
  - 审查另外指出 WSL 里的 `~` 不是 Windows 用户目录，通用偏好会读不到，已写进 README 那条说明。
  - 复核（同一审查上下文）：三条都已解决，没有新的「必须改」。按建议把「代码注释」改成「源码注释」（免得带出 `harness/` 配置里的注释）、README 写明 WSL 只是实测一致、AC-05 的证据改成可直接判定的命令。
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：规则入口、偏好说明与活文档
  - 对应验收：AC-01、AC-02、AC-03、AC-04、AC-07
  - 涉及文件：`template/AGENTS.md`、`template/PREFERENCES.md`、`docs/architecture/modules/guidance.md`
  - 验证：AC-01～AC-04、AC-07 的命令
- [ ] Task 2：换行注释与 README 说明
  - 对应验收：AC-05、AC-06
  - 涉及文件：`template/.gitattributes`、`.gitattributes`、`README.md`、`README.en.md`
  - 验证：AC-05、AC-06 的命令
- [ ] Task 3：把只在 AI 工具记忆里的两条搬回项目
  - 对应验收：AC-08、AC-09
  - 涉及文件：`MEMORY.md`、`PREFERENCES.md`
  - 验证：AC-08 的命令；全部任务完成后跑自检、体积检查和正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `README.md` 前置条件、根 `AGENTS.md`、ADR-0003 / 都写「只支持 Windows（Git Bash）」，而 PowerShell 壳的工具实际在 WSL 里跑这些脚本，自检也通过 / 是否放开由维护者决定，已另行询问
- `template/scripts/ai-gate.sh` 的 `filled()` / 原话以括号开头时报「未填」；`template/scripts/ai-config.sh` / 用上级路径在子目录运行时提示「从模板补齐」/ 没有真实案例，出现了再收录

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 2
- 已完成：需求与方案；方案已由独立上下文审过并按结论改完
- 已完成：Task 1。AC-01～AC-04、AC-07 的命令都按预期输出；`template/AGENTS.md` 仍是 39 行，从 6369 字节增加到 6790 字节。
- 已排除的方案：为不宜入库的项目事实新开一个文件（维护者定过不加文件）；小改动出口用「除外」清单（列不全，见方案审查）
- 下一步：改两个 `.gitattributes` 的注释和 README 的说明
