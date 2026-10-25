#!/usr/bin/env bash
# ==============================================================================
# ai-check-bloat.sh — 上下文体积门禁
# 阈值来自当前项目 harness/redlines.conf
# ==============================================================================
set -u

. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
ai_config_load harness/redlines.conf AGENTS_MAX_LINES MEMORY_MAX_LINES || exit 1

STATUS=0

check_lines() {
  local file=$1 limit=$2
  [ -f "$file" ] || return 0
  local lines
  lines=$(wc -l <"$file" | tr -d ' ')
  if [ "$lines" -gt "$limit" ]; then
    echo "⚠️  [防膨胀告警] $file 当前 $lines 行，超过硬上限 $limit 行。"
    echo "    处理：先删过期、合并重复、移到模块活文档；确需放宽由人改 harness/redlines.conf。"
    STATUS=1
  fi
}

check_lines "AGENTS.md" "$AGENTS_MAX_LINES"
check_lines "MEMORY.md" "$MEMORY_MAX_LINES"

if [ "$STATUS" -eq 0 ]; then
  echo "🟢 [Context Budget OK] 全局上下文体积正常（AGENTS.md ≤ ${AGENTS_MAX_LINES} 行，MEMORY.md ≤ ${MEMORY_MAX_LINES} 行）。"
fi

exit "$STATUS"
