#!/usr/bin/env bash
# ==============================================================================
# harness-selftest.sh — 门禁自检：用坏样例与好样例断言脚本「该拦的拦得住、该过的过得去」。
# 用法：bash scripts/harness-selftest.sh    退出码：0 全部通过；1 有断言失败
# 改 scripts/ 或 harness/redlines.conf 后必跑；可接进 CI。
# ==============================================================================
set -u
# 沙箱里的文件都是 LF：关掉换行转换，免得 Git Bash 下每个文件报一行 CRLF 警告。
export GIT_CONFIG_COUNT=1 GIT_CONFIG_KEY_0=core.autocrlf GIT_CONFIG_VALUE_0=false

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 1
TMP=$(mktemp -d "${TMPDIR:-/tmp}/harness-selftest-XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT

SB="$TMP/scaffold"
mkdir -p "$SB/process/specs" "$SB/harness" "$SB/src/export"
cp -r "$ROOT/scripts" "$SB/scripts"
cp -r "$ROOT/process/specs/_templates" "$SB/process/specs/_templates"
cp "$ROOT/harness/redlines.conf" "$SB/harness/redlines.conf"
# 自检用固定夹具阈值；目标项目可以合法选择不同数值。
sed -i -e 's/^CR_MAX_ROUNDS=.*/CR_MAX_ROUNDS=4/' -e 's/^VERIFY_MAX_ATTEMPTS=.*/VERIFY_MAX_ATTEMPTS=3/' "$SB/harness/redlines.conf"
cp "$SB/harness/redlines.conf" "$TMP/redlines.fixture"
cd "$SB" || exit 1
printf 'export function createExport() { return true; }\n' >src/export/service.ts

TOTAL=0; FAILED=0; SECTION_NAME=""; SECTION_START=$SECONDS
section() {
  [ -z "$SECTION_NAME" ] || printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
  SECTION_NAME="$1"; SECTION_START=$SECONDS
  printf '== %s ==\n' "$SECTION_NAME"
}
ok_msg() { TOTAL=$((TOTAL + 1)); printf '  ✅ %s\n' "$1"; }
ng_msg() {
  TOTAL=$((TOTAL + 1)); FAILED=$((FAILED + 1))
  printf '  ❌ %s\n' "$1"
  [ -n "${2:-}" ] && printf '%s\n' "$2" | head -n 5 | sed 's/^/     | /'
}
expect_ok() {   # $1=描述；其余=命令
  local desc="$1" out rc; shift
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then ok_msg "$desc"; else ng_msg "$desc（期望 exit 0，实际 $rc）" "$out"; fi
}
expect_fail() { # $1=描述 $2=期望提示片段；其余=命令
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then ng_msg "$desc（本应被拒，实际 exit 0）" "$out"
  elif [ -n "$want" ] && ! printf '%s' "$out" | grep -q -- "$want"; then ng_msg "$desc（被拒了，但原因不含「$want」）" "$out"
  else ok_msg "$desc"; fi
}
expect_out() {  # $1=描述 $2=期望输出片段；其余=命令（要求成功且输出命中）
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q -- "$want"; then ok_msg "$desc"
  else ng_msg "$desc（有输出但没有「$want」）" "$out"; fi
}
file_has()   { if grep -q -- "$3" "$2" 2>/dev/null; then ok_msg "$1"; else ng_msg "$1（$2 里没有「$3」）"; fi; }
file_lacks() { if grep -q -- "$3" "$2" 2>/dev/null; then ng_msg "$1（$2 里仍有「$3」）"; else ok_msg "$1"; fi; }
same()       { if [ "$2" = "$3" ]; then ok_msg "$1"; else ng_msg "$1"; fi; }
differ()     { if [ "$2" != "$3" ]; then ok_msg "$1"; else ng_msg "$1"; fi; }
git_q()      { git -c user.name=selftest -c user.email=selftest@example.invalid "$@"; }

# ---------------------------------------------------------------- 样例生成器 --
make_summary() {  # $1=spec 目录：模拟 ai-verify.sh 的正式摘要
  cat >"$1/verification.md" <<MD
- result: PASS
- state: $(bash scripts/ai-state-id.sh)
MD
}
mk_spec() {       # $1=feat：能通过三道门的完整样例（需人决定）
  local d="process/specs/active/$1"
  mkdir -p "$d"
  cat >"$d/requirements.md" <<'MD'
# 需求：selftest

- 原始问题 / 原话：运营同学说现在只能手工导出数据
- 需人决定：是，涉及用户数据导出权限

## 1. 要做什么
- 做什么：导出用户可下载的 CSV
- 为谁做：运营同学

## 2. 验收标准
| 编号 | 通过条件 | 证据 |
| :-- | :-- | :-- |
| AC-01 | 返回任务 id 且可下载 | 建任务 < 2s |

## 3. 待确认问题
- [x] Q1：单次上限 → 结论：5 万行
MD
  cat >"$d/tasks.md" <<'MD'
# 任务与接力：selftest

## 1. 方案
- 思路：新增导出服务与上限校验

## 2. 任务
- [x] Task 1：实现导出与上限校验
  - 对应验收：AC-01
  - 涉及文件：`src/export/service.ts`
- [x] **Task 2：补测试**
  - 涉及文件：`src/export/other.ts`

## 4. WIP 接力区
- 下一步：归档
MD
  make_summary "$d"
  cat >"$d/review.md" <<MD
# 审查：selftest

- **审查者**：selftest-session-b
- **未参与实现**：是
- **CR 轮次**：1 / 4
- 审查状态：$(sed -n 's/^- state: //p' "$d/verification.md")

## 结论
- 关键问题：0
- 人工决定：通过
- 决策来源：测试用例中的模拟对话决定
MD
}
R() { printf 'process/specs/active/%s/requirements.md' "$1"; }
T() { printf 'process/specs/active/%s/tasks.md' "$1"; }
V() { printf 'process/specs/active/%s/review.md' "$1"; }
S() { printf 'process/specs/active/%s/verification.md' "$1"; }

# 状态指纹只在 Git 仓库里算：沙箱先建成仓库，下面的断言才跑在全仓指纹上。
git init -q . && git add -A && git_q commit -qm fixture || exit 1

# ==============================================================================
section "1. 新建 Spec"
expect_ok   "生成新 Spec" bash scripts/ai-new-spec.sh t-empty
expect_fail "拒绝同名重复" "已存在" bash scripts/ai-new-spec.sh t-empty
mkdir -p process/specs/archive/2026-10/t-archived
expect_fail "拒绝重用已归档 ID" "已归档" bash scripts/ai-new-spec.sh t-archived
expect_fail "拒绝路径别名" "只允许" bash scripts/ai-new-spec.sh ..
file_has "新 Spec 含 WIP 接力区" "$(T t-empty)" "WIP 接力区"

section "2. g1 计划"
expect_fail "拒绝空模板" "原始问题" bash scripts/ai-gate.sh check t-empty g1
mk_spec t-noorigin
sed -i 's/^- 原始问题 \/ 原话：.*/- 原始问题 \/ 原话：　/' "$(R t-noorigin)"
expect_fail "LC_ALL=C：原话只有全角空格被拒" "原始问题" env LC_ALL=C bash scripts/ai-gate.sh check t-noorigin g1
mk_spec t-nohuman
sed -i 's/^- 需人决定：.*/- 需人决定：看情况/' "$(R t-nohuman)"
expect_fail "拒绝未判定是否需人决定" "需人决定" bash scripts/ai-gate.sh check t-nohuman g1
mk_spec t-emptyac
sed -i 's/^| AC-01 | .*/| AC-01 | 返回任务 id | 　 |/' "$(R t-emptyac)"
expect_fail "LC_ALL=C：验收标准空单元格被拒" "空单元格" env LC_ALL=C bash scripts/ai-gate.sh check t-emptyac g1
mk_spec t-pending
printf '%s\n' '- [ ] Q2：是否需要断点续传？' >>"$(R t-pending)"
expect_fail "拒绝待确认问题未清零" "待确认" bash scripts/ai-gate.sh check t-pending g1
mk_spec t-noplan
sed -i 's/^- 思路：.*/- 思路：（怎么做）/' "$(T t-noplan)"
expect_fail "拒绝方案未写" "思路" bash scripts/ai-gate.sh check t-noplan g1
mk_spec t-noacref
sed -i '/对应验收/d' "$(T t-noacref)"
expect_fail "拒绝验收标准没有任务对应" "没有任务对应" bash scripts/ai-gate.sh check t-noacref g1
mk_spec t-badacref
sed -i 's/对应验收：AC-01/对应验收：AC-01、AC-02/' "$(T t-badacref)"
expect_fail "拒绝任务引用不存在的验收标准" "不存在的验收标准 AC-02" bash scripts/ai-gate.sh check t-badacref g1
mk_spec t-acprose
printf '%s\n' '## 3. 发现但不碰' '- 与旧需求的 AC-07 冲突，另开任务' >>"$(T t-acprose)"
expect_ok   "正文提到别的 AC 编号不误拒" bash scripts/ai-gate.sh check t-acprose g1
mk_spec t-acnoline
sed -i 's/^  - 对应验收：AC-01$/  - 说明：覆盖 AC-01/' "$(T t-acnoline)"
expect_fail "验收标准只在正文出现时拒绝" "没有任务对应" bash scripts/ai-gate.sh check t-acnoline g1

section "3. g2 验证"
mk_spec t-open
printf '%s\n' '- [ ] Task 3：未完成' >>"$(T t-open)"
expect_fail "拒绝未完成任务" "未完成" bash scripts/ai-gate.sh check t-open g2
mk_spec t-fail
sed -i 's/^- result: PASS/- result: FAIL/' "$(S t-fail)"
expect_fail "拒绝失败摘要" "未通过" bash scripts/ai-gate.sh check t-fail g2
mk_spec t-stale
printf '// changed after verify\n' >>src/export/service.ts
expect_fail "拒绝代码变化后的过期摘要" "过期" bash scripts/ai-gate.sh check t-stale g2
sed -i '$d' src/export/service.ts

section "4. g3 审查"
mk_spec t-self
sed -i '/未参与实现/d' "$(V t-self)"
expect_fail "拒绝未声明未参与实现" "未参与实现" bash scripts/ai-gate.sh check t-self g3
mk_spec t-critical
sed -i 's/^- 关键问题：.*/- 关键问题：1/' "$(V t-critical)"
expect_fail "拒绝关键问题未清零" "关键问题" bash scripts/ai-gate.sh check t-critical g3
mk_spec t-cr5
sed -i 's/^- \*\*CR 轮次\*\*：.*/- **CR 轮次**：5 \/ 4/' "$(V t-cr5)"
expect_fail "拒绝 CR 轮次超上限" "上限" bash scripts/ai-gate.sh check t-cr5 g3
mk_spec t-oldreview
sed -i 's/^- 审查状态：.*/- 审查状态：old-state/' "$(V t-oldreview)"
expect_fail "拒绝审查状态与验证摘要不符" "审查状态" bash scripts/ai-gate.sh check t-oldreview g3
mk_spec t-nodecision
sed -i 's/^- 人工决定：.*/- 人工决定：<待人决定>/' "$(V t-nodecision)"
expect_fail "需人决定时拒绝缺少人的决定" "人工决定" bash scripts/ai-gate.sh check t-nodecision g3
mk_spec t-auto
sed -i 's/^- 需人决定：.*/- 需人决定：否，单文件低风险改动/' "$(R t-auto)"
sed -i '/^- 人工决定：/d; /^- 决策来源：/d' "$(V t-auto)"
expect_ok "不需人决定时 Agent 可过 g3" bash scripts/ai-gate.sh check t-auto g3

section "5. 推进、回退与状态"
mk_spec t-good
expect_ok  "g1 通过" bash scripts/ai-gate.sh pass t-good g1
expect_ok  "g2 通过" bash scripts/ai-gate.sh pass t-good g2
expect_ok  "g3 通过" bash scripts/ai-gate.sh pass t-good g3
expect_out "status 提示可归档" "三道门已通过" bash scripts/ai-gate.sh status t-good
expect_fail "拦住未过的前置门" "前置门 g1 未通过" bash scripts/ai-gate.sh pass t-auto g2
expect_ok   "reset 使 g2 及之后失效" bash scripts/ai-gate.sh reset t-good g2 --reason "需求变更"
file_lacks  ".gates 已删除 g3" process/specs/active/t-good/.gates "^g3"
file_has    "reset 记录原因" process/specs/active/t-good/.gates "需求变更"
file_has    ".gates 保留 g1" process/specs/active/t-good/.gates "g1"
expect_fail "未知门被拒" "未知门" bash scripts/ai-gate.sh pass t-good g4
mk_spec t-arch
expect_fail "未过三道门时拒绝归档" "g1 未通过" bash scripts/ai-task-pool.sh archive t-arch
for g in g1 g2 g3; do bash scripts/ai-gate.sh pass t-arch "$g" >/dev/null; done
printf '// changed after review\n' >>src/export/service.ts
expect_fail "审查失效时拒绝归档" "已失效" bash scripts/ai-task-pool.sh archive t-arch
sed -i '$d' src/export/service.ts
bash scripts/ai-task-pool.sh add "随 Spec 归档的任务" >/dev/null
sed -i 's/^- 关联 Spec: 无$/- 关联 Spec: t-arch/' process/task-pool/T-000001.md
expect_out  "三道门通过后归档" "已归档 t-arch" bash scripts/ai-task-pool.sh archive t-arch
ls process/specs/archive/*/t-arch/T-000001.md >/dev/null 2>&1 && [ ! -e process/task-pool/T-000001.md ] \
  && ok_msg "任务文件随 Spec 归档" || ng_msg "任务文件没有随 Spec 归档"
expect_out  "归档带走的任务编号不重用" "T-000002" bash scripts/ai-task-pool.sh add "归档后的新需求"

section "6. 红线配置"
sed -i '/^CR_MAX_ROUNDS=/d' harness/redlines.conf
expect_fail "缺失配置键时拒绝" "CR_MAX_ROUNDS" bash scripts/ai-gate.sh check t-good g1
cp "$TMP/redlines.fixture" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=17/' harness/redlines.conf
printf 'line\n%.0s' {1..18} >AGENTS.md
expect_fail "体积体检按项目配置拒绝" "硬上限 17 行" bash scripts/ai-check-bloat.sh
rm AGENTS.md; cp "$TMP/redlines.fixture" harness/redlines.conf

section "7. ai-verify"
mk_spec t-verify
expect_fail "未配置检查时视为未验证" "未验证" bash scripts/ai-verify.sh --spec t-verify
expect_fail "必须指定 Spec" "用法" bash scripts/ai-verify.sh
expect_fail "拒绝旧用法多带的参数" "用法" bash scripts/ai-verify.sh --spec t-verify src/export/service.ts
printf "CUSTOM_CHECK='test -f src/export/service.ts'\n" >harness/verify.conf
expect_ok  "正式验证生成摘要" bash scripts/ai-verify.sh --spec t-verify
expect_ok  "g2 接受真实生成的摘要" bash scripts/ai-gate.sh check t-verify g2
printf "CUSTOM_CHECK='test \"\$SPEC_NAME\" = t-verify'\n" >harness/verify.conf
expect_ok  "检查命令能读到 Spec 名" bash scripts/ai-verify.sh --spec t-verify
printf "CUSTOM_CHECK='false'\n" >harness/verify.conf
for i in 1 2; do bash scripts/ai-verify.sh --spec t-verify >/dev/null 2>&1; done
expect_out "第 3 次连续失败亮黄卡" "黄卡" bash -c 'bash scripts/ai-verify.sh --spec t-verify; true'
mk_spec t-redact
# 私钥头拆开写，自检文件本身才不会被 detect-private-key 拦下
cat >harness/verify.conf <<'CONF'
CUSTOM_CHECK='echo "-----BEG""IN RSA PRIVATE"" KEY----- abc"; false'
CONF
expect_fail "失败输出脱敏私钥头" "PRIVATE KEY REDACTED" bash scripts/ai-verify.sh --spec t-redact
redacted=$(bash scripts/ai-verify.sh --spec t-redact 2>&1)
case "$redacted" in *BEGIN*) ng_msg "失败输出残留私钥头" "$redacted" ;; *) ok_msg "失败输出不残留私钥头" ;; esac
rm -f harness/verify.conf

section "8. 接手 ai-resume"
expect_out  "owner 显示验证摘要" "可交接验证摘要" bash scripts/ai-resume.sh owner t-good
expect_fail "拒绝未知角色" "未知角色" bash scripts/ai-resume.sh observer t-good

section "9. 状态指纹与审查接手（Git）"
G="$TMP/git"
mkdir -p "$G/scripts" "$G/process/specs/active/demo"
cp scripts/ai-state-id.sh scripts/ai-resume.sh scripts/ai-config.sh scripts/ai-task-pool.sh scripts/ai-check-bloat.sh "$G/scripts/"
printf 'one\n' >"$G/source.txt"; printf 'two\n' >"$G/other.txt"
(cd "$G" && git init -q && git add . && git_q commit -qm initial)
fp() { (cd "$G" && bash scripts/ai-state-id.sh); }
base=$(fp)
printf 'changed\n' >>"$G/other.txt"
differ "任一文件变化计入指纹" "$base" "$(fp)"
(cd "$G" && git add other.txt); staged=$(fp)
(cd "$G" && git_q commit -qm changed)
same "暂存到提交后指纹稳定" "$staged" "$(fp)"
base=$(fp)
printf 'note\n' >"$G/process/note.md"
(cd "$G" && bash scripts/ai-task-pool.sh add "中途收录的问题" >/dev/null)
same "process/ 下的改动不计入指纹" "$base" "$(fp)"
mkdir -p "$G/process-x"; printf 'near\n' >"$G/process-x/a.md"
differ "前缀相近的目录照常计入" "$base" "$(fp)"
rm -rf "$G/process-x" "$G/process/note.md"
nogit() { (cd "$TMP" && bash "$SB/scripts/ai-state-id.sh"); }
expect_fail "非 Git 目录拒绝计算指纹" "需要 Git 仓库" nogit
review_base=$(cd "$G" && git rev-parse HEAD)
printf 'reviewed\n' >>"$G/source.txt"
printf '原话与 AC\n' >"$G/process/specs/active/demo/requirements.md"
printf '## 2. Task 1\n' >"$G/process/specs/active/demo/tasks.md"
printf -- '- result: PASS\n- state: %s\n' "$(fp)">"$G/process/specs/active/demo/verification.md"
rv() { (cd "$G" && bash scripts/ai-resume.sh review demo "$1"); }
expect_out  "review 给出完整 diff 命令" "git diff $review_base...HEAD" rv "$review_base"
expect_fail "review 拒绝无效基准" "无法解析基准" rv missing-ref
printf 'stale\n' >>"$G/source.txt"
expect_fail "review 拒绝过期验证摘要" "过期" rv "$review_base"
printf '* text=auto eol=lf\n' >"$G/.gitattributes"
(cd "$G" && git add .gitattributes && git_q commit -qm attributes)
printf 'one\r\ncrlf\r\n' >"$G/source.txt"
warn=$(cd "$G" && bash scripts/ai-state-id.sh 2>&1 >/dev/null)
[ -z "$warn" ] && ok_msg "CRLF 文件不让指纹脚本输出警告" || ng_msg "CRLF 文件不让指纹脚本输出警告" "$warn"

section "10. 任务池"
P="$TMP/pool"
mkdir -p "$P/process/specs/archive"
cp -r scripts "$P/scripts"; cp -r process/specs/_templates "$P/process/specs/_templates"
cd "$P" || exit 1
expect_out  "空池 next 可用" "暂无待办" bash scripts/ai-task-pool.sh next
expect_fail "LC_ALL=C：拒绝只有全角空格的原话" "不能为空" env LC_ALL=C bash scripts/ai-task-pool.sh add "　　"
expect_out  "空池 intake 收录并启动" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh intake "第一条需求"
expect_out  "活跃期间新需求只入队" "续做活跃 Spec：feat-t-000001" bash scripts/ai-task-pool.sh intake "第二条需求"
expect_out  "活跃期间再收录一条" "T-000003" bash scripts/ai-task-pool.sh add "第三条需求"
file_has    "新 Spec 引用任务原件" process/specs/active/feat-t-000001/requirements.md "process/task-pool/T-000001.md"
sed -i 's/^- 创建日期: .*/&\n- 优先: 是/' process/task-pool/T-000003.md
expect_out  "有活跃 Spec 时 start-next 只提示续做" "续做活跃 Spec" bash scripts/ai-task-pool.sh start-next
mkdir process/task-pool/.lock
expect_fail "任务池锁冲突时拒绝归档" "另一进程修改" bash scripts/ai-task-pool.sh archive feat-t-000001
rmdir process/task-pool/.lock
expect_fail "任务池里未过门的 Spec 不能归档" "未通过" bash scripts/ai-task-pool.sh archive feat-t-000001
mkdir -p process/specs/archive/2026-10 && mv process/specs/active/feat-t-000001 process/specs/archive/2026-10/
expect_out  "按优先选下一项" "下一项：T-000003（维护者指定优先）" bash scripts/ai-task-pool.sh next
expect_out  "Spec 不在 active 的任务标为关联异常" "关联异常" bash scripts/ai-task-pool.sh list
mv process/specs/_templates/tasks.md "$TMP/tasks.tpl"
expect_fail "缺模板时启动失败" "模板缺失" bash scripts/ai-task-pool.sh start-next
[ ! -e process/specs/active/feat-t-000003 ] && ok_msg "失败后无孤儿 Spec" || ng_msg "失败后留下孤儿 Spec"
file_has    "失败后任务仍未关联" process/task-pool/T-000003.md "- 关联 Spec: 无"
mv "$TMP/tasks.tpl" process/specs/_templates/tasks.md
expect_out  "start-next 启动指定任务" "已关联 feat-t-000003" bash scripts/ai-task-pool.sh start-next
mkdir -p process/specs/archive/2026-01/feat-t-000009
expect_out  "编号避开已有 Spec" "T-000010" bash scripts/ai-task-pool.sh add "第四条需求"
cd "$SB" || exit 1

section "11. 多个工作区"
# 一个主工作区加几个别的工作区：任务池只有一份，Spec 归启动它的工作区，归档只在主工作区做，正式验证一次一个
W="$TMP/wt"; M="$W/main"
mkdir -p "$M/process/specs" "$M/harness" "$M/src"
cp -r "$SB/scripts" "$M/scripts"; cp -r "$SB/process/specs/_templates" "$M/process/specs/_templates"
cp "$TMP/redlines.fixture" "$M/harness/redlines.conf"
printf 'a\n' >"$M/src/a.txt"
# 检查命令占一个「端口」（公共 Git 目录下的一个目录）2 秒：两处同时跑，后跑的抢不到就失败
cat >"$M/harness/verify.conf" <<'CONF'
CUSTOM_CHECK='p="$(git rev-parse --git-common-dir)/port"; mkdir "$p" 2>/dev/null || exit 1; sleep 2; rmdir "$p"'
CONF
cd "$M" || exit 1
git init -q . && git add -A && git_q commit -qm fixture || exit 1
MB=$(git branch --show-current)
at()   { (cd "$1" && shift && "$@"); }                          # 在某个工作区里运行
save() { (cd "$1" && git add -A && git_q commit -qm "$2" >/dev/null); }
done_spec() { # $1=工作区 $2=feat $3=新文件：改一处代码并提交，再造一份能过三道门的记录
  (cd "$1" && printf 'x\n' >"src/$3" && git add -A && git_q commit -qm code >/dev/null && mk_spec "$2" \
    && for g in g1 g2 g3; do bash scripts/ai-gate.sh pass "$2" "$g" >/dev/null; done && git add -A && git_q commit -qm gates >/dev/null)
}
expect_out "主工作区收录并就地启动" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh intake "主线上的需求"
save "$M" start
git_q worktree add -q "$W/w1"; git_q worktree add -q "$W/w3"
expect_out "带着主线 Spec 副本的工作区照常收录并启动" "已关联 feat-t-000002" at "$W/w1" bash scripts/ai-task-pool.sh intake "另一个工作区里的需求"
[ -f process/task-pool/T-000002.md ] && [ ! -e "$W/w1/process/task-pool/T-000002.md" ] \
  && ok_msg "任务文件写进主工作区的任务池" || ng_msg "任务文件没有写进主工作区的任务池"
[ -d "$W/w1/process/specs/active/feat-t-000002" ] && [ ! -e process/specs/active/feat-t-000002 ] \
  && ok_msg "Spec 建在收录它的工作区里" || ng_msg "Spec 没有建在收录它的工作区里"
file_has    "别的工作区里的需求来源仍是仓库内的相对路径" "$W/w1/process/specs/active/feat-t-000002/requirements.md" '`process/task-pool/T-000002.md`'
expect_out  "别的工作区只续做自己的 Spec" "续做活跃 Spec：feat-t-000002" at "$W/w1" bash scripts/ai-task-pool.sh next
expect_out  "主工作区只续做自己的 Spec" "续做活跃 Spec：feat-t-000001" bash scripts/ai-task-pool.sh next
same        "各工作区的 list 输出相同" "$(bash scripts/ai-task-pool.sh list)" "$(at "$W/w1" bash scripts/ai-task-pool.sh list)"
case "$(bash scripts/ai-task-pool.sh list)" in *关联异常*) ng_msg "别的工作区里在做的任务被标成关联异常" ;; *) ok_msg "别的工作区里在做的任务显示进行中" ;; esac
mkdir process/task-pool/.lock
expect_fail "任务池的锁全仓库只有一把" "另一进程修改" at "$W/w1" bash scripts/ai-task-pool.sh add "锁着的时候"
rmdir process/task-pool/.lock
st=$(bash scripts/ai-gate.sh status)
[ "$(printf '%s\n' "$st" | grep -c 'feat-t-000002 ')" = 1 ] && printf '%s\n' "$st" | grep -q "别的工作区.*w1" \
  && ok_msg "status 列出别的工作区在途的 Spec" || ng_msg "status 没有列出别的工作区在途的 Spec" "$st"
