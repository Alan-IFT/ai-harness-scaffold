# 需求：feat-t-000040

- 创建时间：2026-11-05
- **需求来源**: `process/task-pool/T-000040.md`（原始需求与更新）
- 原始问题 / 原话：那就都按推荐处理（维护者 2026-10-31）；2026-11-05 维护者答复公开化清单「那就都按推荐来做」，清单建议先做本任务。
- 需人决定：否。只改模板的两处写法和升级说明的一句话，不涉及数据、权限、发布或不可逆操作。

## 1. 要做什么
- 做什么：去掉模板里两处会被常见 pre-commit 钩子拦截或改写的写法；升级说明加一句，要求列出项目里残留的已退役文件交人决定。
- 为谁做：装了 detect-private-key、trailing-whitespace 这类钩子的接入项目，免得每次升级都要重新定制。
- 不做：T-000040 列的三个未决候选（1.x→2.0 删除清单、「验证要能证明行为」的复议提示、旧用户目录技能入口的升级说明），维护者未表态，留待决定；不改脱敏规则的匹配范围。

## 2. 验收标准
> 每条写清通过条件与证据（命令或可观察输出）；不写「适当」「尽量」这类无法判定的词。

| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | `template/` 下没有 detect-private-key 识别的 PEM 头字面量，含私钥头的输出仍被脱敏且不残留 `BEGIN` 原文 | `grep -rnE 'BEGIN (RSA |DSA |EC |OPENSSH |ENCRYPTED |SSH2 ENCRYPTED |PGP )?PRIVATE KEY' template` 无输出；用 `ai-verify.sh` 第 25~33 行的 `sed` 处理一行私钥头，输出为 `[PRIVATE KEY REDACTED]` |
| AC-02 | `template/` 下没有行尾空白，新 Spec 的 `tasks.md` 也没有 | `grep -rnE '[[:blank:]]+$' template` 无输出；`ai-new-spec.sh` 生成的 `tasks.md` 同样无匹配 |
| AC-03 | `upgrade.md` 要求对照模板全部历史列出残留的已退役文件并交人决定 | `grep -n 'log --name-only' template/.agents/skills/upgrade.md` 命中一行，同行含「交人决定」 |
| AC-04 | 自检全部通过 | `bash scripts/ai-verify.sh --spec feat-t-000040 template/scripts/ai-verify.sh` 为 PASS |
