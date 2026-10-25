#!/usr/bin/env bash
# ==============================================================================
# ai-check-bloat.sh — 上下文体积门禁
# 阈值来自当前项目 harness/redlines.conf
# ==============================================================================
set -u

. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
ai_config_load harness/redlines.conf AGENTS_MAX_LINES MEMORY_MAX_LINES ACTIVE_SPECS_LIMIT || exit 1

STATUS=0

check_lines() {
  local file=$1 limit=$2
  [ -f "$file" ] || return 0
  local lines
  lines=$(wc -l <"$file" | tr -d ' ')
  if [ "$lines" -gt "$limit" ]; then
    echo "⚠️  [防膨胀告警] $file 当前 $lines 行，超过硬上限 $limit 行。"
    echo "    处理：先删过期、合并重复、移到模块活文档；确需放宽先改 harness/redlines.conf 并重跑 baseline。"
    STATUS=1
  fi
}

check_lines "AGENTS.md" "$AGENTS_MAX_LINES"
check_lines "MEMORY.md" "$MEMORY_MAX_LINES"

if [ -d process/specs/active ]; then
  ACTIVE_COUNT=$(find process/specs/active -mindepth 1 -maxdepth 1 -type d 2>/dev/null | wc -l | tr -d ' ')
  if [ "$ACTIVE_COUNT" -gt "$ACTIVE_SPECS_LIMIT" ]; then
    echo "⚠️  [防膨胀告警] process/specs/active/ 积压 $ACTIVE_COUNT 个功能未归档（上限 $ACTIVE_SPECS_LIMIT）。"
    echo "    处理：按 .agents/skills/archive-spec.md 归档已完成功能。"
    STATUS=1
  fi
fi

if [ "$STATUS" -eq 0 ]; then
  echo "🟢 [Context Budget OK] 全局上下文体积正常（AGENTS.md ≤ ${AGENTS_MAX_LINES} 行，MEMORY.md ≤ ${MEMORY_MAX_LINES} 行，active spec ≤ ${ACTIVE_SPECS_LIMIT} 个）。"
fi

exit "$STATUS"