[ "$(at "$W/w1" bash scripts/ai-gate.sh status | grep -c 'feat-t-000001 ')" = 1 ] \
  && ok_msg "带过来的副本不重复列出" || ng_msg "带过来的副本被重复列出"
rs=$(at "$W/w1" bash scripts/ai-resume.sh owner 2>&1)
printf '%s\n' "$rs" | grep -q '主工作区在' && [ "$(printf '%s\n' "$rs" | grep -c '^  📂')" = 1 ] \
  && ok_msg "接手快照只列自己的 Spec 并指出主工作区" || ng_msg "接手快照没有只列自己的 Spec" "$rs"
expect_fail "别的工作区里拒绝归档" "归档在主工作区做" at "$W/w1" bash scripts/ai-task-pool.sh archive feat-t-000002

# 挪出去做：已经在主工作区启动并提交的 Spec，归分支名和它相同的那个工作区
git_q worktree add -q -b feat-t-000001 "$W/w2"
expect_out  "挪到同名分支的工作区后，那里续做它" "续做活跃 Spec：feat-t-000001" at "$W/w2" bash scripts/ai-task-pool.sh next
expect_out  "挪走以后主工作区不再被它挡住" "暂无待办" bash scripts/ai-task-pool.sh next
expect_out  "分支名不同的工作区不把它当成自己的" "已关联 feat-t-000003" at "$W/w3" bash scripts/ai-task-pool.sh intake "第三个工作区里的需求"
mv "$W/w2" "$W/w2-gone"
expect_out  "同名分支的工作区目录不在了，它回到主工作区" "续做活跃 Spec：feat-t-000001" bash scripts/ai-task-pool.sh next
[ -z "$(bash scripts/ai-gate.sh status 2>&1 >/dev/null)" ] && ok_msg "目录不在了的工作区不让 status 报错" || ng_msg "目录不在了的工作区让 status 报错"
mv "$W/w2-gone" "$W/w2"; git_q worktree remove "$W/w2" && git_q branch -q -D feat-t-000001
bash scripts/ai-new-spec.sh feat-loose >/dev/null; git_q worktree add -q -b feat-loose "$W/w5"
expect_out  "还没提交就开了同名分支的工作区时，Spec 仍归主工作区" "feat-loose " bash scripts/ai-gate.sh status
git_q worktree remove "$W/w5" && git_q branch -q -D feat-loose; rm -rf process/specs/active/feat-loose

