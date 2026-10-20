#!/usr/bin/env bash
# ==============================================================================
# ai-knowledge.sh — 知识卡体检（.knowledge/INDEX.md ↔ cards/K-XXXX.md）
#
# 为什么需要它：知识库一旦索引与卡片对不上，Agent 就会被"注入"过时或错误的结论，
# 比没有知识库更糟。这里只做确定性检查，不判断结论对不对（那是人的事）。
#
# 用法：
#   bash scripts/ai-knowledge.sh check   # 索引与卡片一一对应、字段合法（异常 exit 1）
#   bash scripts/ai-knowledge.sh ttl     # 列出复核期限已过的「清理候选」（只提醒，不失败）
#   bash scripts/ai-knowledge.sh list    # 列出全部卡片
#   bash scripts/ai-knowledge.sh suggest <module> # 列出该模块仍有效的候选卡，人工判断相关性
#   bash scripts/ai-knowledge.sh impact <path...> # 代码路径变化后提示关联卡片复核
# 阈值：保鲜天数来自 harness/redlines.conf 的 KNOWLEDGE_TTL_DAYS。
# ==============================================================================
set -u

KNOW=".knowledge"
INDEX="$KNOW/INDEX.md"
CARDS="$KNOW/cards"
REDLINES="harness/redlines.conf"
TTL_DAYS=180
[ -f "$REDLINES" ] && . "$REDLINES" 2>/dev/null || true

say() { printf '%s\n' "$*"; }
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
ok()  { printf '✅ %s\n' "$*"; }

card_ids()  { ls -1 "$CARDS"/K-*.md 2>/dev/null | sed -E 's#.*/##; s/\.md$//' | sort; }
index_ids() { [ -f "$INDEX" ] && grep -oE 'K-[0-9]{4}' "$INDEX" | sort -u || true; }

field() {   # $1=卡片文件 $2=字段名（类型/模块/置信度/复核期限）
  # 注意：全角「：」不能放进 []（会被按字节拆开），必须用 (：|:) 分组匹配
  sed -nE "s/^[[:space:]]*-[[:space:]]*\*\*$2\*\*[[:space:]]*(：|:)[[:space:]]*(.*)$/\2/p" "$1" | head -n 1
}

cmd_check() {
  local bad=0 f id type mod conf ttl iid
  [ -d "$CARDS" ] || { say "缺少 $CARDS（先建目录）"; return 1; }
  [ -f "$INDEX" ] || { say "缺少 $INDEX"; return 1; }
  for f in "$CARDS"/K-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    case "$id" in K-[0-9][0-9][0-9][0-9]) ;; *) say "卡片文件名不是 K-XXXX.md：$f"; bad=1; continue ;; esac
    grep -qF "$id" "$INDEX" || { say "卡片 $id 未在 $INDEX 登记"; bad=1; }
    type=$(field "$f" 类型); mod=$(field "$f" 模块); conf=$(field "$f" 置信度); ttl=$(field "$f" 复核期限)
    [ -n "$type" ] || { say "$id 缺少「类型」"; bad=1; }
    [ -n "$mod" ]  || { say "$id 缺少「模块」"; bad=1; }
    [ -n "$ttl" ]  || { say "$id 缺少「复核期限」"; bad=1; }
    printf '%s' "$ttl" | grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' \
      || { say "$id 的「复核期限」不是 YYYY-MM-DD：${ttl:-空}"; bad=1; }
    case "$conf" in
      ''|*[!0-9.]*) say "$id 的「置信度」不是 0~1 的数字：${conf:-空}"; bad=1 ;;
      *) awk -v c="$conf" 'BEGIN{ exit (c+0 < 0 || c+0 > 1) ? 1 : 0 }' \
           || { say "$id 的「置信度」超出 0~1：$conf"; bad=1; } ;;
    esac
  done
  for iid in $(index_ids); do
    [ -f "$CARDS/$iid.md" ] || { say "INDEX 引用的卡片不存在：$CARDS/$iid.md"; bad=1; }
  done
  [ "$bad" -eq 0 ] || return 1
  ok "知识卡与索引一致（$(card_ids | wc -l | tr -d ' ') 张卡片）"
}

