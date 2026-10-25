#!/usr/bin/env bash
# ==============================================================================
# ai-gate.sh — 三道门的机械校验与推进：g1 计划 → g2 验证 → g3 审查
# 原则：只认磁盘上骗不过的信号（字段已填、命令跑过、状态一致），不判断文字质量。
#
# 用法：
#   bash scripts/ai-gate.sh                                # 全部活跃 Spec 的门禁状态
#   bash scripts/ai-gate.sh status [<feat>]                # 某个 / 全部 spec 的门禁状态
#   bash scripts/ai-gate.sh check <feat> <gate>            # 只校验，不推进
#   bash scripts/ai-gate.sh pass  <feat> <gate>            # 前置门已过且校验通过后记录
#   bash scripts/ai-gate.sh reset <feat> <gate> [--reason "why"]  # 回退：使该门及之后的门失效
#
# 约定：门禁状态写在 <spec>/.gates，由本脚本维护；手改它不会让 check 通过。
# ==============================================================================
set -u

SPEC_ROOT="process/specs"
GATES="g1 g2 g3"
FEAT=""
DIR=""

# 阈值只从当前项目配置读取；缺失或无效时明确拒绝。
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
ai_config_load harness/redlines.conf CR_MAX_ROUNDS || exit 1

say() { printf '%s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
ok()  { printf '✅ %s\n' "$*"; }

gate_name() {
  case "$1" in g1) printf '计划' ;; g2) printf '验证' ;; g3) printf '审查' ;; *) printf '%s' "$1" ;; esac
}

feat_dir() {          # active 优先，其次 archive/YYYY-MM/<feat>
  local f="$1" d
  case "$f" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ -d "$SPEC_ROOT/active/$f" ] && { printf '%s' "$SPEC_ROOT/active/$f"; return 0; }
  d=$(find "$SPEC_ROOT/archive" -mindepth 2 -maxdepth 2 -type d -name "$f" 2>/dev/null | head -n 1)
  [ -n "$d" ] && { printf '%s' "$d"; return 0; }
  return 1
}

# 字段行「- 标签：值」的值；全角冒号与全角空格先归一（字节 locale 下它们不属于 [[:space:]]）。
field_value() { # $1=文件 $2=标签
  sed 's/：/:/g; s/　/ /g; s/\*\*//g' "$1" 2>/dev/null \
    | sed -nE "s#^[[:space:]]*[-*][[:space:]]*$2[[:space:]]*:[[:space:]]*(.*)\$#\1#p" \
    | head -n 1 | sed -E 's/[[:space:]]+$//'
}
filled() { # $1=值：非空且不是模板占位
  case "$1" in ''|'<'*|'{{'*|'（'*|'('*|'__'*) return 1 ;; esac
}
needs_human() { case "$(field_value "$DIR/requirements.md" '需人决定')" in 是*) return 0 ;; esac; return 1; }

# ------------------------------------------------------------------- 三道门 --
ck_g1() { # 计划：原话、是否需人决定、验收标准、待确认清零、至少一个任务与方案
  local r="$DIR/requirements.md" t="$DIR/tasks.md" bad
  [ -f "$r" ] || { say "缺少 $r"; return 1; }
  [ -f "$t" ] || { say "缺少 $t"; return 1; }
  filled "$(field_value "$r" '原始问题 / 原话')" || { say "原始问题 / 原话未填：保留提出者的表达或链接任务文件"; return 1; }
  case "$(field_value "$r" '需人决定')" in 是*|否*) ;; *) say "「需人决定」须以「是」或「否」开头"; return 1 ;; esac
  filled "$(field_value "$r" '做什么')" || { say "「做什么」未填"; return 1; }
  grep -qE '^\|[[:space:]]*AC-[0-9]+' "$r" || { say "验收标准表里没有 AC-xx 条目"; return 1; }
  bad=$(awk -F'|' '/^\|[[:space:]]*AC-[0-9]+/ { for (i=2;i<NF;i++) { c=$i; gsub(/[[:space:]]|　/, "", c); if (c=="") { print; break } } }' "$r")
  [ -z "$bad" ] || { say "验收标准有空单元格：$bad"; return 1; }
  grep -qE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$r" && { say "待确认问题未清零（requirements.md 仍有未勾选项）"; return 1; }
  filled "$(field_value "$t" '思路')" || { say "tasks.md 的方案「思路」未填"; return 1; }
  grep -qE '^[[:space:]]*-[[:space:]]*\[[ xX]\].*Task' "$t" || { say "tasks.md 没有任何 Task"; return 1; }
  return 0
}

