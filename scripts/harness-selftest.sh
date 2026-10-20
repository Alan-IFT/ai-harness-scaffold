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
mkdir -p "$SB/docs/specs" "$SB/harness"
cp -r "$ROOT/scripts" "$SB/scripts"
cp -r "$ROOT/docs/specs/_templates" "$SB/docs/specs/_templates"
cp "$ROOT/harness/redlines.conf" "$SB/harness/redlines.conf"
# 不复制基线：让沙箱里的门禁自行记录初始基线（顺带验证 ensure_baseline 路径）
cd "$SB" || exit 1

TOTAL=0; FAILED=0
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
  mkdir -p "$1"
  cat >"$1/verify-20990101-000000.log" <<'MD'
# verify: ai-verify.sh
# target: src/export/service.ts
# result: PASS
# checks: 2  failed: 0  duration: 1s
### ESLint 单文件
### Vitest related
MD
}

good_spec() {     # $1=spec 目录：应能通过 G1~G5 的完整样例
  local d="$1"
  mkdir -p "$d/reports"
  cat >"$d/requirements.md" <<'MD'
# 需求与验收规范 (Requirements): selftest

## 0. 必须明确（四项）
- 做什么：导出用户可下载的 CSV
- 为谁做：运营同学
- 关键业务规则：单次最多 5 万行，超限拒绝并提示分批
- 验收标准：见第 3 节 AC 表

## 1. 背景与目标
导出能力缺失，运营只能手工导数据。

## 2. 结构化需求（EARS）
WHEN 用户点击导出，THE SYSTEM SHALL 生成 CSV 下载任务。

## 3. 验收标准
| 编号 | 验收点 | 通过条件 | 不通过条件 | 量化指标 / 证据 |
| :-- | :-- | :-- | :-- | :-- |
| AC-01 | 正常导出 | 返回任务 id 且可下载 | 报错或超时 | 建任务 < 2s |

## 4. 待确认问题
- 无

## 5. 非功能性约束
安全：仅本人可下载自己的导出文件。
MD
  cat >"$d/design.md" <<'MD'
# 技术架构与接口设计 (Design): selftest

## 1. 架构与数据流
Controller → ExportService → 导出任务表。

## 2. 实现顺序（依赖图 + 垂直切片）
1. 存储层：导出任务表与索引
2. 协议层：任务创建接口
3. 逻辑层：CSV 生成与下载
检查点：完成第 1、2 步后各跑一次增量验证。

## 3. 契约与 Schema
新增表 export_task（id、uid、status、created_at）。

## 4. 影响面与文件清单
- src/export/service.ts：实现导出与上限校验
- src/export/controller.ts：暴露创建与下载接口

## 5. 对抗自审
1. 假设作者过度自信：5 万行上限能否被并发绕过？
MD
  cat >"$d/tasks.md" <<'MD'
# 原子执行队列与跨工具接力棒 (Tasks): selftest

## 0. 阶段门
见 ai-gate.sh。

## 1. 上下文清单
- 必读：requirements.md、design.md、本文件

## 2. 原子任务序列
- [x] Task 1: 建导出任务表与索引
- [x] Task 2: 实现接口与上限校验
MD
  cat >"$d/review.md" <<'MD'
# 代码审查报告 (Code Review): selftest

- **审查者**：selftest-session-b
- **未参与实现**：是
- **审查时间**：2026-10-20

## 结论
- 关键问题（必须修）：0
- 改进建议（非阻塞）：1
- 判定：通过

## 关键问题（bug / 崩溃 / 安全 / 数据损坏 / 功能缺失 / 越权）
无

## 安全六项核对
| 项 | 结果 | 证据 |
| :-- | :-- | :-- |
| UID 取自登录态 | ✅ | src/export/controller.ts:12 |
MD
  make_report "$d/reports"
}

mk_spec() {       # $1=feat：在沙箱里造一个好样例 spec
  mkdir -p "docs/specs/active/$1"
  good_spec "docs/specs/active/$1"
}