cmd_ttl() {
  local today id ttl f n=0
  today=$(date +%Y-%m-%d)
  say "== 知识卡保鲜（今天 $today / TTL ${KNOWLEDGE_TTL_DAYS:-$TTL_DAYS} 天）=="
  for f in "$CARDS"/K-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md); ttl=$(field "$f" 复核期限)
    [ -n "$ttl" ] || continue
    if [[ "$ttl" < "$today" ]]; then
      n=$((n+1))
      printf '  ⚠️  清理候选：%s（复核期限 %s）→ gc-memory 处置：改写 / 删卡+删索引行 / 置信度 -0.1\n' "$id" "$ttl"
    fi
  done
  [ "$n" -eq 0 ] && ok "无到期卡片"
  say "   合计：$(card_ids | wc -l | tr -d ' ') 张卡片，清理候选 $n 条"
  return 0
}

cmd_list() {
  local f id
  say "== 知识卡清单（置信度 / 复核期限 / 一句话结论）=="
  [ -d "$CARDS" ] || { say "  (尚无 $CARDS)"; return 0; }
  for f in "$CARDS"/K-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    printf '  %s  %-6s  %s\n' "$id" "$(field "$f" 置信度)" "$(head -n 1 "$f" | sed 's/^# //')"
  done
}

card_current() { # $1=文件；有效期内且未标待验证
  local ttl today
  ttl=$(field "$1" 复核期限); today=$(date +%Y-%m-%d)
  [ -n "$ttl" ] && [[ "$ttl" > "$today" || "$ttl" = "$today" ]] && ! grep -q '#待验证' "$1"
}

cmd_suggest() { # 按模块给候选，不声称关键词相似就是相关
  local module="${1:-}" f id n=0
  [ -n "$module" ] || die "用法：ai-knowledge.sh suggest <module>"
  say "== $module 模块可复核的知识候选 =="
  for f in "$CARDS"/K-*.md; do
    [ -f "$f" ] || continue
    [ "$(field "$f" 模块)" = "$module" ] || continue
    card_current "$f" || continue
    id=$(basename "$f" .md)
    printf '  %s  %s\n' "$id" "$(head -n 1 "$f" | sed 's/^# //')"
    n=$((n+1))
  done
  [ "$n" -gt 0 ] || say "  无有效候选；仍须检查模块活文档和真实代码"
}

cmd_impact() { # 关联路径是提醒线索，不代替代码影响分析
  [ "$#" -gt 0 ] || die "用法：ai-knowledge.sh impact <changed-path...>"
  local f id paths prefix changed hit n=0
  for f in "$CARDS"/K-*.md; do
    [ -f "$f" ] || continue
    paths=$(field "$f" 关联路径)
    [ -n "$paths" ] || continue
    hit=0
    while IFS= read -r prefix; do
      prefix=$(printf '%s' "$prefix" | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s#/$##')
      [ -n "$prefix" ] || continue
      for changed in "$@"; do
        case "$changed" in "$prefix"|"$prefix"/*) hit=1 ;; esac
      done
    done < <(printf '%s\n' "$paths" | tr ',' '\n')
    if [ "$hit" -eq 1 ]; then
      id=$(basename "$f" .md)
      say "  ⚠️  $id 关联路径命中，使用前复核：$paths"
      n=$((n+1))
    fi
  done
  [ "$n" -gt 0 ] || say "无关联路径命中；仍需人工检查间接消费者"
}

main() {
  case "${1:-}" in
    check) cmd_check ;;
    ttl)   cmd_ttl ;;
    list)  cmd_list ;;
    suggest) shift; cmd_suggest "$@" ;;
    impact) shift; cmd_impact "$@" ;;
    ""|-h|--help|help) sed -n '3,17p' "$0" | sed 's/^# \{0,1\}//' ;;
    *) die "未知命令 $1（可用：check / ttl / list / suggest / impact）" ;;
  esac
}

main "$@"
