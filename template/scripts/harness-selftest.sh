#!/usr/bin/env bash
# ==============================================================================
# harness-selftest.sh — 门禁自检 / Dry Run（策略即代码）
#
# 为什么需要它：门禁本身也是代码。换模型、换工具、改脚本之后，如果没人验证过
# "该拦的还拦得住"，门禁随时会退化成摆设（比如报告只要存在就算通过）。
# 本脚本把脚手架复制到临时目录，用"应该被拒"的坏样例和"应该通过"的好样例，
# 逐条断言 ai-gate.sh / ai-verify.sh 的退出码与关键提示。
#
# 用法：bash scripts/harness-selftest.sh
# 退出码：0 = 全部通过；1 = 有断言失败（失败详情直接打印）
# 建议：接进 CI 的 harness job，改 scripts/ai-gate.sh 或 redlines 后必跑。
# ==============================================================================
set -u

ROOT=$(cd "$(dirname "$0")/.." && pwd) || exit 1
TMP=$(mktemp -d "${TMPDIR:-/tmp}/harness-selftest-XXXXXX") || exit 1
trap 'rm -rf "$TMP"' EXIT

SB="$TMP/scaffold"
mkdir -p "$SB/process/specs" "$SB/harness"
cp -r "$ROOT/scripts" "$SB/scripts"
cp -r "$ROOT/process/specs/_templates" "$SB/process/specs/_templates"
cp "$ROOT/harness/redlines.conf" "$SB/harness/redlines.conf"
# 自检用固定夹具阈值；目标项目可以合法选择不同数值。
sed -i -e 's/^CR_MAX_ROUNDS=.*/CR_MAX_ROUNDS=4/' \
       -e 's/^VERIFY_MAX_ATTEMPTS=.*/VERIFY_MAX_ATTEMPTS=3/' "$SB/harness/redlines.conf"
cp "$SB/harness/redlines.conf" "$TMP/redlines.fixture"
# 不复制基线：让沙箱里的门禁自行记录初始基线（顺带验证 ensure_baseline 路径）
cd "$SB" || exit 1
mkdir -p src/export
printf 'export function createExport() { return true; }\n' >src/export/service.ts

TOTAL=0; FAILED=0
SECTION_NAME=""; SECTION_START=$SECONDS
section() {
  if [ -n "$SECTION_NAME" ]; then
    printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
  fi
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

expect_fail() { # $1=描述 $2=期望提示片段（可空）；其余=命令
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ]; then
    ng_msg "$desc（本应被拒，实际 exit 0）" "$out"
  elif [ -n "$want" ] && ! printf '%s' "$out" | grep -q -- "$want"; then
    ng_msg "$desc（被拒了，但原因不含「$want」）" "$out"
  else
    ok_msg "$desc"
  fi
}

