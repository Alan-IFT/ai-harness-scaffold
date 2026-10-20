#!/usr/bin/env bash
# ==============================================================================
# ai-gate.sh — 阶段门机械校验与推进（G1~G7）
# 原则：门禁不信任"AI 说完成了"，只认磁盘上的产物。
#
# 用法：
#   bash scripts/ai-gate.sh                                # 全局状态（含红线基线检查）
#   bash scripts/ai-gate.sh status [<feat>]                # 某个 / 全部 spec 的门禁状态
#   bash scripts/ai-gate.sh check <feat> <gate>            # 只校验，不推进
#   bash scripts/ai-gate.sh pass  <feat> <gate> [--by human]   # 校验通过后记录
#   bash scripts/ai-gate.sh baseline                       # 人类确认红线后记录基线
#   bash scripts/ai-gate.sh reset <feat> <gate> [--reason "why"]  # 回退：使该门及之后的门失效
#
# 约定：
#   - <gate> 取 g1~g7；g6 是人工验收门，必须在交互终端（TTY）由人类执行。
#   - 门禁状态写在 <spec>/.gates，由本脚本维护；手改它不会让 check 通过。
#   - 校验只是"最低机械门槛"，不能替代人工判断。
# ==============================================================================
set -u

SPEC_ROOT="docs/specs"
REDLINES="harness/redlines.conf"
BASELINE="harness/.redlines.baseline"
FEAT=""
DIR=""

say() { printf '%s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
ok()  { printf '✅ %s\n' "$*"; }

audit_ev() {   # $1=事件类型 $2=说明；写入 <spec>/.violations（随 spec 入库的审计流水）
  [ -n "${DIR:-}" ] && [ -d "$DIR" ] || return 0
  printf '%s\t%s\t%s\t%s\n' "$1" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${FEAT:-?}" "${2:-}" >>"$DIR/.violations"
}

gate_name() {
  case "$1" in
    g1) printf '需求澄清' ;; g2) printf '验收标准' ;; g3) printf '方案设计' ;;
    g4) printf '实现完成' ;; g5) printf '独立CR'   ;; g6) printf '人工验收' ;;
    g7) printf '归档'     ;; *)  printf '%s' "$1" ;;
  esac
}

feat_dir() {          # active 优先，其次 archive/YYYY-MM/<feat>
  local f="$1" d
  [ -d "$SPEC_ROOT/active/$f" ] && { printf '%s' "$SPEC_ROOT/active/$f"; return 0; }
  d=$(find "$SPEC_ROOT/archive" -mindepth 2 -maxdepth 2 -type d -name "$f" 2>/dev/null | head -n 1)
  [ -n "$d" ] && { printf '%s' "$d"; return 0; }
  return 1
}

sha() {
  [ -f "$1" ] || return 1
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else cksum "$1" | awk '{print $1"-"$2}'; fi
}

# --- 文本抽取：二级标题下、到下一个二级标题为止 ---
section_body() {
  [ -f "$1" ] || return 0
  awk -v p="$2" '
    substr($0,1,3)=="## " {
      if (index(substr($0,4), p)==1) { inb=1; next }
      else if (inb) { exit }
    }
    inb { print }
  ' "$1"
}

# stdin：筛出有实质内容的列表项 / 编号项（剔除模板占位符）
items() {
  grep -vE '^[[:space:]]*$' \
    | grep -E '^[[:space:]]*([-*]|[0-9]+[.)])[[:space:]]+' \
    | grep -vE '(path/to/|\{\{|<[^>]*>|（待填）|TODO)' || true
}

field_ok() {         # $1=section 正文 $2=标签：冒号后必须有实质内容且非占位符
  local line val
  line=$(printf '%s\n' "$1" | grep -E "^[[:space:]]*[-*][[:space:]]*$2[[:space:]]*[：:]" | head -n 1)
  [ -n "$line" ] || return 1
  val=$(printf '%s' "$line" | sed -E "s/^[^：:]*[：:]//" | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//')
  [ -n "$val" ] || return 1
  case "$val" in '<'*|'{{'*|'['*) return 1 ;; esac
  return 0
}

