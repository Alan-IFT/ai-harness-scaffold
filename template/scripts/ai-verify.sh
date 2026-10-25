#!/usr/bin/env bash
# ==============================================================================
# ai-verify.sh — 增量极速验证（本地可信的最低门槛）
# 设计原则：未验证 ≠ 通过。没有任何真实检查被执行时，本脚本必须失败。
#
# 用法：bash scripts/ai-verify.sh [--quick] --spec <feature> <file_path>
# 检查命令只来自 harness/verify.conf：CUSTOM_CHECK（正式）/ QUICK_CHECK（--quick），可用 $TARGET_FILE。
# ==============================================================================
set -u
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1

QUICK=0
if [ "${1:-}" = "--quick" ]; then QUICK=1; shift; fi
[ "${1:-}" = "--spec" ] || { echo "👉 用法: bash scripts/ai-verify.sh [--quick] --spec <feature> <file_path>" >&2; exit 1; }
SPEC_NAME="${2:-}"; TARGET_FILE="${3:-}"
case "$SPEC_NAME" in ''|.|..|*[!A-Za-z0-9._-]*) echo "❌ 无效 Spec 名称: $SPEC_NAME" >&2; exit 1 ;; esac
SPEC_DIR="process/specs/active/$SPEC_NAME"
[ -d "$SPEC_DIR" ] || { echo "❌ 找不到活跃 Spec: $SPEC_NAME" >&2; exit 1; }
[ -f "$TARGET_FILE" ] || { echo "❌ 文件不存在: $TARGET_FILE" >&2; exit 1; }
TARGET_FILE="${TARGET_FILE#./}"
case "$TARGET_FILE" in
  /*|../*|*/../*|[A-Za-z]:*) echo "❌ 请使用项目内的相对路径，验证摘要才能跨工作区复用: $TARGET_FILE" >&2; exit 1 ;;
  process/*) [ "$QUICK" -eq 1 ] || { echo "❌ 正式验证目标不能选流程文件（process/ 下）: $TARGET_FILE" >&2; exit 1; } ;;
esac
export TARGET_FILE

# --- 红线预算（当前项目 harness/redlines.conf 是唯一阈值来源）---
ai_config_load harness/redlines.conf VERIFY_MAX_SECONDS VERIFY_MAX_ATTEMPTS || exit 1

START_TIME=$(date +%s)
LOG=$(mktemp "${TMPDIR:-/tmp}/ai-verify-XXXXXX.log" 2>/dev/null || printf '/tmp/ai-verify-%s.log' "$$")
CHECKS=0
FAIL=0

run_check() {   # $1=显示名；其余=要执行的命令
  local name="$1"; shift
  local t0 t1 rc
  CHECKS=$((CHECKS + 1))
  t0=$(date +%s)
  echo "  -> $name"
  { echo "### $name"; "$@"; } >>"$LOG" 2>&1
  rc=$?
  t1=$(date +%s)
  if [ "$rc" -eq 0 ]; then
    printf '     ✅ %s (%ss)\n' "$name" "$((t1 - t0))"
  else
    printf '     ❌ %s (%ss, exit %s)\n' "$name" "$((t1 - t0))" "$rc"
    FAIL=1
  fi
}

# 报告落盘前脱敏：token / secret / password / key 等一律 [REDACTED]（跨 BSD/GNU sed）
redact() {
  sed -E \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*)[^[:space:]",;]+/\1\2[REDACTED]/g' \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*")[^"]+"/\1\2[REDACTED]"/g' \
    -e 's#://[^/[:space:]]*:[^@/[:space:]]*@#://[REDACTED]@#g' \
    -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----.*/-----BEGIN PRIVATE KEY----- [REDACTED]/' \
    -e 's/(ghp_|gho_|github_pat_)[A-Za-z0-9_]{10,}/\1[REDACTED]/g' \
    -e 's/AKIA[0-9A-Z]{16}/AKIA[REDACTED]/g'
}

# ---------------------------------------------------------------- 项目检查 --
[ -f harness/verify.conf ] && . harness/verify.conf 2>/dev/null || true
if [ "$QUICK" -eq 1 ]; then
  if [ -n "${QUICK_CHECK:-}" ]; then
    run_check "快速检查 (harness/verify.conf)" bash -c "$QUICK_CHECK"
  fi
elif [ -n "${CUSTOM_CHECK:-}" ]; then
  run_check "自定义检查 (harness/verify.conf)" bash -c "$CUSTOM_CHECK"
fi

END_TIME=$(date +%s)
DUR=$((END_TIME - START_TIME))

if [ "$CHECKS" -eq 0 ]; then
  echo ""
  echo "❌ 未执行任何真实检查 —— 本次视为【未验证】（未验证 ≠ 通过）"
  [ "$QUICK" -eq 1 ] && echo "   在 harness/verify.conf 配置 QUICK_CHECK（可用 \$TARGET_FILE）" \
    || echo "   在 harness/verify.conf 配置 CUSTOM_CHECK（可用 \$TARGET_FILE）"
  FAIL=1
fi

RESULT=PASS; [ "$FAIL" -ne 0 ] && RESULT=FAIL

if [ "$QUICK" -eq 1 ]; then
  if [ "$RESULT" = FAIL ]; then tail -n 20 "$LOG" | redact | sed 's/^/   /'; fi
  rm -f "$LOG"
  echo "快速检查：$RESULT（$CHECKS 项，${DUR}s）；不生成正式验证摘要"
  [ "$RESULT" = PASS ]
  exit $?
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "   失败摘要（日志末尾 20 行，已脱敏）："
  tail -n 20 "$LOG" | redact | sed 's/^/   /'
fi

# --- 成本包络：同一目标连续失败计数（触顶=黄卡，必须停下等人，不硬闯） ---
ATT="$SPEC_DIR/.attempts"
if [ "$RESULT" = FAIL ]; then
  n=0
  [ -f "$ATT" ] && n=$(tr -dc '0-9' <"$ATT" 2>/dev/null | head -c 4)
  n=$(( ${n:-0} + 1 ))
  printf '%s\n' "$n" >"$ATT"
  if [ "$n" -ge "$VERIFY_MAX_ATTEMPTS" ]; then
    echo ""
    echo "🟡 [黄卡] 同一目标已连续失败 $n 次（上限 ${VERIFY_MAX_ATTEMPTS}）：停止第 $((n + 1)) 次硬闯。"
    echo "   请把 WIP 区更新为「已尝试方案 + 卡点 + 下一个疑点」后向人说明；"
    echo "   若判断是方向错误：回退到最近一次通过验证的提交，并同步 ai-gate.sh reset 相关门。"
  fi
else
  rm -f "$ATT"
fi

mkdir -p "$SPEC_DIR/reports"
OUT="$SPEC_DIR/reports/verify-$(date +%Y%m%d-%H%M%S)-$$.log"
{
  echo "# verify: ai-verify.sh"
  echo "# target: $TARGET_FILE"
  echo "# result: $RESULT"
  echo "# checks: $CHECKS  failed: $FAIL  duration: ${DUR}s"
  redact <"$LOG"
} >"$OUT"
echo "📄 验证报告: $OUT"
STATE_ID=$(bash scripts/ai-state-id.sh "$TARGET_FILE") || { rm -f "$LOG"; exit 1; }
SUMMARY="$SPEC_DIR/verification.md"
{
  echo "# 增量验证摘要（随项目文档和 Git 交接）"
  echo ""
  echo "- spec: $SPEC_NAME"
  echo "- target: $TARGET_FILE"
  echo "- result: $RESULT"
  echo "- checks: $CHECKS"
  echo "- state: $STATE_ID"
  echo "- command: bash scripts/ai-verify.sh --spec $SPEC_NAME $TARGET_FILE"
  echo "- verified_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
  echo ""
  echo "详细输出仅在本地 reports/；代码内容或 Git 暂存状态变化后重新验证，同一索引内容提交后仍有效。"
} >"$SUMMARY"
echo "📝 可交接摘要: $SUMMARY"
rm -f "$LOG"

if [ "$DUR" -gt "$VERIFY_MAX_SECONDS" ]; then
  echo "⚠️  超出预算 ${VERIFY_MAX_SECONDS}s（实际 ${DUR}s）：验证正在变慢，检查是否误跑了全量。"
fi

if [ "$RESULT" = PASS ]; then
  echo "✅ 增量验证通过（$CHECKS 项检查，${DUR}s）"
  exit 0
fi
echo "❌ 增量验证失败（$CHECKS 项检查，${DUR}s）"
exit 1