expect_out() {  # $1=描述 $2=期望输出片段；其余=命令（要求命令成功且输出命中）
  local desc="$1" want="$2" out rc; shift 2
  out=$("$@" 2>&1); rc=$?
  if [ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q -- "$want"; then
    ok_msg "$desc"
  else
    ng_msg "$desc（有输出但没有「$want」）" "$out"
  fi
}

file_has() {    # $1=描述 $2=文件 $3=片段
  if grep -q -- "$3" "$2" 2>/dev/null; then ok_msg "$1"; else ng_msg "$1（$2 里没有「$3」）"; fi
}
file_lacks() {  # $1=描述 $2=文件 $3=片段
  if grep -q -- "$3" "$2" 2>/dev/null; then ng_msg "$1（$2 里仍有「$3」）"; else ok_msg "$1"; fi
}

# ---------------------------------------------------------------- 样例生成器 --
make_report() {   # $1=reports 目录：模拟 ai-verify.sh 真实产出
  local state spec
  mkdir -p "$1"
  printf '# verify: ai-verify.sh\n# result: PASS\n' >"$1/verify-20990101-000000.log"
  spec=$(basename "$(dirname "$1")")
  state=$(bash scripts/ai-state-id.sh src/export/service.ts)
  cat >"$(dirname "$1")/verification.md" <<MD
# 增量验证摘要

- spec: $spec
- target: src/export/service.ts
- result: PASS
- checks: 2
- state: $state
- command: bash scripts/ai-verify.sh --spec $spec src/export/service.ts
MD
}

good_spec() {     # $1=spec 目录：应能通过 g1~g3 的完整样例（需人决定）
  local d="$1"
  mkdir -p "$d/reports"
  cat >"$d/requirements.md" <<'MD'
# 需求：selftest

- 原始问题 / 原话：运营同学说现在只能手工导出数据
- 需人决定：是，涉及用户数据导出权限

## 1. 要做什么
- 做什么：导出用户可下载的 CSV
- 为谁做：运营同学
- 不做：定时导出

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
- 改动文件：`src/export/service.ts`
- 影响与风险：只读导出，权限取自登录态

## 2. 任务
- [x] Task 1：实现导出与上限校验
  - 涉及文件：`src/export/service.ts`

## 4. WIP 接力区
- 下一步：归档
MD
  cat >"$d/review.md" <<'MD'
# 审查：selftest

- **审查者**：selftest-session-b
- **未参与实现**：是
- **CR 轮次**：1 / 4

## 结论
- 关键问题：0
- 改进建议：1
- 人工决定：通过
- 决策来源：测试用例中的模拟对话决定
MD
  make_report "$d/reports"
  printf '%s\n' "- 审查状态：$(sed -n 's/^- state: //p' "$d/verification.md" | head -n 1)" >>"$d/review.md"
}

mk_spec() {       # $1=feat：在沙箱里造一个好样例 spec
  mkdir -p "process/specs/active/$1"
  good_spec "process/specs/active/$1"
}
R() { printf 'process/specs/active/%s/requirements.md' "$1"; }
T() { printf 'process/specs/active/%s/tasks.md' "$1"; }
V() { printf 'process/specs/active/%s/review.md' "$1"; }

# ==============================================================================
section "1. 模板生成与参数校验"
expect_ok   "ai-new-spec 生成新 spec 文档" bash scripts/ai-new-spec.sh t-empty
expect_fail "ai-new-spec 拒绝无参" "请提供功能名称" bash scripts/ai-new-spec.sh
expect_fail "ai-new-spec 拒绝同名重复" "已存在" bash scripts/ai-new-spec.sh t-empty
mkdir -p process/specs/archive/2026-10/t-archived-id
expect_fail "ai-new-spec 拒绝重用已归档 ID" "已归档，不能重用" bash scripts/ai-new-spec.sh t-archived-id
expect_fail "ai-new-spec 拒绝路径别名" "只允许" bash scripts/ai-new-spec.sh ..
file_has "新 spec 含 WIP 接力区" "$(T t-empty)" "WIP 接力区"
file_has "新 spec 含 verification.md（跨 IDE 接力）" process/specs/active/t-empty/verification.md "UNVERIFIED"

section "2. 空模板与缺项必须被拒（模板占位不能算完成）"
expect_fail "g1 拒绝空模板" "原始问题" bash scripts/ai-gate.sh check t-empty g1
expect_fail "g2 拒绝未完成任务的空模板" "未完成" bash scripts/ai-gate.sh check t-empty g2
expect_fail "g3 拒绝验证未通过的空模板" "验证已失效" bash scripts/ai-gate.sh check t-empty g3
mk_spec t-noorigin
sed -i '/^- 原始问题 \/ 原话：/d' "$(R t-noorigin)"
expect_fail "g1 拒绝丢失提出者原意" "原始问题" bash scripts/ai-gate.sh check t-noorigin g1
printf '%s\n' '- 原始问题 / 原话：　' >>"$(R t-noorigin)"
expect_fail "LC_ALL=C：原始问题只有全角空格被拒" "原始问题" env LC_ALL=C bash scripts/ai-gate.sh check t-noorigin g1
mk_spec t-nohuman
sed -i 's/^- 需人决定：.*/- 需人决定：看情况/' "$(R t-nohuman)"
expect_fail "g1 拒绝未判定是否需人决定" "需人决定" bash scripts/ai-gate.sh check t-nohuman g1
mk_spec t-noac
sed -i '/^| AC-01 |/d' "$(R t-noac)"
expect_fail "g1 拒绝没有验收标准" "AC-xx" bash scripts/ai-gate.sh check t-noac g1
mk_spec t-emptyac
sed -i 's/^| AC-01 | .*/| AC-01 | 返回任务 id |  |/' "$(R t-emptyac)"
expect_fail "g1 拒绝验收标准空单元格" "空单元格" bash scripts/ai-gate.sh check t-emptyac g1
sed -i 's/^| AC-01 | .*/| AC-01 | 返回任务 id | 　 |/' "$(R t-emptyac)"
expect_fail "LC_ALL=C：只有全角空格的单元格被拒" "空单元格" env LC_ALL=C bash scripts/ai-gate.sh check t-emptyac g1
mk_spec t-vague
sed -i 's/^| AC-01 | .*/| AC-01 | 尽量 2s 内返回 | 计时 |/' "$(R t-vague)"
expect_ok "g1 不扫描措辞（含糊词交给独立审查）" env LC_ALL=C bash scripts/ai-gate.sh check t-vague g1
mk_spec t-pending
printf '%s\n' '- [ ] Q2：是否需要断点续传？' >>"$(R t-pending)"
expect_fail "g1 拒绝待确认问题未清零" "待确认" bash scripts/ai-gate.sh check t-pending g1
mk_spec t-noplan
sed -i 's/^- 思路：.*/- 思路：（怎么做）/' "$(T t-noplan)"
expect_fail "g1 拒绝方案未写" "思路" bash scripts/ai-gate.sh check t-noplan g1
mk_spec t-open
printf '%s\n' '- [ ] Task 2：补一个未完成任务' >>"$(T t-open)"
expect_fail "g2 拒绝未完成任务" "未完成" bash scripts/ai-gate.sh check t-open g2

section "3. 好样例必须通过三道门"
mk_spec t-good
expect_ok "g1 通过" bash scripts/ai-gate.sh pass t-good g1
expect_ok "g2 通过（摘要对应当前代码且 checks≥1）" bash scripts/ai-gate.sh pass t-good g2
expect_ok "g3 通过（独立审查 + 人的决定）" bash scripts/ai-gate.sh pass t-good g3
expect_out "status 提示可归档" "三道门已通过" bash scripts/ai-gate.sh status t-good
expect_out "metrics 从门记录派生耗时" "g1 → g2:" bash scripts/ai-gate.sh metrics t-good
mk_spec t-nodecision
sed -i '/^- 人工决定：/d' "$(V t-nodecision)"
expect_fail "需人决定时 g3 拒绝缺少人的决定" "人工决定" bash scripts/ai-gate.sh check t-nodecision g3
sed -i 's/^- 决策来源：.*/- 人工决定：通过\n- 决策来源：<待填写>/' "$(V t-nodecision)"
expect_fail "需人决定时 g3 拒绝占位决策来源" "决策来源" bash scripts/ai-gate.sh check t-nodecision g3
expect_fail "LC_ALL=C：缺少决策来源仍被拒" "决策来源" env LC_ALL=C bash scripts/ai-gate.sh check t-nodecision g3
mk_spec t-auto
sed -i 's/^- 需人决定：.*/- 需人决定：否，单文件低风险改动/' "$(R t-auto)"
sed -i '/^- 人工决定：/d; /^- 决策来源：/d' "$(V t-auto)"
expect_ok "不需人决定时 Agent 可推进 g3" bash scripts/ai-gate.sh check t-auto g3
expect_fail "pass 不接受 --by" "未知参数" bash scripts/ai-gate.sh pass t-auto g1 --by agent
expect_fail "pass 拦住未过的前置门" "前置门 g1 未通过" bash scripts/ai-gate.sh pass t-auto g2
expect_ok "--force 可越过前置门" bash scripts/ai-gate.sh pass t-auto g2 --force
file_has "--force 记入审计" process/specs/active/t-auto/.violations "force-skip"

section "4. 验证摘要必须有目标、真实检查和当前代码状态"
mk_spec t-fake-hand
sed -i 's/^- result: PASS/- result: FAIL/' process/specs/active/t-fake-hand/verification.md
expect_fail "g2 拒绝失败摘要" "未通过" bash scripts/ai-gate.sh check t-fake-hand g2

mk_spec t-zero
sed -i 's/^- checks: 2/- checks: 0/' process/specs/active/t-zero/verification.md
expect_fail "g2 拒绝 0 项检查的 PASS" "0 项检查" bash scripts/ai-gate.sh check t-zero g2

mk_spec t-notarget
sed -i '/^- target:/d' process/specs/active/t-notarget/verification.md
expect_fail "g2 拒绝缺少目标的摘要" "目标文件" bash scripts/ai-gate.sh check t-notarget g2

mk_spec t-stale
printf '// changed after verify\n' >>src/export/service.ts
expect_fail "g2 拒绝代码变化后的过期摘要" "过期" bash scripts/ai-gate.sh check t-stale g2
sed -i '$d' src/export/service.ts

expect_fail "多个活跃 Spec 必须显式选择" "显式指定" bash scripts/ai-verify.sh src/export/service.ts
expect_fail "ai-verify 拒绝路径别名 Spec" "无效 Spec" bash scripts/ai-verify.sh --spec .. src/export/service.ts
expect_fail "正式验证拒绝会移动的 Spec 文档目标" "流程文件" bash scripts/ai-verify.sh --spec t-good process/specs/active/t-good/requirements.md
mkdir -p docs
printf '# Metrics\n' >process/metrics.md
expect_fail "正式验证拒绝归档时会更新的度量目标" "流程文件" bash scripts/ai-verify.sh --spec t-good ./process/metrics.md
mkdir -p process/task-pool
printf '# T-000001\n' >process/task-pool/T-000001.md
printf 'T-000001\n' >process/task-pool/NEXT
expect_fail "正式验证拒绝任务池文件目标" "流程文件" bash scripts/ai-verify.sh --spec t-good process/task-pool/T-000001.md
expect_fail "正式验证拒绝 ./ 开头的任务池目标" "流程文件" bash scripts/ai-verify.sh --spec t-good ./process/task-pool/NEXT
rm -rf process/task-pool
expect_fail "验证拒绝重复分隔符绕过流程目标限制" "规范化项目路径" bash scripts/ai-verify.sh --spec t-good process//metrics.md
expect_fail "验证拒绝中间点目录绕过流程目标限制" "规范化项目路径" bash scripts/ai-verify.sh --spec t-good process/./specs/active/t-good/requirements.md
expect_out "owner 接手快照显示验证摘要" "可交接验证摘要" bash scripts/ai-resume.sh owner t-good
expect_out "owner 接手提示任务池下一步" "任务池下一步" bash scripts/ai-resume.sh owner t-good
expect_fail "旧式接手命令给迁移提示" "旧式" bash scripts/ai-resume.sh t-good
expect_fail "接手命令必须指定角色" "用法" bash scripts/ai-resume.sh
expect_fail "接手拒绝未知角色" "未知角色" bash scripts/ai-resume.sh observer t-good
mk_spec t-worker
cat >process/specs/active/t-worker/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] **Task 1：限定文件**
  - 涉及文件：`src/export/service.ts`