need_items() {       # $1=文件 $2=section 前缀 $3=最少项数 $4=说明
  local body n
  body=$(section_body "$1" "$2")
  [ -n "$body" ] || { say "缺少「## $2」章节（$4）"; return 1; }
  n=$(printf '%s\n' "$body" | items | wc -l | tr -d ' ')
  [ "$n" -ge "$3" ] || { say "「$4」内容不足：$n 项 / 至少 $3 项"; return 1; }
  return 0
}

# ---------------------------------------------------------------- G1~G7 校验 --
ck_g1() {
  local f="$DIR/requirements.md" body missing=""
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  body=$(section_body "$f" "0.")
  [ -n "$body" ] || { say "requirements.md 缺少「## 0. 必须明确（四项）」"; return 1; }
  for label in 做什么 为谁做 关键业务规则 验收标准; do
    field_ok "$body" "$label" || missing="$missing $label"
  done
  [ -z "$missing" ] || { say "四项必答未填:$missing"; return 1; }
  if section_body "$f" "4." | grep -qE '^[[:space:]]*[-*][[:space:]]*\[ \]'; then
    say "待确认问题未清零（「## 4.」仍有未勾选项）"; return 1
  fi
  return 0
}

ck_g2() {
  local f="$DIR/requirements.md" body bad
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  body=$(section_body "$f" "3.")
  [ -n "$body" ] || { say "缺少「## 3. 验收标准」"; return 1; }
  printf '%s\n' "$body" | grep -qE 'AC-[0-9]{2}' || { say "AC 表里没有 AC-xx 条目"; return 1; }
  printf '%s\n' "$body" | grep -q '不通过' || { say "AC 表缺少「不通过条件」"; return 1; }
  bad=$(printf '%s\n' "$body" | awk '/AC-[0-9][0-9]/ { n=split($0,a,"|"); for(i=2;i<n;i++) if (a[i] ~ /^[[:space:]]*$/) { print $0; break } }')
  [ -z "$bad" ] || { say "AC 表有空单元格（通过 / 不通过 / 量化证据必须填写）："; say "  $bad"; return 1; }
  return 0
}

ck_g3() {
  local f="$DIR/design.md"
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  grep -q 'path/to/' "$f" && { say "design.md 仍是模板占位路径（path/to/...），先替换成真实文件"; return 1; }
  need_items "$f" "2." 2 "实现顺序（按依赖图自底向上，至少 2 步）" || return 1
  need_items "$f" "4." 2 "影响面与文件清单" || return 1
  need_items "$f" "5." 1 "对抗自审" || return 1
  section_body "$f" "2." | grep -q '检查点' || { say "「实现顺序」里没写检查点（每 2~3 步一个）"; return 1; }
  return 0
}

