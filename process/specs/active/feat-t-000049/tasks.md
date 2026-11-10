# 任务与接力：feat-t-000049

> 门禁状态以 `bash scripts/ai-gate.sh status feat-t-000049` 为准；`.gates` 由脚本维护，禁止手改。

## 1. 方案
- 整体规划（三个 Spec，按编号顺序做，后一个依赖前一个）：
  1. `feat-t-000049`（本条）：状态指纹只在 Git 仓库里算，自检沙箱改成 Git 仓库。前置，行为对已接入项目不变。
  2. `T-000050`：正式验证去掉 `<file>` 参数与 `$TARGET_FILE`，连同 g2 的「目标在涉及文件里」规则一起删。改命令用法，需人决定。
  3. `T-000051`：状态指纹只按文件内容算，先验证后提交也有效。改门禁的核心信号，需人决定。规划与方案审查的结论是现在不做，已标为暂缓，规划留在任务文件里，等这个问题真的出现或维护者说要做再启用。
  - 前两个都归档、CI 通过后发 v2.2.0（公开标签由维护者自己打）。接入项目跳过 v2.1.4，直接升到这一版。
  - 不在规划里：去掉 `ai-verify.sh` 的 `redact()`。删掉只省 14 行，却要在公开的更新日志里留一句「去掉密钥脱敏」。
  - 更正此前对维护者说过的一个理由：「去掉 `<file>` 会让进行中的验证过期一次，所以指纹算法搭车一起改」不成立。`scripts/` 本身计入指纹，任何一次升级都会让进行中的验证过期，`upgrade.md` 第 1 步已经要求先归档在途 Spec。第三个 Spec 要靠自己的理由成立，见 `T-000051` 的规划。
- 思路：本条只改两个脚本、加一条活文档，Git 仓库里算出的指纹值不变。逐项如下。
  - `template/scripts/ai-state-id.sh`：把「在 Git 工作区里就算全仓、否则只输出 `no-git`」的分支，改成开头一句守卫：`git rev-parse --is-inside-work-tree` 不成功，就向错误输出写一行「状态指纹需要 Git 仓库：当前目录不在 Git 工作区，或 Git 读不了它（原因见上一行）；新项目先运行 git init」并以 1 退出。守卫里不吞掉 Git 自己的报错，这样目录归属之类的原因能直接看到。原来 Git 分支里的内容原样保留，所以 Git 仓库里的指纹值不变。
  - `template/scripts/harness-selftest.sh`：在第 1 节之前对沙箱执行 `git init -q . && git add -A && git_q commit -qm fixture`；第 9 节加一条断言，在一个非 Git 的临时目录里运行 `ai-state-id.sh`，期望失败且提示含「需要 Git 仓库」。
  - `docs/architecture/modules/template-mechanism.md`：加一条「为什么状态指纹只在 Git 仓库里算」。
- 改动文件：`template/scripts/ai-state-id.sh`、`template/scripts/harness-selftest.sh`、`docs/architecture/modules/template-mechanism.md`。
- 影响与风险：
  - 依据（2026-11-10，在仓库的临时克隆里实测，Git Bash）：只做上面两处脚本改动后，现有 76 项断言全部通过。自检总耗时一次测得 84 秒，改动前 59 秒；原因是 Git 仓库里每算一次指纹要起 3 个 git 进程，沙箱里要算约一百次。CI 的 Windows 任务会相应变慢，本仓库每次正式验证也多二十多秒。接入项目只在升级时跑自检。
  - 缺口的实测：非 Git 目录里，改动目标以外的文件，指纹不变（两次都是 `7b1e3d12fd04…`）。
  - 调用方都已处理指纹脚本失败：`ai-verify.sh` 第 62 行和 `ai-gate.sh` 第 91 行是 `|| exit 1`、`|| return 1`，`ai-resume.sh` 第 43、86 行拿空值比较，结果是报「已过期」。非 Git 目录里 `ai-resume.sh owner` 会多显示一行过期提醒，同一屏下方本来就有「尚未初始化 Git 仓库」。
  - 第 10 节任务池的沙箱仍是非 Git 目录，用到的命令都不算指纹，实验里照常通过。
  - 第 3、5、6、7 节会临时改沙箱里的文件再改回去：实验确认改回去后指纹回到原值，后面的断言不受影响。
  - 试过并放弃：把 `make_summary` 的夹具指纹缓存成变量以缩短耗时，一次测得 91 秒，没有比不缓存的 80 到 84 秒快，机器负载的波动比它的收益大。
- 方案审查（2026-11-10，独立 subagent 上下文，只读，三个 Spec 一起审）：对本条有两条「必须改」，都已采纳。
  - 「已接入项目的行为不变」说得太满：没有 `.git` 的目录原来能拿到指纹，现在会在正式验证、g2、g3、接手和归档处失败。已把「需人决定：否」的理由改成只影响没有 Git 或 Git 读不了的目录。审查认为判「否」站得住，但在边界上。
  - 报错只说「需要 Git 仓库」会误导：Git 因目录归属、仓库损坏读不了时也走这条路，而原方案把 Git 的报错吞掉了。已改成不吞报错，说明里写明两种可能。
  - AC-03 原来用 `grep -c 'git init'` 数行数，证明不了沙箱真是 Git 仓库。已换成反向检查：去掉那一行后 g2 相关断言会失败。
  - 审查建议在 `ai-verify.sh` 开头提前检查能否算指纹，免得白跑一次检查命令。没有采纳，理由写在需求的「不做」里。
  - 审查核对无误：`skill/SKILL.md` 第 18 行、现有 76 项断言（它自己跑了一遍）、`git_q` 定义在第 1 节之前所以 `git init` 的位置可行；本条单独做完，脚本、自检和文档自洽，不依赖后两个。