- [ ] **Task 2：另一个任务**
  - 涉及文件：`src/export/other.ts`

## 4. WIP
- 本段不属于 Task 2。
MD
expect_out "worker 只输出指定任务" "限定文件" bash scripts/ai-resume.sh worker t-worker 1
worker_out=$(bash scripts/ai-resume.sh worker t-worker 1)
if printf '%s' "$worker_out" | grep -q '另一个任务'; then ng_msg "worker 混入其他任务"; else ok_msg "worker 未混入其他任务"; fi
expect_fail "worker 拒绝缺失 Task" "找不到 Task" bash scripts/ai-resume.sh worker t-worker 9
mk_spec t-worker-no-boundary
cat >process/specs/active/t-worker-no-boundary/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] **Task 1：缺少文件边界**
MD
expect_fail "worker 拒绝缺失任务边界" "涉及文件" bash scripts/ai-resume.sh worker t-worker-no-boundary 1
cat >process/specs/active/t-worker-no-boundary/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] Task 1: 旧式普通标题
  - 涉及文件：`src/export/service.ts`
MD
expect_out "worker 接受旧 Spec 的普通 Task 标题" "旧式普通标题" bash scripts/ai-resume.sh worker t-worker-no-boundary 1
mk_spec t-worker-collision
cat >process/specs/active/t-worker-collision/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] Task 2: follow Task 1: migration
  - 涉及文件：`src/export/other.ts`
