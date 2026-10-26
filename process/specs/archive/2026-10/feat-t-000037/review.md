# 审查：feat-t-000037

- 审查者：subagent/general-purpose
- 未参与实现：是
- CR 轮次：1 / 4
- 审查状态：8c66ccd78445ead87de8f57a07b2c9d263cd79962942908a9250d1aaa7306258
- 审查范围：b131fda...HEAD + 工作区（.gates 已改、verification.md 未跟踪）

## 结论
- 关键问题：0
- 改进建议：3
- 人工决定：无（requirements 标注「需人决定：否」）
- 决策来源：requirements.md，维护者对话中明确要求

## 关键问题
无

## 改进建议
1. AC-01 字面要求 `template/AGENTS.md` 的「接手步骤与经验积累」都写明读取顺序和优先级。经验积累（template/AGENTS.md:38）只写了该写哪个文件，未提顺序与优先级；优先级只在接手步骤（:6）和 template/PREFERENCES.md:4 出现。不阻塞：语义无矛盾，AC 措辞偏严，必要时放宽验收措辞即可。
2. 本仓库根 AGENTS.md:6 只写「有则读」，未写冲突时项目优先；与 template 一致性略弱，但该仓库按 template/AGENTS.md 流程，规则可继承，不阻塞。
3. 优先级链「项目约定 > 项目偏好 > 通用偏好」散落在 template/AGENTS.md:6 与 template/PREFERENCES.md:3-4，两处互不矛盾；template/AGENTS.md:6 没有明说「项目约定优先于个人偏好」。可在不加行的前提下补半句。

## 证据
- 验证：verification.md result PASS，state 8c66ccd7...，target template/AGENTS.md
- AC-01：template/AGENTS.md:6、:38 含 `~/.ai-harness/PREFERENCES.md`；AC-02：template/PREFERENCES.md、skill/SKILL.md:31、README.md:16 均已改；AC-03：AGENTS.md:6、guidance.md:10 已改；AC-04：template/AGENTS.md 共 40 行，上限 AGENTS_MAX_LINES=120，g2 已通过
- 同步性：upgrade.md:9 只提项目内 PREFERENCES.md，通用文件在仓库外，无需改；ai-resume.sh 与自检无 PREFERENCES 相关逻辑，无需同步；.gitignore 已忽略项目 PREFERENCES.md
- 少就是多：只改说明，无脚本、配置或兼容代码，无多余新增
