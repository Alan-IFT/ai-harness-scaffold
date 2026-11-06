# 任务与接力：feat-t-000045

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000045` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 思路：结构取大型开源项目的通行做法（徽章、问题与解法、快速开始、工作原理、架构、局限、贡献、许可证）；内容只从脚本、模板和活文档提炼，不写未实现的能力。流程和架构用 Mermaid 图，GitHub 原生渲染，不用提交图片文件。规则细节继续留在 `template/AGENTS.md`，README 只讲结构和作用，并链接过去。
- 改动文件：`README.md`、`README.en.md`；README 现在列出脚本和配置键，所以根目录 `AGENTS.md` 的同步检查规则补上脚本，`docs/architecture/modules/guidance.md` 记下 README 的写法依据。
- 影响与风险：README 不装进目标项目，已接入项目和已发布版本都不受影响。`upgrade.md` 与 `skill/SKILL.md` 不引用 README 的具体章节（已搜索确认）。风险是脚本表和代码以后不同步，用同步检查规则兜住，不加自动检查。外部徽章依赖 shields.io，加载失败只影响图标显示。

## 2. 任务
- [x] Task 1：重写 `README.md`
  - 对应验收：AC-01, AC-02, AC-03
  - 涉及文件：`README.md`
  - 验证：临时校验脚本
- [x] Task 2：`README.en.md` 按同样骨架补架构概览
  - 对应验收：AC-05
  - 涉及文件：`README.en.md`
  - 验证：临时校验脚本
- [x] Task 3：同步维护规则与活文档，提交推送后查看 GitHub 页面，正式验证
  - 对应验收：AC-04, AC-06
  - 涉及文件：`AGENTS.md`、`docs/architecture/modules/guidance.md`、`README.md`
  - 验证：浏览器查看两个 GitHub 页面的 Mermaid 图；`bash scripts/ai-verify.sh --spec feat-t-000045 README.md`

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `README.md:112`：「验收标准无空格」容易误读，脚本实际检查的是无空单元格 / 建议改为「无空单元格」 / 项目指南
- `README.en.md`：全文 101 行，正文 87 行，满足 AC-05，但接近上限 / 以后再加内容时先精简 / 项目指南
- `README.md:162-187`：目录树没列 `.gitignore`、`.gitattributes`，`docs/architecture/modules/` 是接入试点时才建 / 可在注释里说明 / 项目指南

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：无，独立审查已通过
- 已完成：Task 1~3；两个 GitHub 页面已截图查看（9fee93e），流程图三段式、架构图纵向分层，没有被 GitHub 缩放控件遮挡
- 已排除的方案：提交架构图图片（要多维护二进制文件）；英文全量翻译（维护者定的是简短英文版）；用 npx 跑 mermaid-cli 本地渲染（运行外部代码被权限策略拦下，改为在 GitHub 页面验证）
- 下一步：过 g3 并归档