MD
expect_fail "worker 不把标题正文的 Task 1 当成任务编号" "找不到 Task 1" bash scripts/ai-resume.sh worker t-worker-collision 1
expect_out "LC_ALL=C：worker 识别全角冒号分隔" "限定文件" env LC_ALL=C bash scripts/ai-resume.sh worker t-worker 1
cat >process/specs/active/t-worker-collision/tasks.md <<'MD'
## 2. 原子任务序列
- [ ] **Task 1（括号不是分隔符）**
  - 涉及文件：`src/export/other.ts`
MD
expect_fail "LC_ALL=C：worker 不把全角括号当分隔符" "找不到 Task 1" env LC_ALL=C bash scripts/ai-resume.sh worker t-worker-collision 1
mk_spec t-real-verify
printf "CUSTOM_CHECK='test -f \"\$TARGET_FILE\"'\n" >harness/verify.conf
expect_ok "真实 ai-verify 为指定 Spec 生成摘要" bash scripts/ai-verify.sh --spec t-real-verify src/export/service.ts
file_has "真实验证摘要记入 PASS" process/specs/active/t-real-verify/verification.md "- result: PASS"
expect_ok "g2 接受真实生成的摘要" bash scripts/ai-gate.sh check t-real-verify g2
cp process/specs/active/t-real-verify/verification.md "$TMP/formal-summary"
printf "QUICK_CHECK='test -f \"\$TARGET_FILE\"'\n" >>harness/verify.conf
expect_ok "quick 执行真实检查" bash scripts/ai-verify.sh --quick --spec t-real-verify src/export/service.ts
if cmp -s "$TMP/formal-summary" process/specs/active/t-real-verify/verification.md; then ok_msg "quick 不覆盖正式摘要"; else ng_msg "quick 覆盖了正式摘要"; fi
rm -f harness/verify.conf
expect_fail "quick 无真实检查时拒绝" "未执行任何真实检查" bash scripts/ai-verify.sh --quick --spec t-real-verify src/export/service.ts

GIT_SB="$TMP/git-state"
mkdir -p "$GIT_SB/scripts" "$GIT_SB/process/specs/active/demo"
cp scripts/ai-state-id.sh "$GIT_SB/scripts/"
cp scripts/ai-config.sh "$GIT_SB/scripts/"
printf 'one\n' >"$GIT_SB/source.txt"
printf 'two\n' >"$GIT_SB/other.txt"
printf '{"name":"selftest"}\n' >"$GIT_SB/package.json"
(
  cd "$GIT_SB" || exit 1
  git init -q && git add . && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm initial
)
before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
printf 'changed\n' >>"$GIT_SB/other.txt"
after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$before" != "$after" ]; then ok_msg "Git 指纹识别非目标代码文件变化"; else ng_msg "Git 指纹漏掉非目标代码文件变化"; fi
(
  cd "$GIT_SB" || exit 1
  git add other.txt
)
staged=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
(
  cd "$GIT_SB" || exit 1
  git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm changed
)
committed=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$staged" = "$committed" ]; then ok_msg "Git 指纹在暂存到提交后稳定"; else ng_msg "Git 指纹在提交后无内容变化仍过期"; fi
printf 'new\n' >"$GIT_SB/new.txt"
(
  cd "$GIT_SB" || exit 1
  git add new.txt
)
staged_new=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
(
  cd "$GIT_SB" || exit 1
  git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm added
)
committed_new=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$staged_new" = "$committed_new" ]; then ok_msg "新文件暂存到提交后指纹稳定"; else ng_msg "新文件提交后指纹过期"; fi
mkdir -p "$GIT_SB/docs"
metrics_before=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
printf 'delivery result\n' >"$GIT_SB/process/metrics.md"
metrics_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$metrics_before" = "$metrics_after" ]; then ok_msg "交付度量不使代码指纹过期"; else ng_msg "交付度量错误地使代码指纹过期"; fi
# 任务池是流程记录：未跟踪走未跟踪 case，已跟踪的修改、暂存、提交与删除走 pathspec 排除；基线取在收录之前
cp scripts/ai-task-pool.sh "$GIT_SB/scripts/"
(cd "$GIT_SB" && git add scripts/ai-task-pool.sh 2>/dev/null && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm pool-script)
pool_base=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
pool_same() { # $1=描述
  local now
  now=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
  if [ "$now" = "$pool_base" ]; then ok_msg "$1"; else ng_msg "$1：指纹变化"; fi
}
(cd "$GIT_SB" && bash scripts/ai-task-pool.sh intake "中途收录的问题" && bash scripts/ai-task-pool.sh prefer T-000001) >/dev/null 2>&1
if [ -f "$GIT_SB/process/task-pool/T-000001.md" ] && [ -f "$GIT_SB/process/task-pool/NEXT" ]; then
  pool_same "Spec 进行中收录并指定任务不使指纹过期"
else
  ng_msg "Git 夹具中任务池收录未生成任务文件"