# ==============================================================================
echo "== 1. 模板生成与参数校验 =="
expect_ok   "ai-new-spec 生成新 spec 三件套" bash scripts/ai-new-spec.sh t-empty
expect_fail "ai-new-spec 拒绝无参" "请提供功能名称" bash scripts/ai-new-spec.sh
expect_fail "ai-new-spec 拒绝同名重复" "已存在" bash scripts/ai-new-spec.sh t-empty

echo "== 2. 空模板必须被逐门拒绝（模板占位不能算完成） =="
expect_fail "G1 拒绝未澄清的需求" "待确认" bash scripts/ai-gate.sh check t-empty g1
expect_fail "G2 拒绝空 AC 表" "AC 表有空单元格" bash scripts/ai-gate.sh check t-empty g2
expect_fail "G3 拒绝模板占位路径 path/to/" "path/to" bash scripts/ai-gate.sh check t-empty g3
expect_fail "G4 拒绝模板占位路径 path/to/" "path/to" bash scripts/ai-gate.sh check t-empty g4
mk_spec t-open
printf '\n- [ ] Task 3: 补一个未完成任务\n' >>docs/specs/active/t-open/tasks.md
expect_fail "G4 拒绝未完成任务" "未完成" bash scripts/ai-gate.sh check t-open g4
expect_fail "G5 拒绝缺失的 review.md" "review.md" bash scripts/ai-gate.sh check t-empty g5

echo "== 3. 好样例必须通过 G1~G5 =="
mk_spec t-good
expect_ok "G1 通过" bash scripts/ai-gate.sh pass t-good g1
expect_ok "G2 通过" bash scripts/ai-gate.sh pass t-good g2
expect_ok "G3 通过" bash scripts/ai-gate.sh pass t-good g3
expect_ok "G4 通过（报告由 ai-verify 产出且 checks≥1）" bash scripts/ai-gate.sh pass t-good g4
expect_ok "G5 通过（审查者 + 未参与实现）" bash scripts/ai-gate.sh pass t-good g5
expect_out "status 能渲染下一门" "下一门" bash scripts/ai-gate.sh status t-good

echo "== 4. 防伪：报告必须来自 ai-verify.sh 且有真实检查 =="
mk_spec t-fake-hand
rm -f docs/specs/active/t-fake-hand/reports/*.log
printf '# verify: fake\n# result: PASS\n# checks: 3\n' >docs/specs/active/t-fake-hand/reports/verify-1.log
expect_fail "G4 拒绝手写报告（无 ai-verify.sh 头）" "手写" bash scripts/ai-gate.sh check t-fake-hand g4

mk_spec t-zero
rm -f docs/specs/active/t-zero/reports/*.log
printf '# verify: ai-verify.sh\n# target: src/x.ts\n# result: PASS\n# checks: 0  failed: 0\n' \
  >docs/specs/active/t-zero/reports/verify-1.log
expect_fail "G4 拒绝 0 项检查的 PASS" "0 项检查" bash scripts/ai-gate.sh check t-zero g4

mk_spec t-notarget
rm -f docs/specs/active/t-notarget/reports/*.log
printf '# verify: ai-verify.sh\n# result: PASS\n# checks: 2\n' \
  >docs/specs/active/t-notarget/reports/verify-1.log
expect_fail "G4 拒绝缺少 # target 的报告" "# target" bash scripts/ai-gate.sh check t-notarget g4

echo "== 5. 独立 CR 证据链（自己审自己不留痕 = 未审查） =="
mk_spec t-selfreview
sed -i '/未参与实现/d' docs/specs/active/t-selfreview/review.md
expect_fail "G5 拒绝未声明「未参与实现」" "未参与实现" bash scripts/ai-gate.sh check t-selfreview g5
mk_spec t-placeholder
sed -i 's/\*\*审查者\*\*：.*/**审查者**：<独立上下文标识>/' docs/specs/active/t-placeholder/review.md
expect_fail "G5 拒绝模板占位的审查者" "审查者" bash scripts/ai-gate.sh check t-placeholder g5