ck_g4() {
  local f="$DIR/tasks.md" open done latest
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  grep -q 'path/to/' "$f" && { say "tasks.md 仍含模板占位路径（path/to/...）"; return 1; }
  open=$(grep -cE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$f" || true)
  done=$(grep -cE '^[[:space:]]*[-*][[:space:]]*\[[xX]\]' "$f" || true)
  open=$(printf '%s' "$open" | tr -d ' '); done=$(printf '%s' "$done" | tr -d ' ')
  [ "$open" -eq 0 ] || { say "还有 $open 个任务未完成"; return 1; }
  [ "$done" -ge 1 ] || { say "没有任何已完成任务"; return 1; }
  latest=$(ls -1t "$DIR"/reports/verify-*.log 2>/dev/null | head -n 1)
  [ -n "$latest" ] || { say "没有增量验证报告，先跑 bash scripts/ai-verify.sh <file>"; return 1; }
  grep -q '^# result: PASS' "$latest" || { say "最近一次验证未通过：$latest"; return 1; }
  grep -qE '^# verify:[[:space:]]*ai-verify\.sh' "$latest" || { say "最近报告不是 ai-verify.sh 产出的（手写报告不算验证）：$latest"; return 1; }
  grep -qE '^# target:[[:space:]]*[^[:space:]]' "$latest" || { say "验证报告缺少 # target 行，无法认定验证对象：$latest"; return 1; }
  local chk
  chk=$(sed -nE 's/^# checks:[[:space:]]*([0-9]+).*/\1/p' "$latest" | head -n 1)
  { [ -n "$chk" ] && [ "$chk" -ge 1 ]; } || { say "报告声称 0 项检查（未验证 ≠ 通过）：$latest"; return 1; }
  return 0
}

ck_g5() {
  local f="$DIR/review.md"
  [ -f "$f" ] || { say "缺少 review.md：用独立上下文执行 @.agents/skills/code-review.md 产出"; return 1; }
  grep -q '^## 结论' "$f" || { say "review.md 缺少「## 结论」"; return 1; }
  grep -qE '关键问题.*[：:][[:space:]]*(0|无)' "$f" || { say "关键问题未清零（结论写「关键问题（必须修）：0」）"; return 1; }
  grep -q '审查者' "$f" || { say "review.md 缺少「审查者」署名（独立上下文标识）"; return 1; }
  grep -q '审查者.*<独立上下文标识' "$f" && { say "review.md 的「审查者」仍是模板占位（去掉 <...> 填真实上下文标识）"; return 1; }
  grep -qE '未参与实现.*[：:][[:space:]]*(是|yes)' "$f" || { say "review.md 未声明「未参与实现：是」（自己审自己不留痕 = 未审查）"; return 1; }
  { grep -q '判定' "$f" && grep -q '通过' "$f"; } || { say "review.md 判定未写「通过」"; return 1; }
  grep -qE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$f" && { say "review.md 仍有未勾选项"; return 1; }
  return 0
}

ck_g6() {
  local i g
  for i in 1 2 3 4 5; do
    g="g$i"
    { [ -f "$DIR/.gates" ] && grep -qE "^$g[[:space:]]" "$DIR/.gates"; } || { say "前置门 $g 未通过"; return 1; }
  done
  [ -n "$(ls -1t "$DIR"/reports/verify-*.log 2>/dev/null | head -n 1)" ] || { say "没有验证报告"; return 1; }
  [ -f "$DIR/review.md" ] || { say "没有 review.md"; return 1; }
  return 0
}

ck_g7() {
  case "$DIR" in
    "$SPEC_ROOT"/active/*) say "spec 还在 active 目录，先按 archive-spec.md 归档"; return 1 ;;
  esac
  return 0
}

check_gate() {
  case "$1" in
    g1) ck_g1 ;; g2) ck_g2 ;; g3) ck_g3 ;; g4) ck_g4 ;;
    g5) ck_g5 ;; g6) ck_g6 ;; g7) ck_g7 ;;
    *) say "未知门 $1（可选 g1~g7）"; return 1 ;;
  esac
}

# ---------------------------------------------------------------- 红线基线 --
redline_state() {     # ok | drift | unbaselined | missing
  [ -f "$REDLINES" ] || { printf 'missing'; return 0; }
  [ -f "$BASELINE" ] || { printf 'unbaselined'; return 0; }
  if [ "$(sha "$REDLINES")" = "$(cat "$BASELINE" 2>/dev/null)" ]; then printf 'ok'; else printf 'drift'; fi
}

ensure_baseline() {
  [ -f "$REDLINES" ] || return 0
  [ -f "$BASELINE" ] && return 0
  mkdir -p "$(dirname "$BASELINE")"
  sha "$REDLINES" > "$BASELINE"
  say "ℹ️  已记录红线初始基线。若你此前手工改过红线，请人工重跑：bash scripts/ai-gate.sh baseline"
}

guard_redlines() {
  case "$(redline_state)" in
    drift)
      say "🚫 红线配置已变更（漂移）（harness/redlines.conf 与基线不符）。"
      say "   若确属人类有意修改，请在交互终端执行：bash scripts/ai-gate.sh baseline"
      return 1 ;;
    unbaselined) ensure_baseline ;;
  esac
  return 0
}

# ---------------------------------------------------------------- 子命令 -----
cmd_check() {
  FEAT="${1:-}"; local gate="${2:-}"
  [ -n "$FEAT" ] && [ -n "$gate" ] || die "用法：ai-gate.sh check <feat> <gate>"
  gate=$(printf '%s' "$gate" | tr 'A-Z' 'a-z')
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  if check_gate "$gate"; then ok "$FEAT 门 $gate（$(gate_name "$gate")）校验通过"; else die "$FEAT 门 $gate 校验未通过"; fi
}

cmd_pass() {
  [ $# -ge 2 ] || die "用法：ai-gate.sh pass <feat> <gate> [--by human]"
  FEAT="$1"; local gate; gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z')
  shift 2
  local by="agent" force=0
  while [ $# -gt 0 ]; do
    case "$1" in
      --by) by="${2:-agent}"; shift 2 ;;
      --force) force=1; shift ;;
      *) die "未知参数 $1" ;;
    esac
  done
  case " g1 g2 g3 g4 g5 g6 g7 " in *" $gate "*) ;; *) die "未知门 $gate（可选 g1~g7）" ;; esac
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  if [ "$gate" = "g6" ] && [ "$by" != "human" ]; then
    audit_ev "g6-denied" "agent 尝试推进人工验收门"
    die "G6 是人工验收门，必须由人类执行：bash scripts/ai-gate.sh pass $FEAT g6 --by human"
  fi
  if [ "$by" = "human" ] && [ ! -t 0 ]; then
    die "人工门需要在交互终端（TTY）执行，当前环境无法确认真人操作"
  fi
  guard_redlines || exit 1
  local n i
  n=${gate#g}; i=1
  while [ "$i" -lt "$n" ]; do
    if ! { [ -f "$DIR/.gates" ] && grep -qE "^g$i[[:space:]]" "$DIR/.gates"; }; then
      if [ "$force" -eq 1 ]; then
        say "⚠️  --force：跳过未通过的前置门 g$i（已记入 .violations 审计）"
        audit_ev "force-skip" "跳过未通过的前置门 g$i"
      else
        die "前置门 g$i 未通过（先 pass g$i）"
      fi
    fi
    i=$((i+1))
  done
  if ! check_gate "$gate" >/dev/null 2>&1; then check_gate "$gate"; die "门禁校验未通过，拒绝推进 $gate"; fi
  printf '%s\t%s\t%s\n' "$gate" "$by" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DIR/.gates"
  ok "$FEAT 已通过 $gate（$(gate_name "$gate")，by $by）"
  say "   下一步：bash scripts/ai-gate.sh status $FEAT"
}

cmd_reset() {   # 回退：使 <gate> 及之后的门失效（需求/设计变更、代码回滚后必须执行）
  [ $# -ge 2 ] || die "用法：ai-gate.sh reset <feat> <gate> [--reason \"why\"]"
  FEAT="$1"; local gate; gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z'); shift 2
  local reason=""
  while [ $# -gt 0 ]; do
    case "$1" in
      --reason) reason="${2:-}"; shift 2 ;;
      *) die "未知参数 $1" ;;
    esac
  done
  case " g1 g2 g3 g4 g5 g6 g7 " in *" $gate "*) ;; *) die "未知门 $gate（可选 g1~g7）" ;; esac
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT"
  [ -f "$DIR/.gates" ] || die "$FEAT 没有任何门记录，无需回退"
  local n removed
  n=${gate#g}
  removed=$(awk -F'\t' -v n="$n" '$1 ~ /^g[0-9]+$/ && substr($1,2)+0 >= n' "$DIR/.gates" | wc -l | tr -d ' ')
  [ "$removed" -gt 0 ] || die "$FEAT 的 $gate 及之后没有已通过的门记录（无需回退）"
  awk -F'\t' -v n="$n" '$1 !~ /^g[0-9]+$/ || substr($1,2)+0 < n' "$DIR/.gates" > "$DIR/.gates.tmp"
  mv "$DIR/.gates.tmp" "$DIR/.gates"
  audit_ev "reset" "回退 $gate 及之后（移除 $removed 条）：${reason:-未说明原因}"
  ok "$FEAT 已回退：$gate 及之后的 $removed 条门记录失效"
  say "   含义：需求 / 设计 / 代码已变更，必须重新逐门校验并 pass。"
  say "   下一步：bash scripts/ai-gate.sh status $FEAT"
}

render_spec() {
  local d="$1" f i g when next="" out
  f=$(basename "$d"); DIR="$d"; FEAT="$f"
  say ""
  say "📂 $f   ($d)"
  for i in 1 2 3 4 5 6 7; do
    g="g$i"
    if [ -f "$DIR/.gates" ] && grep -qE "^$g[[:space:]]" "$DIR/.gates"; then
      when=$(grep -E "^$g[[:space:]]" "$DIR/.gates" | tail -n 1 | awk '{print $3}')
      printf '   %s %-8s ✅ %s\n' "$g" "$(gate_name "$g")" "$when"
    else
      printf '   %s %-8s ⬜\n' "$g" "$(gate_name "$g")"
      [ -z "$next" ] && next="$g"
    fi
  done
  if [ -f "$DIR/.violations" ]; then
    say "   🧾 审计事件：$(wc -l <"$DIR/.violations" | tr -d ' ') 条（$DIR/.violations）"
  fi
  [ -z "$next" ] && { say "   🎉 全部门已通过，可收尾归档。"; return 0; }
  if out=$(check_gate "$next" 2>&1); then
    say "   下一门：$next（$(gate_name "$next")）"
    say "   可推进：bash scripts/ai-gate.sh pass $f $next"
  else
    say "   下一门：$next（$(gate_name "$next")）"
    say "   阻断原因：$out"
  fi
}

cmd_status() {
  local feat="${1:-}" d any=0
  say "== 阶段门状态 (ai-gate.sh) =="
  case "$(redline_state)" in
    ok)          say "🔒 红线基线：一致（$(sha "$REDLINES" | cut -c1-12)…）" ;;
    drift)       say "🚫 红线基线：漂移！harness/redlines.conf 被改动过，所有 pass 都会被阻断。"
                 say "   若属人类有意修改，请在交互终端执行：bash scripts/ai-gate.sh baseline" ;;
    unbaselined) ensure_baseline ;;
    missing)     say "ℹ️  未找到 harness/redlines.conf（可从脚手架模板补回）。" ;;
  esac
  if [ -n "$feat" ]; then
    d=$(feat_dir "$feat") || die "找不到 spec: $feat"
    render_spec "$d"; return 0
  fi
  for d in "$SPEC_ROOT"/active/*/; do
    [ -d "$d" ] || continue
    render_spec "${d%/}"; any=1
  done
  [ "$any" -eq 1 ] || { say ""; say "  当前无活跃 Spec。新建：bash scripts/ai-new-spec.sh <feat-name>"; }
}

cmd_baseline() {
  [ -f "$REDLINES" ] || die "找不到 $REDLINES"
  [ -t 0 ] || die "红线基线只能由人类在交互终端（TTY）确认；当前环境无法确认真人操作"
  sha "$REDLINES" > "$BASELINE"
  ok "已记录红线基线：$(sha "$REDLINES" | cut -c1-12)…"
  say "   含义：确认「harness/redlines.conf 的本次变更是人类有意为之」。"
}

main() {
  local cmd="${1:-status}"
  [ $# -gt 0 ] && shift
  case "$cmd" in
    status)   cmd_status "${1:-}" ;;
    check)    cmd_check "$@" ;;
    pass)     cmd_pass "$@" ;;
    reset)    cmd_reset "$@" ;;
    baseline) cmd_baseline ;;
    -h|--help|help) sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "未知命令 $cmd（可用：status / check / pass / reset / baseline）" ;;
  esac
}

main "$@"
