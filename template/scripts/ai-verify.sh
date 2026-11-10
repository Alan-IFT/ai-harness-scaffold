#!/usr/bin/env bash
# ==============================================================================
# ai-verify.sh — 正式验证：运行 harness/verify.conf 的 CUSTOM_CHECK，把结果与代码状态写进 verification.md。
# 未配置检查 = 未验证 ≠ 通过。
# 用法：bash scripts/ai-verify.sh --spec <feature>
# ==============================================================================
set -u
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1

[ "${1:-}" = "--spec" ] && [ "$#" -eq 2 ] || { echo "👉 用法: bash scripts/ai-verify.sh --spec <feature>" >&2; exit 1; }
SPEC_NAME="$2"
case "$SPEC_NAME" in ''|.|..|*[!A-Za-z0-9._-]*) echo "❌ 无效 Spec 名称: $SPEC_NAME" >&2; exit 1 ;; esac
SPEC_DIR="process/specs/active/$SPEC_NAME"
[ -d "$SPEC_DIR" ] || { echo "❌ 找不到活跃 Spec: $SPEC_NAME" >&2; exit 1; }
ai_config_load harness/redlines.conf VERIFY_MAX_ATTEMPTS || exit 1

# 输出进终端前脱敏：token / secret / password / key 等一律 [REDACTED]
redact() {
  sed -E \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*)[^[:space:]",;]+/\1\2[REDACTED]/g' \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*")[^"]+"/\1\2[REDACTED]"/g' \
    -e 's#://[^/[:space:]]*:[^@/[:space:]]*@#://[REDACTED]@#g' \
    -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----.*/[PRIVATE KEY REDACTED]/' \
    -e 's/(ghp_|gho_|github_pat_)[A-Za-z0-9_]{10,}/\1[REDACTED]/g' \
    -e 's/AKIA[0-9A-Z]{16}/AKIA[REDACTED]/g'
}

CUSTOM_CHECK=""
[ -f harness/verify.conf ] && . harness/verify.conf
START=$(date +%s)
if [ -z "$CUSTOM_CHECK" ]; then
  echo "❌ 未配置检查 —— 本次视为【未验证】：在 harness/verify.conf 配置 CUSTOM_CHECK"
  RESULT=FAIL
elif OUT=$(bash -c "$CUSTOM_CHECK" 2>&1); then
  RESULT=PASS
else
  RESULT=FAIL
  echo "   失败输出（末尾 20 行，已脱敏）："
  printf '%s\n' "$OUT" | tail -n 20 | redact | sed 's/^/   /'
fi
DUR=$(( $(date +%s) - START ))

# 成本包络：同一 Spec 连续失败计数，触顶亮黄卡，停下等人
ATT="$SPEC_DIR/.attempts"
if [ "$RESULT" = FAIL ]; then
  n=$(( $(cat "$ATT" 2>/dev/null || echo 0) + 1 ))
  echo "$n" >"$ATT"
  if [ "$n" -ge "$VERIFY_MAX_ATTEMPTS" ]; then
    echo "🟡 [黄卡] 已连续失败 $n 次（上限 $VERIFY_MAX_ATTEMPTS）：停止硬闯，把已尝试方案与卡点写进 WIP 后向人说明；方向错了就回退到最近一次通过的提交并 reset 相关门。"
  fi
else
  rm -f "$ATT"
fi

STATE_ID=$(bash scripts/ai-state-id.sh) || exit 1
cat >"$SPEC_DIR/verification.md" <<EOF
# 验证摘要（代码或暂存内容变化后重新验证；同一内容提交后仍有效）

- result: $RESULT
- state: $STATE_ID
- command: bash scripts/ai-verify.sh --spec $SPEC_NAME
- verified_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)
EOF

if [ "$RESULT" = PASS ]; then echo "✅ 验证通过（${DUR}s）：$SPEC_DIR/verification.md"; exit 0; fi
echo "❌ 验证失败（${DUR}s）"
exit 1