ck_g2() { # 验证：任务全部完成，验证摘要通过、有真实检查且对应当前代码
  local f="$DIR/tasks.md" s="$DIR/verification.md" open spec target result chk saved current
  [ -f "$f" ] || { say "缺少 $f"; return 1; }
  open=$(grep -cE '^[[:space:]]*[-*][[:space:]]*\[ \]' "$f" | tr -d ' ')
  [ "$open" -eq 0 ] || { say "还有 $open 个任务未完成"; return 1; }
  [ -f "$s" ] || { say "没有验证摘要：先跑 bash scripts/ai-verify.sh --spec $FEAT <file>"; return 1; }
  spec=$(sed -n 's/^- spec: //p' "$s" | head -n 1)
  target=$(sed -n 's/^- target: //p' "$s" | head -n 1)
  result=$(sed -n 's/^- result: //p' "$s" | head -n 1)
  chk=$(sed -n 's/^- checks: //p' "$s" | head -n 1)
  saved=$(sed -n 's/^- state: //p' "$s" | head -n 1)
  [ "$spec" = "$FEAT" ] || { say "验证摘要的 Spec 不匹配：$spec"; return 1; }
  [ "$result" = PASS ] || { say "最近一次验证未通过：$s"; return 1; }
  case "$chk" in ''|*[!0-9]*) say "验证摘要的 checks 无效"; return 1 ;; esac
  [ "$chk" -ge 1 ] || { say "验证摘要声称 0 项检查（未验证 ≠ 通过）"; return 1; }
  [ -n "$target" ] && [ -f "$target" ] || { say "验证摘要缺少有效目标文件：$target"; return 1; }
  [ -n "$saved" ] || { say "验证摘要缺少代码状态指纹"; return 1; }
  current=$(bash scripts/ai-state-id.sh "$target") || return 1
  [ "$saved" = "$current" ] || { say "验证摘要已过期：代码在验证后变化，请重新运行 ai-verify.sh"; return 1; }
  return 0
}

ck_g3() { # 审查：独立上下文、关键问题 0、轮次不超限、审的是当前验证状态；需人决定时有人的通过决定
  local f="$DIR/review.md" rounds reviewed verified
  ck_g2 >/dev/null || { say "验证已失效，先重新验证（g2）"; return 1; }
  [ -f "$f" ] || { say "缺少 review.md：用独立上下文按 .agents/skills/code-review.md 产出"; return 1; }
  filled "$(field_value "$f" '审查者')" || { say "review.md 缺少「审查者」（独立上下文标识）"; return 1; }
  case "$(field_value "$f" '未参与实现')" in 是*|yes*) ;; *) say "review.md 未声明「未参与实现：是」（自己审自己 = 未审查）"; return 1 ;; esac
  case "$(field_value "$f" '关键问题')" in 0*|无*) ;; *) say "关键问题未清零（写「- 关键问题：0」）"; return 1 ;; esac
  rounds=$(field_value "$f" 'CR 轮次' | grep -oE '^[0-9]+')
  [ -n "$rounds" ] && [ "$rounds" -ge 1 ] || { say "review.md 缺少「CR 轮次」（格式：- CR 轮次：N / $CR_MAX_ROUNDS）"; return 1; }
  [ "$rounds" -le "$CR_MAX_ROUNDS" ] || { say "CR 已达 $rounds 轮 > 上限 $CR_MAX_ROUNDS：停下转人工，禁止继续自我修复"; return 1; }
  reviewed=$(field_value "$f" '审查状态')
  verified=$(sed -n 's/^- state: //p' "$DIR/verification.md" | head -n 1)
  [ "$reviewed" = "$verified" ] || { say "review.md 的审查状态与当前 verification.md 不符，须重做独立审查"; return 1; }
  if needs_human; then
    case "$(field_value "$f" '人工决定')" in 通过*) ;; *) say "需人决定：review.md 须记录人的「人工决定：通过」，Agent 不能代作决定"; return 1 ;; esac
    filled "$(field_value "$f" '决策来源')" || { say "需人决定：review.md 缺少「决策来源」（对话或工单 + 原话摘要）"; return 1; }
  fi
  return 0
}

check_gate() {
  case "$1" in
    g1) ck_g1 ;; g2) ck_g2 ;; g3) ck_g3 ;;
    *) say "未知门 $1（可选 g1~g3）"; return 1 ;;
  esac
}

# ---------------------------------------------------------------- 子命令 -----
valid_gate() { case " $GATES " in *" $1 "*) return 0 ;; esac; die "未知门 $1（可选 g1~g3）"; }