fi
(cd "$GIT_SB" && git add process/task-pool 2>/dev/null && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm pool)
pool_same "任务池提交后指纹不变"
(cd "$GIT_SB" && bash scripts/ai-task-pool.sh update T-000001 "补充一条") >/dev/null 2>&1
pool_same "已跟踪任务文件未暂存的补充不使指纹过期"
(cd "$GIT_SB" && git add process/task-pool 2>/dev/null)
pool_same "已跟踪任务文件暂存后不使指纹过期"
(cd "$GIT_SB" && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm pool-update)
pool_same "任务文件补充提交后不使指纹过期"
rm -f "$GIT_SB/process/task-pool/NEXT"
pool_same "删除已跟踪的 NEXT 不使指纹过期"
(cd "$GIT_SB" && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qam pool-next)
printf 'process note\n' >"$GIT_SB/process/note.md"
pool_same "process/ 下任意新文件不使指纹过期"
rm -f "$GIT_SB/process/note.md"
mkdir -p "$GIT_SB/process-x"
printf 'near\n' >"$GIT_SB/process-x/a.md"
near_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$near_after" != "$pool_base" ]; then ok_msg "前缀相近的目录照常计入指纹"; else ng_msg "process-x/ 被误排除"; fi
rm -rf "$GIT_SB/process-x"
printf 'near\n' >"$GIT_SB/processes.md"
near_file=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$near_file" != "$pool_base" ]; then ok_msg "前缀相近的文件照常计入指纹"; else ng_msg "processes.md 被误排除"; fi
rm -f "$GIT_SB/processes.md"
printf '\n# changed\n' >>"$GIT_SB/scripts/ai-task-pool.sh"
script_after=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$script_after" != "$pool_base" ]; then ok_msg "任务池脚本改动照常计入指纹"; else ng_msg "ai-task-pool.sh 被误排除"; fi
(cd "$GIT_SB" && git checkout -- scripts/ai-task-pool.sh)
# 指纹只有全仓模式：--spec 为兼容保留，不改变结果
spec_arg=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
no_arg=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh source.txt)
if [ "$spec_arg" = "$no_arg" ]; then ok_msg "--spec 与不带参数的指纹相同"; else ng_msg "--spec 改变了指纹"; fi
printf 'unclaimed\n' >"$GIT_SB/unclaimed.txt"
unclaimed=$(cd "$GIT_SB" && bash scripts/ai-state-id.sh --spec one source.txt)
if [ "$unclaimed" != "$spec_arg" ]; then ok_msg "带 --spec 时非目标改动仍计入指纹"; else ng_msg "带 --spec 时漏掉非目标改动"; fi
rm -f "$GIT_SB/unclaimed.txt"

RESUME_SB="$TMP/resume-review"
mkdir -p "$RESUME_SB/scripts" "$RESUME_SB/process/specs/active/demo"
cp "$ROOT/scripts/ai-resume.sh" "$ROOT/scripts/ai-state-id.sh" "$ROOT/scripts/ai-config.sh" "$RESUME_SB/scripts/"
printf 'initial\n' >"$RESUME_SB/source.txt"
printf '原始需求与 AC\n' >"$RESUME_SB/process/specs/active/demo/requirements.md"
printf '## 2. Task 1\n' >"$RESUME_SB/process/specs/active/demo/tasks.md"
(
  cd "$RESUME_SB" || exit 1
  git init -q && git add scripts source.txt && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm initial
)
review_base=$(cd "$RESUME_SB" && git rev-parse HEAD)
printf 'changed\n' >>"$RESUME_SB/source.txt"
review_state=$(cd "$RESUME_SB" && bash scripts/ai-state-id.sh --spec demo source.txt)
cat >"$RESUME_SB/process/specs/active/demo/verification.md" <<MD
- target: source.txt
- result: PASS
- state: $review_state
MD
expect_fail "review 拒绝无效基准" "无法解析基准" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo missing-ref' _ "$RESUME_SB"
empty_tree=$(cd "$RESUME_SB" && git hash-object -t tree /dev/null)
unrelated_base=$(cd "$RESUME_SB" && printf 'unrelated\n' | git -c user.name=selftest -c user.email=selftest@example.invalid commit-tree "$empty_tree")
expect_fail "review 拒绝无共同历史的基准" "不是当前 HEAD 的祖先" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$unrelated_base"
expect_out "review 给出原始证据与完整 diff 命令" "git diff $review_base...HEAD" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
rm "$RESUME_SB/process/specs/active/demo/requirements.md"
expect_fail "review 拒绝缺失原始需求" "缺少审查原件" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
printf '原始需求与 AC\n' >"$RESUME_SB/process/specs/active/demo/requirements.md"
printf 'stale\n' >>"$RESUME_SB/source.txt"
expect_fail "review 拒绝过期验证摘要" "过期" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo "$2"' _ "$RESUME_SB" "$review_base"
(
  cd "$RESUME_SB" || exit 1
  git checkout -- source.txt
  review_state=$(bash scripts/ai-state-id.sh --spec demo source.txt)
  sed -i "s/^- state: .*/- state: $review_state/" process/specs/active/demo/verification.md
  git add . && git -c user.name=selftest -c user.email=selftest@example.invalid commit -qm no-diff
)
expect_fail "review 拒绝空 diff" "没有可审查的变更" bash -c 'cd "$1" && bash scripts/ai-resume.sh review demo HEAD' _ "$RESUME_SB"

