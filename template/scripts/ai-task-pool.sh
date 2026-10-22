#!/usr/bin/env bash
# 项目任务池：任务原文保存在 docs/task-pool；进度由关联 Spec 的位置派生。
set -euo pipefail

POOL=docs/task-pool
usage() {
  cat <<'EOF'
用法：
  bash scripts/ai-task-pool.sh add [--priority P0|P1|P2] <原始需求>
  bash scripts/ai-task-pool.sh update <T-ID> <补充或变更>
  bash scripts/ai-task-pool.sh list
  bash scripts/ai-task-pool.sh next
  bash scripts/ai-task-pool.sh start <T-ID> <feat-id>
P0 最高，缺省 P2；同级按 ID。新会话先运行 owner 接手或 next。
EOF
}
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
valid_id() { [[ "$1" =~ ^T-[0-9]{6}$ ]]; }
valid_feat() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] && [ "$1" != . ] && [ "$1" != .. ]; }
field() { sed -n "s/^- $2: //p" "$1" | head -n 1; }
summary_for() { awk '/^## 原始需求[[:space:]]*$/ { inside=1; next } inside && NF { print; exit }' "$1"; }
nonblank() { [[ "$1" =~ [^[:space:]] ]]; }
task_file() {
  valid_id "$1" || die "任务 ID 无效：$1"
  [ -f "$POOL/$1.md" ] || die "任务不存在：$1"
  printf '%s\n' "$POOL/$1.md"
}
lock_pool() {
  mkdir -p "$POOL"
  mkdir "$POOL/.lock" 2>/dev/null || die "任务池正被另一进程修改；稍后重试（若异常中断，核实后移除 $POOL/.lock）"
  trap cleanup_lock EXIT
}
cleanup_lock() {
  [ -z "${LINK_TMP:-}" ] || rm -f -- "$LINK_TMP"
  if [ -n "${START_SPEC:-}" ]; then
    for name in requirements.md design.md tasks.md acceptance.md verification.md; do
      rm -f -- "$START_SPEC/$name"
    done
    rmdir "$START_SPEC/reports" "$START_SPEC" 2>/dev/null || true
  fi
  rmdir "$POOL/.lock"
}
spec_location() {
  local spec=$1
  [ -d "docs/specs/active/$spec" ] && { printf '进行中'; return; }
  if find docs/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$spec" -print -quit 2>/dev/null | grep -q .; then
    printf '已归档'
  else
    printf '关联异常'
  fi
}
status_for() {
  local f=$1 spec
  spec=$(field "$f" '关联 Spec')
  if [ -z "$spec" ] || [ "$spec" = 无 ]; then
    field "$f" '队列状态'
  else
    spec_location "$spec"
  fi
}
pending_rows() {
  local f id priority state spec
  for f in "$POOL"/T-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    valid_id "$id" || continue
    state=$(field "$f" '队列状态')
    spec=$(field "$f" '关联 Spec')
    case "$state" in 待办|暂缓|取消) ;; *) die "$id 的队列状态无效：$state" ;; esac
    [ -n "$spec" ] || die "$id 缺少关联 Spec 字段"
    priority=$(field "$f" '优先级')
    case "$priority" in P0|P1|P2) ;; *) die "$id 的优先级无效：$priority" ;; esac
    [ "$state" = 待办 ] && [ "$spec" = 无 ] || continue
    printf '%s|%s|%s\n' "${priority#P}" "$id" "$f"
  done | sort -t '|' -k1,1n -k2,2
}
case "${1:-}" in
  add)
    shift
    priority=P2
    if [ "${1:-}" = --priority ]; then
      [ "$#" -ge 2 ] || die "--priority 缺少值"
      priority=$2; shift 2
    fi
    case "$priority" in P0|P1|P2) ;; *) die "优先级只允许 P0/P1/P2" ;; esac
    [ "$#" -ge 1 ] || die "缺少原始需求"
    title="$*"
    nonblank "$title" || die "原始需求不能为空"
    [[ "$title" != *$'\n'* && "$title" != *$'\r'* ]] || die "原始需求须为单行；长内容可在创建后编辑任务文件"
    lock_pool
    max=0
    for f in "$POOL"/T-*.md; do
      [ -f "$f" ] || continue
      id=$(basename "$f" .md)
      valid_id "$id" || continue
      n=$((10#${id#T-}))
      [ "$n" -le "$max" ] || max=$n
    done
    [ "$max" -lt 999999 ] || die "任务 ID 已用尽"
    printf -v id 'T-%06d' "$((max + 1))"
    f="$POOL/$id.md"
    [ ! -e "$f" ] || die "任务文件已存在：$f"
    {
      printf '# %s\n\n' "$id"
      printf -- '- 优先级: %s\n- 队列状态: 待办\n- 关联 Spec: 无\n- 创建日期: %s\n\n' "$priority" "$(date +%Y-%m-%d)"
      printf '## 原始需求\n\n%s\n\n## 补充与变更\n\n' "$title"
    } >"$f"
    printf '✅ 已收集 %s：%s\n' "$id" "$f"
    ;;
  update)
    [ "$#" -ge 3 ] || die "用法：update <T-ID> <补充或变更>"
    f=$(task_file "$2")
    shift 2
    note="$*"
    nonblank "$note" || die "补充不能为空"
    [[ "$note" != *$'\n'* && "$note" != *$'\r'* ]] || die "补充须为单行；长内容可直接编辑任务文件"
    lock_pool
    printf -- '- %s：%s\n' "$(date +%Y-%m-%d)" "$note" >>"$f"
    printf '✅ 已追加 %s；若关联 Spec 已开始，请同步修订需求并按门禁回退。\n' "$(basename "$f" .md)"
    ;;
  list)
    [ "$#" -eq 1 ] || die "list 不接受参数"
    found=0
    for f in "$POOL"/T-*.md; do
      [ -f "$f" ] || continue
      id=$(basename "$f" .md)
      valid_id "$id" || continue
      found=1
      printf '%s  %s  %s  %s  %s\n' "$id" "$(field "$f" '优先级')" "$(status_for "$f")" "$(field "$f" '关联 Spec')" "$(summary_for "$f")"
    done
    [ "$found" -eq 1 ] || printf '任务池为空。用 add 收集第一条需求。\n'
    ;;
  next)
    [ "$#" -eq 1 ] || die "next 不接受参数"
    for specdir in docs/specs/active/*/; do
      [ -d "$specdir" ] || continue
      spec=${specdir%/}; spec=${spec##*/}
      printf '续做活跃 Spec：%s；运行 bash scripts/ai-resume.sh owner %s\n' "$spec" "$spec"
      exit 0
    done
    row=$(pending_rows | sed -n '1p')
    if [ -z "$row" ]; then
      printf '暂无待办任务。用 add 收集需求。\n'
    else
      id=${row#*|}; id=${id%%|*}
      printf '下一项：%s（%s）\n' "$id" "$(field "$POOL/$id.md" '优先级')"
      printf '原始需求：%s\n' "$(summary_for "$POOL/$id.md")"
      printf '原件：%s/%s.md；开始：bash scripts/ai-task-pool.sh start %s <feat-id>\n' "$POOL" "$id" "$id"
    fi
    ;;
  start)
    [ "$#" -eq 3 ] || die "用法：start <T-ID> <feat-id>"
    f=$(task_file "$2")
    feat=$3
    valid_feat "$feat" || die "Spec ID 无效：$feat"
    lock_pool
    [ "$(field "$f" '关联 Spec')" = 无 ] && [ "$(field "$f" '队列状态')" = 待办 ] || die "任务不是未关联的待办：$2"
    case "$(field "$f" '优先级')" in P0|P1|P2) ;; *) die "任务优先级无效：$2" ;; esac
    for specdir in docs/specs/active/*/; do
      [ -d "$specdir" ] || continue
      die "已有活跃 Spec：${specdir%/}；先完成或移交后再开始下一项"
    done
    [ ! -e "docs/specs/active/$feat" ] || die "Spec ID 已占用：$feat"
    if find docs/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$feat" -print -quit 2>/dev/null | grep -q .; then
      die "Spec ID 已归档，不能重用：$feat"
    fi
    LINK_TMP=$(mktemp "$POOL/.link.XXXXXX") || die "无法暂存任务关联"
    sed "s/^- 关联 Spec: 无$/- 关联 Spec: $feat/" "$f" >"$LINK_TMP" || die "无法暂存任务关联"
    [ "$(field "$LINK_TMP" '关联 Spec')" = "$feat" ] || die "任务关联字段无效"
    AI_HARNESS_SOURCE_TASK="$f" bash scripts/ai-new-spec.sh "$feat" || die "创建 Spec 失败；任务仍未关联"
    START_SPEC="docs/specs/active/$feat"
    mv -f -- "$LINK_TMP" "$f" || die "无法更新任务关联；正在回滚新建 Spec"
    LINK_TMP=""
    START_SPEC=""
    printf '✅ %s 已关联 %s。先读任务原件，再完成 G1~G3。\n' "$2" "$feat"
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac
