#!/usr/bin/env bash
# ==============================================================================
# ai-check-bloat.sh — 上下文体积门禁
# 阈值来自 harness/redlines.conf（人类可改，AI 不可自改）
# ==============================================================================
set -u

AGENTS_MAX_LINES=120
MEMORY_MAX_LINES=150
ACTIVE_SPECS_LIMIT=3
[ -f harness/redlines.conf ] && . harness/redlines.conf 2>/dev/null || true
case "${AGENTS_MAX_LINES:-}"   in ''|*[!0-9]*) AGENTS_MAX_LINES=120 ;; esac
case "${MEMORY_MAX_LINES:-}"   in ''|*[!0-9]*) MEMORY_MAX_LINES=150 ;; esac
case "${ACTIVE_SPECS_LIMIT:-}" in ''|*[!0-9]*) ACTIVE_SPECS_LIMIT=3 ;; esac

STATUS=0

check_lines() {
  local file=$1 limit=$2
  [ -f "$file" ] || return 0
  local lines
  lines=$(wc -l <"$file" | tr -d ' ')
  if [ "$lines" -gt "$limit" ]; then
    echo "⚠️  [防膨胀告警] $file 当前 $lines 行，超过硬上限 $limit 行。"
    echo "    处理：先按 .agents/skills/gc-memory.md 做减法；确需放宽先改 harness/redlines.conf 并重跑 baseline。"
    STATUS=1
  fi
}

check_lines "AGENTS.md" "$AGENTS_MAX_LINES"
check_lines "MEMORY.md" "$MEMORY_MAX_LINES"

if [ -d docs/specs/active ]; then
  ACTIVE_COUNT=$(find docs/specs/active -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ACTIVE_COUNT" -gt "$ACTIVE_SPECS_LIMIT" ]; then
    echo "⚠️  [防膨胀告警] docs/specs/active/ 积压 $ACTIVE_COUNT 个功能未归档（上限 $ACTIVE_SPECS_LIMIT）。"
    echo "    处理：按 .agents/skills/archive-spec.md 归档已完成功能。"
    STATUS=1
  fi
fi

if [ "$STATUS" -eq 0 ]; then
  echo "🟢 [Context Budget OK] 全局上下文体积正常（AGENTS.md ≤ ${AGENTS_MAX_LINES} 行，MEMORY.md ≤ ${MEMORY_MAX_LINES} 行，active spec ≤ ${ACTIVE_SPECS_LIMIT} 个）。"
fi

exit "$STATUS"