section "5. 独立 CR 证据链（自己审自己不留痕 = 未审查）"
mk_spec t-selfreview
sed -i '/未参与实现/d' "$(V t-selfreview)"
expect_fail "g3 拒绝未声明「未参与实现」" "未参与实现" bash scripts/ai-gate.sh check t-selfreview g3
mk_spec t-placeholder
sed -i 's/\*\*审查者\*\*：.*/**审查者**：<独立上下文标识>/' "$(V t-placeholder)"
expect_fail "g3 拒绝模板占位的审查者" "审查者" bash scripts/ai-gate.sh check t-placeholder g3
mk_spec t-critical
sed -i 's/^- 关键问题：.*/- 关键问题：1/' "$(V t-critical)"
expect_fail "g3 拒绝关键问题未清零" "关键问题" bash scripts/ai-gate.sh check t-critical g3
# CR 修复包络（超过上限必须转人工，禁止无限自我修复）
mk_spec t-cr5
sed -i 's/^- \*\*CR 轮次\*\*：.*/- **CR 轮次**：5 \/ 4/' "$(V t-cr5)"
expect_fail "g3 拒绝 CR 轮次超上限" "上限" bash scripts/ai-gate.sh check t-cr5 g3
mk_spec t-nocr
sed -i '/CR 轮次/d' "$(V t-nocr)"
expect_fail "g3 拒绝缺少 CR 轮次" "CR 轮次" bash scripts/ai-gate.sh check t-nocr g3
mk_spec t-stalereview
sed -i 's/^- 审查状态：.*/- 审查状态：old-state/' "$(V t-stalereview)"
expect_fail "g3 拒绝与验证摘要不符的旧审查" "审查状态" bash scripts/ai-gate.sh check t-stalereview g3

section "6. 红线基线须人在终端确认"
call_baseline() { bash scripts/ai-gate.sh baseline </dev/null; }
expect_fail "baseline 拒绝非 TTY 确认" "TTY" call_baseline

section "7. 红线漂移必须阻断推进"
printf '\n# tampered by selftest\n' >>harness/redlines.conf
expect_fail "红线漂移时 pass 被阻断" "漂移" bash scripts/ai-gate.sh pass t-good g1
expect_out "status 报出红线漂移" "漂移" bash scripts/ai-gate.sh status t-good
cp "$TMP/redlines.fixture" harness/redlines.conf
expect_out "恢复红线后基线重新一致" "一致" bash scripts/ai-gate.sh status t-good

section "8. 门禁回退（reset）"
mk_spec t-reset
bash scripts/ai-gate.sh pass t-reset g1 >/dev/null 2>&1
bash scripts/ai-gate.sh pass t-reset g2 >/dev/null 2>&1
expect_ok "reset 使 g2 及之后失效" bash scripts/ai-gate.sh reset t-reset g2 --reason "需求变更"
file_lacks ".gates 里已删除 g2" process/specs/active/t-reset/.gates "g2"
file_has ".gates 里保留 g1" process/specs/active/t-reset/.gates "g1"
expect_fail "reset 后 pass g3 被前置门拦住" "前置门 g2 未通过" bash scripts/ai-gate.sh pass t-reset g3
expect_fail "未知门被拒" "未知门" bash scripts/ai-gate.sh pass t-reset g4
expect_fail "未知 spec 被拒" "找不到 spec" bash scripts/ai-gate.sh pass no-such-feat g1

section "9. 零检查 = 未验证（本地可信最低门槛）"
mkdir -p src && : >src/x.ts
expect_fail "无项目工具链时 ai-verify 必须失败" "未执行任何真实检查" bash scripts/ai-verify.sh --spec t-good src/x.ts

section "10. 成本包络：连续失败计数与黄卡"
ONLY="$TMP/only"
mkdir -p "$ONLY/scripts" "$ONLY/harness" "$ONLY/process/specs/active/only/reports"
cp -r "$ROOT/scripts/." "$ONLY/scripts/"
cp "$TMP/redlines.fixture" "$ONLY/harness/redlines.conf"
printf 'CUSTOM_CHECK="false"\n' >"$ONLY/harness/verify.conf"
: >"$ONLY/src.ts"
(
  cd "$ONLY" || exit 1
  bash scripts/ai-verify.sh --spec only src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh --spec only src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh --spec only src.ts >out3 2>&1
)
n=$(tr -dc '0-9' <"$ONLY/process/specs/active/only/.attempts" 2>/dev/null)
if [ "${n:-}" = "3" ]; then ok_msg "连续失败计数 = 3"; else ng_msg "连续失败计数应为 3，实际 ${n:-空}"; fi
if grep -q '黄卡' "$ONLY/out3" 2>/dev/null; then ok_msg "第 3 次失败输出黄卡"; else ng_msg "第 3 次失败未输出黄卡"; fi

