# 任务与接力：feat-t-000041

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000041` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：分许可证、版本、CI 三块，各写一条如下。
  - 许可证：根目录放标准 MIT 全文，不加别的内容，否则 GitHub 识别不出。接入项目不能得到根目录 `LICENSE`，否则新项目会被误标成 MIT，所以模板里放 `.ai-harness/LICENSE.md`，与 `.ai-harness/version` 同目录。
  - 版本：`.ai-harness/version` 继续记提交号（理由见 `install-skill.md`），tag 只决定默认取哪个版本。取法写死：先 `fetch --tags`，失败就停下问人，避免静默装到未发布的 HEAD；`tag --sort=-v:refname` 取第一个，避免 v1.10 排在 v1.9 前；`rev-parse <tag>^{commit}` 解析成提交号。`SKILL.md` 改为按 `git ls-tree` 与 `git show`（在 bash 里重定向写入）从所选版本读文件，不切换脚手架工作区，也就不再需要「工作区有未提交改动时先停下」这条。升级时未点名版本、目标又不比已装版本新，就停下问人，避免把升级做成降级。
  - CI：`shell: bash` 跑 `bash scripts/harness-selftest.sh`，换行由 `.gitattributes` 固定为 LF。
- 改动文件：`LICENSE`、`README.md`、`README.en.md`、`.gitignore`、`AGENTS.md`、`.github/workflows/selftest.yml`、`skill/SKILL.md`、`template/.ai-harness/LICENSE.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`、`docs/architecture/modules/self-hosting.md`。
- 影响与风险：
  - 已接入项目下次升级时多一个机制文件，没有迁移动作；旧的 `commit=` 因历史重写取不到时，`upgrade.md` 已有「取不到就当作改过」的处理。
  - 搜索过 `.ai-harness`：脚本和自检不读这个目录，`SKILL.md` 只用 `version` 文件判断是否已接入，新增文件不影响判断。
  - `.gitignore` 移除的锁文件规则已转到本机 `.git/info/exclude`。
  - 打 tag 前没有 tag，默认回退到 HEAD，与现状一致。
> 「需人决定：是」的需求，编码前让独立上下文只读审一遍方案，结论记在这里。
- 方案审查（独立 subagent，未写方案，2026-11-05）：无硬性阻断。已采纳：tag 取法写死、防止升级变降级、按版本读文件、上游无 LICENSE 文件时如实表述且不写版权行、AC-02 判定改为已跟踪、AC-03 列出检索词、AC-06/07 注明词表和映射表不入库。未采纳：CI 预先配置 Git 身份，改为在无全局配置的环境实测，需要才加。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：许可证与模板声明
  - 对应验收：AC-01、AC-02
  - 涉及文件：`LICENSE`、`template/.ai-harness/LICENSE.md`、`template/.agents/skills/upgrade.md`
  - 验证：运行 AC-02 的命令；AC-01 推送后核对
- [x] Task 2：版本选择规则
  - 对应验收：AC-05
  - 涉及文件：`skill/SKILL.md`、`template/.agents/skills/upgrade.md`、`docs/architecture/modules/install-skill.md`
  - 验证：按 AC-05 在临时目录实际接入两次
- [x] Task 3：README 与英文版
  - 对应验收：AC-03、AC-04
  - 涉及文件：`README.md`、`README.en.md`
  - 验证：逐条运行 AC-03、AC-04 的 `grep`
- [x] Task 4：隐私约束与失效提交号
  - 对应验收：AC-06、AC-07
  - 涉及文件：`AGENTS.md`、`.gitignore`、`docs/architecture/modules/install-skill.md`、`docs/architecture/modules/self-hosting.md`
  - 验证：运行隐私词表 `git grep` 与映射表核对
- [x] Task 5：自检 CI
  - 对应验收：AC-08、AC-09
  - 涉及文件：`.github/workflows/selftest.yml`
  - 验证：正式验证；推送后 `gh run list` 为 `success`

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `README.en.md:23` / 只写取最新 tag，没写无 tag 时取 HEAD / 改进建议，维护者确认后再收录
- `skill/SKILL.md:12` / 「已接入」让 AI 读工作区的 `upgrade.md`，可能比所选版本新 / 改进建议，维护者确认后再收录
- `template/.agents/skills/upgrade.md:5` / 第 2 步太长，防降级的停下条件容易被漏看 / 改进建议，维护者确认后再收录

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无
- 已完成：Task 1~5。AC-05 实测（2026-11-05，临时克隆，提交 2113beb）：同时有 v1.9、v1.10 两个 annotated tag 时取 v1.10，`commit=` 为解析后的提交号；模板文件与该 tag 一致，自检 72 项 0 失败；删除 tag 后取 HEAD，自检 72 项 0 失败。
- 已排除的方案：模板放根目录 `LICENSE`（会把接入项目误标成 MIT）；`SKILL.md` 用 `git checkout <tag>`（会动脚手架工作区）
- 下一步：归档后打 v2.1.0 并发 Release