cmd_check() {
  FEAT="${1:-}"; local gate="${2:-}"
  [ -n "$FEAT" ] && [ -n "$gate" ] || die "用法：ai-gate.sh check <feat> <gate>"
  gate=$(printf '%s' "$gate" | tr 'A-Z' 'a-z')
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  if check_gate "$gate"; then ok "$FEAT 门 $gate（$(gate_name "$gate")）校验通过"; else die "$FEAT 门 $gate 校验未通过"; fi
}

cmd_pass() {
  [ $# -eq 2 ] || die "用法：ai-gate.sh pass <feat> <gate>"
  FEAT="$1"; local gate i
  gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z')
  valid_gate "$gate"
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT（先 bash scripts/ai-new-spec.sh $FEAT）"
  for i in $GATES; do
    [ "$i" = "$gate" ] && break
    [ -f "$DIR/.gates" ] && grep -qE "^$i[[:space:]]" "$DIR/.gates" || die "前置门 $i 未通过（先 pass $i）"
  done
  if ! check_gate "$gate" >/dev/null 2>&1; then check_gate "$gate"; die "门禁校验未通过，拒绝推进 $gate"; fi
  printf '%s\t%s\t%s\n' "$gate" agent "$(date -u +%Y-%m-%dT%H:%M:%SZ)" >> "$DIR/.gates"
  ok "$FEAT 已通过 $gate（$(gate_name "$gate")）"
  [ "$gate" = g3 ] && say "   下一步：按 .agents/skills/archive-spec.md 归档" || say "   下一步：bash scripts/ai-gate.sh status $FEAT"
}

cmd_reset() {   # 回退：使 <gate> 及之后的门失效（需求 / 方案变更、代码回滚后执行）
  [ $# -ge 2 ] || die "用法：ai-gate.sh reset <feat> <gate> [--reason \"why\"]"
  FEAT="$1"; local gate reason="" n removed
  gate=$(printf '%s' "$2" | tr 'A-Z' 'a-z'); shift 2
  while [ $# -gt 0 ]; do
    case "$1" in --reason) reason="${2:-}"; shift 2 ;; *) die "未知参数 $1" ;; esac
  done
  valid_gate "$gate"
  DIR=$(feat_dir "$FEAT") || die "找不到 spec: $FEAT"
  [ -f "$DIR/.gates" ] || die "$FEAT 没有任何门记录，无需回退"
  n=${gate#g}
  removed=$(awk -F'\t' -v n="$n" '$1 ~ /^g[0-9]+$/ && substr($1,2)+0 >= n' "$DIR/.gates" | wc -l | tr -d ' ')
  [ "$removed" -gt 0 ] || die "$FEAT 的 $gate 及之后没有已通过的门记录（无需回退）"
  awk -F'\t' -v n="$n" '$1 !~ /^g[0-9]+$/ || substr($1,2)+0 < n' "$DIR/.gates" > "$DIR/.gates.tmp"
  mv "$DIR/.gates.tmp" "$DIR/.gates"
  printf 'reset\t%s\t%s\t%s\n' "$gate" "$(date -u +%Y-%m-%dT%H:%M:%SZ)" "${reason:-未说明原因}" >> "$DIR/.gates"
  ok "$FEAT 已回退：$gate 及之后的 $removed 条门记录失效"
}

render_spec() {
  local d="$1" g when next="" out
  DIR="$d"; FEAT=$(basename "$d")
  say ""
  say "📂 $FEAT   ($d)"
  for g in $GATES; do
    if [ -f "$DIR/.gates" ] && grep -qE "^$g[[:space:]]" "$DIR/.gates"; then
      when=$(grep -E "^$g[[:space:]]" "$DIR/.gates" | tail -n 1 | awk '{print $3}')
      printf '   %s %s ✅ %s\n' "$g" "$(gate_name "$g")" "$when"
    else
      printf '   %s %s ⬜\n' "$g" "$(gate_name "$g")"
      [ -z "$next" ] && next="$g"
    fi
  done
  [ -z "$next" ] && { say "   🎉 三道门已通过，可归档。"; return 0; }
  say "   下一门：$next（$(gate_name "$next")）"
  if out=$(check_gate "$next" 2>&1); then say "   可推进：bash scripts/ai-gate.sh pass $FEAT $next"
  else say "   阻断原因：$out"; fi
}

cmd_status() {
  local feat="${1:-}" d any=0
  say "== 阶段门状态 (ai-gate.sh) =="
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

main() {
  local cmd="${1:-status}"
  [ $# -gt 0 ] && shift
  case "$cmd" in
    status)   cmd_status "${1:-}" ;;
    check)    cmd_check "$@" ;;
    pass)     cmd_pass "$@" ;;
    reset)    cmd_reset "$@" ;;
    -h|--help|help) sed -n '3,15p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "未知命令 $cmd（可用：status / check / pass / reset）" ;;
  esac
}

main "$@"