# ---------------------------------------------------------- 单一配置来源 ----
section "12. 阈值只从项目配置读取"
cp harness/redlines.conf "$TMP/redlines.original"
sed -i 's/^CR_MAX_ROUNDS=.*/CR_MAX_ROUNDS=1/' harness/redlines.conf
mk_spec t-config-threshold
sed -i 's/^- \*\*CR 轮次\*\*：.*/- **CR 轮次**：2 \/ 4/' process/specs/active/t-config-threshold/review.md
expect_fail "修改 CR 轮次上限后 g3 使用新值" "上限 1" bash scripts/ai-gate.sh check t-config-threshold g3
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=17/' harness/redlines.conf
printf 'line\n%.0s' {1..18} >AGENTS.md
expect_fail "体积体检按项目配置的新上限拒绝" "硬上限 17 行" bash scripts/ai-check-bloat.sh
rm AGENTS.md
cp "$TMP/redlines.original" harness/redlines.conf
sed -i '/^CR_MAX_ROUNDS=/d' harness/redlines.conf
expect_fail "缺失必要配置键时 gate 拒绝" "CR_MAX_ROUNDS" bash scripts/ai-gate.sh check t-config-threshold g1
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^VERIFY_MAX_SECONDS=.*/VERIFY_MAX_SECONDS=invalid/' harness/redlines.conf
expect_fail "非法验证预算时 verify 拒绝" "VERIFY_MAX_SECONDS" bash scripts/ai-verify.sh --spec t-config-threshold src/export/service.ts
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=invalid/' harness/redlines.conf
expect_fail "非法体积预算时 bloat 拒绝" "AGENTS_MAX_LINES" bash scripts/ai-check-bloat.sh
cp "$TMP/redlines.original" harness/redlines.conf
sed -i 's/^AGENTS_MAX_LINES=.*/AGENTS_MAX_LINES=999999999999999999999999999/' harness/redlines.conf
expect_fail "超大整数预算时 bloat 拒绝" "整数范围" bash scripts/ai-check-bloat.sh
rm harness/redlines.conf
expect_fail "缺失项目配置时拒绝" "缺少配置" bash scripts/ai-gate.sh check t-config-threshold g1
cp "$TMP/redlines.original" harness/redlines.conf

# ---------------------------------------------------------------- 汇总 --------
section "13. 跨会话任务池"
POOL_SB="$TMP/task-pool"
mkdir -p "$POOL_SB/scripts" "$POOL_SB/process/specs/archive"
cp "$ROOT/scripts/ai-task-pool.sh" "$ROOT/scripts/ai-new-spec.sh" "$ROOT/scripts/ai-config.sh" "$POOL_SB/scripts/"
cp -r "$ROOT/process/specs/_templates" "$POOL_SB/process/specs/_templates"
cd "$POOL_SB" || exit 1
expect_out "空池 next 可用" "暂无待办" bash scripts/ai-task-pool.sh next
expect_fail "拒绝无效优先级" "优先级" bash scripts/ai-task-pool.sh add --priority P3 bad
expect_fail "拒绝空白原话" "不能为空" bash scripts/ai-task-pool.sh add "   "
expect_fail "LC_ALL=C：拒绝只有全角空格的原话" "不能为空" env LC_ALL=C bash scripts/ai-task-pool.sh add "　　"
expect_out "收集第一条需求" "T-000001" bash scripts/ai-task-pool.sh add "较晚处理"
expect_out "收集高优先级需求" "T-000002" bash scripts/ai-task-pool.sh add --priority P0 "先处理"
expect_out "默认按收录顺序选下一项" "下一项：T-000001" bash scripts/ai-task-pool.sh next
expect_out "下一项显示原始需求" "原始需求：较晚处理" bash scripts/ai-task-pool.sh next
expect_fail "拒绝指定不存在任务" "任务不存在" bash scripts/ai-task-pool.sh prefer T-000003
expect_out "人工指定下一项" "已指定 T-000002" bash scripts/ai-task-pool.sh prefer T-000002
expect_out "跨会话保留指定" "下一项：T-000002" bash scripts/ai-task-pool.sh next
file_has "指定选择已落盘" process/task-pool/NEXT "T-000002"
expect_out "追加需求变更" "已追加" bash scripts/ai-task-pool.sh update T-000002 "加入边界"
expect_out "再次追加需求变更" "已追加" bash scripts/ai-task-pool.sh update T-000002 "再补一条"
expect_fail "拒绝空白补充" "不能为空" bash scripts/ai-task-pool.sh update T-000002 "   "
expect_fail "LC_ALL=C：拒绝只有全角空格的补充" "不能为空" env LC_ALL=C bash scripts/ai-task-pool.sh update T-000002 "　 　"
file_has "原话未被更新覆盖" process/task-pool/T-000002.md "先处理"
file_has "补充已落盘" process/task-pool/T-000002.md "加入边界"
file_has "第二次补充已落盘" process/task-pool/T-000002.md "再补一条"
expect_fail "拒绝非法任务 ID" "ID 无效" bash scripts/ai-task-pool.sh update T-2 bad
sed -i 's/^- 优先级: P0$/- 优先级: P3/' process/task-pool/T-000002.md
expect_fail "next 拒绝手工改坏的优先级" "优先级无效" bash scripts/ai-task-pool.sh next
expect_fail "start 拒绝手工改坏的优先级" "优先级无效" bash scripts/ai-task-pool.sh start T-000002 feat-invalid
sed -i 's/^- 优先级: P3$/- 优先级: P0/' process/task-pool/T-000002.md
rm process/specs/_templates/tasks.md
expect_fail "建 Spec 缺模板时失败" "模板缺失" bash scripts/ai-task-pool.sh start T-000002 feat-broken
[ ! -e process/specs/active/feat-broken ] && ok_msg "失败后无孤儿 Spec" || ng_msg "失败后留下孤儿 Spec"
file_has "失败后任务仍未关联" process/task-pool/T-000002.md "- 关联 Spec: 无"
cp "$ROOT/process/specs/_templates/tasks.md" process/specs/_templates/tasks.md
cp process/specs/_templates/requirements.md "$TMP/pool-requirements.original"
sed -i '/^- \*\*需求来源\*\*:/d' process/specs/_templates/requirements.md
expect_fail "建 Spec 来源占位缺失时失败" "创建 Spec 失败" bash scripts/ai-task-pool.sh start T-000002 feat-broken-source
[ ! -e process/specs/active/feat-broken-source ] && ok_msg "来源处理失败后无孤儿 Spec" || ng_msg "来源处理失败后留下孤儿 Spec"
cp "$TMP/pool-requirements.original" process/specs/_templates/requirements.md
expect_out "从待办建 Spec" "已关联 feat-first" bash scripts/ai-task-pool.sh start T-000002 feat-first
[ ! -e process/task-pool/NEXT ] && ok_msg "成功启动后清除一次性指定" || ng_msg "成功启动后仍有指定"
file_has "新 Spec 引用任务原件" process/specs/active/feat-first/requirements.md "process/task-pool/T-000002.md"
expect_out "活跃 Spec 优先续做" "续做活跃 Spec：feat-first" bash scripts/ai-task-pool.sh next
expect_fail "拒绝指定已开始任务" "不是未关联" bash scripts/ai-task-pool.sh prefer T-000002
expect_out "活跃期间可指定下项" "已指定 T-000001" bash scripts/ai-task-pool.sh prefer T-000001
expect_fail "拒绝重复领取" "不是未关联" bash scripts/ai-task-pool.sh start T-000002 feat-second
expect_fail "已有活跃 Spec 时拒绝启动下一项" "已有活跃 Spec" bash scripts/ai-task-pool.sh start T-000001 feat-second
mkdir -p process/specs/archive/2026-10
mkdir process/task-pool/.lock
expect_fail "归档遇任务池锁明确拒绝" "另一进程修改" bash scripts/ai-task-pool.sh archive feat-first
[ -d process/specs/active/feat-first ] && ok_msg "锁冲突时活跃 Spec 未移动" || ng_msg "锁冲突误移动活跃 Spec"
rmdir process/task-pool/.lock
expect_out "同锁归档活跃 Spec" "已归档 feat-first" bash scripts/ai-task-pool.sh archive feat-first
expect_out "归档后选下一项" "下一项：T-000001" bash scripts/ai-task-pool.sh next
expect_out "归档状态由 Spec 派生" "已归档" bash scripts/ai-task-pool.sh list
expect_out "补充另一个待办" "T-000003" bash scripts/ai-task-pool.sh add "临时插队"
expect_out "手动启动其他任务" "已关联 feat-other" bash scripts/ai-task-pool.sh start T-000003 feat-other
file_has "手动启动其他任务不清除指定" process/task-pool/NEXT "T-000001"
expect_out "归档插队任务" "已归档 feat-other" bash scripts/ai-task-pool.sh archive feat-other
expect_out "同锁选择并启动指定任务" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh start-next
[ ! -e process/task-pool/NEXT ] && ok_msg "指定任务启动后清除指定" || ng_msg "指定任务启动后仍有指定"
mkdir process/task-pool/.lock
expect_fail "并发写锁拒绝收集" "另一进程修改" bash scripts/ai-task-pool.sh add "冲突任务"
rmdir process/task-pool/.lock