## 2. 任务
> 每次只做一个 `[ ]`；完成后先验证，再勾 `[x]` 并提交。
- [x] Task 1：非 Git 目录报错，自检沙箱改成 Git 仓库
  - 对应验收：AC-01、AC-02、AC-03
  - 涉及文件：`template/scripts/ai-state-id.sh`、`template/scripts/harness-selftest.sh`
  - 验证：AC-01、AC-02、AC-03 的命令
- [ ] Task 2：活文档，推送后核对 CI，正式验证
  - 对应验收：AC-04、AC-05、AC-06
  - 涉及文件：`docs/architecture/modules/template-mechanism.md`
  - 验证：AC-04 的命令；提交并推送后等 CI，跑 AC-05 的命令；再跑体积检查和正式验证

## 3. 发现但不碰
> 范围外的问题只记录：位置 / 现象 / 建议归属。
- `template/scripts/harness-selftest.sh` 的总耗时 / 沙箱改成 Git 仓库后 Git Bash 下多二十多秒 / 是否值得优化由维护者决定；缓存夹具指纹这条路试过，没有测出收益
- `template/scripts/harness-selftest.sh` 给沙箱 `git add -A` 的那一行 / Git Bash 下系统级 `core.autocrlf=true`，自检开头多 13 行「LF will be replaced by CRLF」警告，第 4、7 节各多 1 行（第 9 节原来就有 10 行同样的警告）；只是错误输出里的噪声，不影响断言 / 要不要在沙箱里关掉换行转换由维护者决定

## 4. WIP 接力区
> 换工具或换会话前更新；下一个 Agent 先读这里和 `git diff`，不要推倒重写已验证的代码。
- 当前任务：Task 2
- 已完成：三个 Spec 的整体规划；本条的需求与方案；后两条的完整规划写在各自的任务文件里（`process/task-pool/T-000050.md`、`process/task-pool/T-000051.md` 的「规划」一节）
- 已完成：Task 1（2026-11-10，Git Bash）。守卫放在取目标参数之前，所以非 Git 目录里带不带参数都报同一句。
  - AC-01：在系统临时目录的一个空目录里（只有一个 `a.txt`）运行 `bash <仓库>/template/scripts/ai-state-id.sh a.txt >out.txt 2>err.txt`，退出码 1，`out.txt` 0 字节，`err.txt` 两行：`fatal: not a git repository (or any of the parent directories): .git` 和「状态指纹需要 Git 仓库：当前目录不在 Git 工作区，或 Git 读不了它（原因见上一行）；新项目先运行 git init」。不带参数运行结果相同。自检断言「非 Git 目录拒绝计算指纹」通过；先只加这条断言、不改脚本跑过一遍，它是失败的（旧脚本以 0 退出并输出指纹 `25a8abf468e5…`），其余 76 项通过。
  - AC-02：临时 Git 仓库里提交 `tracked.txt`、`other.txt`，再给 `other.txt` 追加一行（未暂存）、新建 `untracked.txt`（未跟踪）。`git show d0149b4:template/scripts/ai-state-id.sh` 存成的旧脚本与改动后的脚本，对 `tracked.txt` 都输出 `f683ae2101b38f73ecf901015d80ecb4572803410c331325678a85cba994a7f1`。
  - AC-03：`bash scripts/harness-selftest.sh` 输出「77 项断言，失败 0 项」，总耗时 89 秒（同一会话里改动前是 60 秒）。反向检查：去掉自检里 `git init -q . && git add -A && git_q commit -qm fixture || exit 1` 这一行重跑，77 项里失败 17 项，都是算不出指纹引起的：第 3 节「拒绝代码变化后的过期摘要」，第 4 节 6 项，第 5 节「g2 通过」「g3 通过」等 8 项，第 7 节「正式验证生成摘要」「g2 接受真实生成的摘要」2 项；失败输出里就是上面那两行报错。恢复后文件的 SHA-256 与去掉前相同。
- 已排除的方案：三件事合成一个 Spec（维护者要求拆开，也便于只做前两个）；把本条并进第二个 Spec 当任务（沙箱改动会波及前 8 节，单独验证更容易看清有没有改坏）
- 下一步：做 Task 2（活文档、推送后核对 CI、正式验证）。本条归档后用 `bash scripts/ai-task-pool.sh start-next` 领 `T-000050`，把它「规划」一节的内容写进新 Spec 的 requirements.md 和 tasks.md；方案已随本次规划审过，开工时只需核对行号有没有因本条的改动而变。`T-000051` 是暂缓状态，`start-next` 不会领它。