echo "== 6. 人工门防作弊（AI 不能自己验收） =="
call_g6_agent() { bash scripts/ai-gate.sh pass t-good g6; }
call_g6_human() { bash scripts/ai-gate.sh pass t-good g6 --by human </dev/null; }
call_baseline() { bash scripts/ai-gate.sh baseline </dev/null; }
expect_fail "G6 拒绝 Agent 推进" "人工验收门" call_g6_agent
expect_fail "G6 拒绝非 TTY 的 --by human" "TTY" call_g6_human
expect_fail "baseline 拒绝非 TTY 确认" "TTY" call_baseline
file_has "G6 拒绝事件已记入 .violations" docs/specs/active/t-good/.violations "g6-denied"

echo "== 7. 红线漂移必须阻断推进 =="
printf '\n# tampered by selftest\n' >>harness/redlines.conf
expect_fail "红线漂移时 pass 被阻断" "漂移" bash scripts/ai-gate.sh pass t-good g1
expect_out "status 报出红线漂移" "漂移" bash scripts/ai-gate.sh status t-good
cp "$ROOT/harness/redlines.conf" harness/redlines.conf
expect_out "恢复红线后基线重新一致" "一致" bash scripts/ai-gate.sh status t-good

echo "== 8. 门禁回退（reset） =="
mk_spec t-reset
bash scripts/ai-gate.sh pass t-reset g1 >/dev/null 2>&1
bash scripts/ai-gate.sh pass t-reset g2 >/dev/null 2>&1
bash scripts/ai-gate.sh pass t-reset g3 >/dev/null 2>&1
expect_ok "reset 使 g2 及之后失效" bash scripts/ai-gate.sh reset t-reset g2 --reason "需求变更"
file_lacks ".gates 里已删除 g2" docs/specs/active/t-reset/.gates "g2"
file_lacks ".gates 里已删除 g3" docs/specs/active/t-reset/.gates "g3"
file_has ".gates 里保留 g1" docs/specs/active/t-reset/.gates "g1"
expect_fail "reset 后 pass g3 被前置门拦住" "前置门 g2 未通过" bash scripts/ai-gate.sh pass t-reset g3
expect_fail "未知门被拒" "未知门" bash scripts/ai-gate.sh pass t-reset g9
expect_fail "未知 spec 被拒" "找不到 spec" bash scripts/ai-gate.sh pass no-such-feat g1

echo "== 9. 零检查 = 未验证（本地可信最低门槛） =="
mkdir -p src && : >src/x.ts
expect_fail "无项目工具链时 ai-verify 必须失败" "未执行任何真实检查" bash scripts/ai-verify.sh src/x.ts

echo "== 10. 成本包络：连续失败计数与黄卡 =="
ONLY="$TMP/only"
mkdir -p "$ONLY/scripts" "$ONLY/harness" "$ONLY/docs/specs/active/only/reports"
cp -r "$ROOT/scripts/." "$ONLY/scripts/"
cp "$ROOT/harness/redlines.conf" "$ONLY/harness/redlines.conf"
printf 'CUSTOM_CHECK="false"\n' >"$ONLY/harness/verify.conf"
: >"$ONLY/src.ts"
(
  cd "$ONLY" || exit 1
  bash scripts/ai-verify.sh src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh src.ts >/dev/null 2>&1
  bash scripts/ai-verify.sh src.ts >out3 2>&1
)
n=$(tr -dc '0-9' <"$ONLY/docs/specs/active/only/.attempts" 2>/dev/null)
if [ "${n:-}" = "3" ]; then ok_msg "连续失败计数 = 3"; else ng_msg "连续失败计数应为 3，实际 ${n:-空}"; fi
if grep -q '黄卡' "$ONLY/out3" 2>/dev/null; then ok_msg "第 3 次失败输出黄卡"; else ng_msg "第 3 次失败未输出黄卡"; fi

# ---------------------------------------------------------------- 汇总 --------
echo ""
echo "== 自检结果：$TOTAL 项断言，失败 $FAILED 项 =="
if [ "$FAILED" -ne 0 ]; then
  echo "❌ 门禁自检未通过：先修 scripts/ai-gate.sh 或 ai-verify.sh，再谈业务代码。"
  exit 1
fi
echo "🟢 门禁自检通过：该拒的拒了，该过的过了。"