AUTO_SB="$TMP/task-pool-auto"
mkdir -p "$AUTO_SB/scripts" "$AUTO_SB/process/specs/archive"
cp "$ROOT/scripts/ai-task-pool.sh" "$ROOT/scripts/ai-new-spec.sh" "$ROOT/scripts/ai-config.sh" "$AUTO_SB/scripts/"
cp -r "$ROOT/process/specs/_templates" "$AUTO_SB/process/specs/_templates"
cd "$AUTO_SB" || exit 1
expect_out "空池自然语言收录并启动" "已关联 feat-t-000001" bash scripts/ai-task-pool.sh intake "第一条需求"
expect_out "活跃期间新需求只入队" "续做活跃 Spec：feat-t-000001" bash scripts/ai-task-pool.sh intake "第二条需求"
file_has "活跃期间新需求保留原话" process/task-pool/T-000002.md "第二条需求"
mkdir -p process/specs/archive/2026-10
expect_out "自动路由样本归档" "已归档 feat-t-000001" bash scripts/ai-task-pool.sh archive feat-t-000001
expect_out "已有待办时先启动旧任务" "已关联 feat-t-000002" bash scripts/ai-task-pool.sh intake "第三条需求"
file_has "较新需求仍待办" process/task-pool/T-000003.md "- 关联 Spec: 无"
expect_out "旧待办完成后归档" "已归档 feat-t-000002" bash scripts/ai-task-pool.sh archive feat-t-000002
rm process/specs/_templates/tasks.md
expect_fail "自动启动失败仍提示已收录" "已收录" bash scripts/ai-task-pool.sh intake "第四条需求"
file_has "自动启动失败仍保留任务" process/task-pool/T-000004.md "第四条需求"
file_has "自动启动失败不关联旧待办" process/task-pool/T-000003.md "- 关联 Spec: 无"
cd "$SB" || exit 1

# ---------------------------------------------------------------- 汇总 --------
echo ""
printf '== %s: %ss ==\n' "$SECTION_NAME" "$((SECONDS - SECTION_START))"
echo "== 自检结果：$TOTAL 项断言，失败 $FAILED 项 =="
if [ "$FAILED" -ne 0 ]; then
  echo "❌ 门禁自检未通过：先修 scripts/ai-gate.sh 或 ai-verify.sh，再谈业务代码。"
  exit 1
fi
echo "🟢 门禁自检通过：该拒的拒了，该过的过了。"