# 正式验证同一时间只跑一个
(cd "$W/w1" && bash scripts/ai-verify.sh --spec feat-t-000002 >"$TMP/v1.out" 2>&1; echo $? >"$TMP/v1.rc") &
sleep 1
(cd "$W/w3" && bash scripts/ai-verify.sh --spec feat-t-000003 >"$TMP/v3.out" 2>&1; echo $? >"$TMP/v3.rc")
wait
[ "$(cat "$TMP/v1.rc")$(cat "$TMP/v3.rc")" = 00 ] && [ ! -e "$W/w3/process/specs/active/feat-t-000003/.attempts" ] \
  && ok_msg "两个工作区同时验证：后发起的等前一个结束，都不记失败" || ng_msg "两个工作区同时验证互相撞了" "$(cat "$TMP/v3.out")"
file_has    "等待提示里有持锁的进程号和锁文件位置" "$TMP/v3.out" "进程 [0-9][0-9]*）.*ai-verify.lock"
echo 999999 >.git/ai-verify.lock
vout=$(at "$W/w1" timeout 30 bash scripts/ai-verify.sh --spec feat-t-000002 2>&1); vrc=$?
case "$vrc:$vout" in 0:*等它结束*) ng_msg "锁里记的进程不在了却还在等" "$vout" ;; 0:*) ok_msg "锁里记的进程已经不在时不等待" ;; *) ng_msg "残留的锁挡住了验证" "$vout" ;; esac
[ ! -e .git/ai-verify.lock ] && ok_msg "验证结束后不留锁" || ng_msg "验证结束后锁还在"
mkdir .git/port
expect_fail "检查失败时照常记失败" "验证失败" at "$W/w1" bash scripts/ai-verify.sh --spec feat-t-000002
rmdir .git/port; rm -f "$W/w1/process/specs/active/feat-t-000002/.attempts"
[ ! -e .git/ai-verify.lock ] && ok_msg "验证失败后也不留锁" || ng_msg "验证失败后锁还在"
vout=$(at "$SB" bash scripts/ai-verify.sh --spec t-verify 2>&1)
case "$vout" in *等它结束*) ng_msg "没有别的验证在跑时也打印了等待提示" "$vout" ;; *) ok_msg "没有别的验证在跑时不等待、不多输出" ;; esac
mkdir "$SB/.git/ai-verify.lock"   # 锁的位置上是个目录：建不出锁
vout=$(at "$SB" timeout 30 bash scripts/ai-verify.sh --spec t-verify 2>&1); vrc=$?
rmdir "$SB/.git/ai-verify.lock"
case "$vrc:$vout" in 124:*|*等它结束*) ng_msg "验证锁建不出来时卡住了" "$vout" ;; *) ok_msg "验证锁建不出来时不等待，照常验证" ;; esac
: >"$SB/.git/ai-verify.lock"      # 空的残留锁
vout=$(at "$SB" timeout 30 bash scripts/ai-verify.sh --spec t-verify 2>&1); vrc=$?
[ "$vrc" != 124 ] && [ ! -e "$SB/.git/ai-verify.lock" ] && ok_msg "空的残留锁会被清掉" || ng_msg "空的残留锁挡住了验证" "$vout"

# 合回主线：归档只在主工作区做，按主线当时的状态复核
done_spec "$W/w1" feat-t-000002 b.txt; done_spec "$W/w3" feat-t-000003 c.txt
save "$M" pool
expect_out  "三道门的记录对得上时 status 显示可归档" "三道门已通过" at "$W/w1" bash scripts/ai-gate.sh status
(cd "$W/w1" && git_q merge -q --no-edit "$MB") && git_q merge -q --ff-only w1
[ "$(bash scripts/ai-gate.sh status | grep -c 'feat-t-000002 ')" = 1 ] && at "$W/w1" bash scripts/ai-gate.sh status | grep -q "别的工作区.*main" \
  && ok_msg "分支名不同于 Spec 名的工作区合入主线后，这个 Spec 归主工作区" || ng_msg "合入主线后 Spec 的归属不对"
expect_out  "合入后在主工作区归档" "已归档 feat-t-000002" bash scripts/ai-task-pool.sh archive feat-t-000002
ls process/specs/archive/*/feat-t-000002/T-000002.md >/dev/null 2>&1 && ok_msg "别的工作区里做的任务，任务文件也随 Spec 归档" || ng_msg "任务文件没有随 Spec 归档"
expect_out  "已归档的 Spec 单独查看时显示不变" "三道门已通过" bash scripts/ai-gate.sh status feat-t-000002
save "$M" archive
(cd "$W/w3" && git_q merge -q --no-edit "$MB")
expect_out  "别的线先合入后，记录过期的 Spec 不再显示可归档" "已不对应当前状态" at "$W/w3" bash scripts/ai-gate.sh status
git_q merge -q --ff-only w3
expect_fail "后合入的线没有重新验证就归档被拒" "已失效" bash scripts/ai-task-pool.sh archive feat-t-000003
# 主线上的 Spec 归档之后，带着它旧副本、还没同步的工作区仍只认自己的
git_q worktree add -q "$W/w4"; at "$W/w4" bash scripts/ai-task-pool.sh intake "第四个工作区里的需求" >/dev/null
mkdir -p process/specs/archive/2026-01 && git mv process/specs/active/feat-t-000001 process/specs/archive/2026-01/ && save "$M" archived
expect_out  "主线的 Spec 归档后，没同步的工作区仍只认自己的" "续做活跃 Spec：feat-t-000004" at "$W/w4" bash scripts/ai-task-pool.sh next
cd "$SB" || exit 1

# ---------------------------------------------------------------- 汇总 --------
printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
echo "== 自检结果：$TOTAL 项断言，失败 $FAILED 项 =="
if [ "$FAILED" -ne 0 ]; then
  echo "❌ 门禁自检未通过：先修 scripts/，再谈业务代码。"
  exit 1
fi
echo "🟢 门禁自检通过：该拒的拒了，该过的过了。"
