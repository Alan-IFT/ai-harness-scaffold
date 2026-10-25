#!/usr/bin/env bash
# 项目任务池：任务原文保存在 process/task-pool；进度由关联 Spec 的位置派生。
set -euo pipefail

POOL=process/task-pool
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
usage() {
  cat <<'EOF'
用法：
  bash scripts/ai-task-pool.sh add <原始需求>
  bash scripts/ai-task-pool.sh intake <原始需求>
  bash scripts/ai-task-pool.sh update <T-ID> <补充或变更>
  bash scripts/ai-task-pool.sh prefer <T-ID>
  bash scripts/ai-task-pool.sh list
  bash scripts/ai-task-pool.sh next
  bash scripts/ai-task-pool.sh start-next
  bash scripts/ai-task-pool.sh archive <feat-id>
待办按收录 ID 排序；prefer 一次性指定下一项。
intake 供 AI 在收到独立新需求时调用；维护者只需用自然语言提出需求。
EOF
}
die() { printf '❌ %s\n' "$*" >&2; exit 1; }
valid_id() { [[ "$1" =~ ^T-[0-9]{6}$ ]]; }
valid_feat() { [[ "$1" =~ ^[A-Za-z0-9._-]+$ ]] && [ "$1" != . ] && [ "$1" != .. ]; }
field() { sed -n "s/^- $2: //p" "$1" | head -n 1; }
summary_for() { awk '/^## 原始需求[[:space:]]*$/ { inside=1; next } inside && NF { print; exit }' "$1"; }
# 全角空格在字节 locale 下不属于 [[:space:]]，先归一，否则纯全角空格会被当成有内容
nonblank() { local s=${1//　/ }; [[ "$s" =~ [^[:space:]] ]]; }
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
    for name in requirements.md tasks.md verification.md; do
      rm -f -- "$START_SPEC/$name"
    done
    rmdir "$START_SPEC/reports" "$START_SPEC" 2>/dev/null || true
  fi
  rmdir "$POOL/.lock"
}
spec_location() {
  local spec=$1
  [ -d "process/specs/active/$spec" ] && { printf '进行中'; return; }
  if find process/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$spec" -print -quit 2>/dev/null | grep -q .; then
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
  local f id state spec
  for f in "$POOL"/T-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    valid_id "$id" || continue
    state=$(field "$f" '队列状态')
    spec=$(field "$f" '关联 Spec')
    case "$state" in 待办|暂缓|取消) ;; *) die "$id 的队列状态无效：$state" ;; esac
    [ -n "$spec" ] || die "$id 缺少关联 Spec 字段"
    [ "$state" = 待办 ] && [ "$spec" = 无 ] || continue
    printf '%s|%s\n' "$id" "$f"
  done | sort -t '|' -k1,1
}
selected_pending() {
  local id f
  if [ -e "$POOL/NEXT" ]; then
    id=$(cat "$POOL/NEXT")
    valid_id "$id" || die "人工指定的下一项无效：$id；请重新指定"
    f=$(task_file "$id")
    [ "$(field "$f" '队列状态')" = 待办 ] && [ "$(field "$f" '关联 Spec')" = 无 ] \
      || die "人工指定的下一项不是未关联的待办：$id；请重新指定"
    printf '%s|%s\n' "$id" "$f"
  else
    pending_rows | sed -n '1p'
  fi
}
case "${1:-}" in
  intake)
    shift
    [ "$#" -ge 1 ] || die "缺少原始需求"
    added=$(bash "$0" add "$@") || die "需求收录失败，未启动任务"
    printf '%s\n' "$added"
    [[ "$added" =~ (T-[0-9]{6}) ]] || die "需求已收录但无法识别任务 ID；请查看任务池后恢复，勿重复提交"
    added_id=${BASH_REMATCH[1]}
    bash "$0" start-next \
      || die "已收录 $added_id，但自动路由失败；请修复后运行 next，勿重复提交"
    ;;
  add)
    shift
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
      printf -- '- 队列状态: 待办\n- 关联 Spec: 无\n- 创建日期: %s\n\n' "$(date +%Y-%m-%d)"
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
  prefer)
    [ "$#" -eq 2 ] || die "用法：prefer <T-ID>"
    f=$(task_file "$2")
    lock_pool
    [ "$(field "$f" '关联 Spec')" = 无 ] && [ "$(field "$f" '队列状态')" = 待办 ] \
      || die "任务不是未关联的待办：$2"
    printf '%s\n' "$2" >"$POOL/NEXT"
    printf '✅ 已指定 %s 为下一项；当前活跃 Spec 完成后生效。\n' "$2"
    ;;
  list)
    [ "$#" -eq 1 ] || die "list 不接受参数"
    found=0
    for f in "$POOL"/T-*.md; do
      [ -f "$f" ] || continue
      id=$(basename "$f" .md)
      valid_id "$id" || continue
      found=1
      printf '%s  %s  %s  %s\n' "$id" "$(status_for "$f")" "$(field "$f" '关联 Spec')" "$(summary_for "$f")"
    done
    [ "$found" -eq 1 ] || printf '任务池为空。维护者直接向 AI 提需求，由 AI 使用 intake 收录。\n'
    ;;
  next)
    [ "$#" -eq 1 ] || die "next 不接受参数"
    for specdir in process/specs/active/*/; do
      [ -d "$specdir" ] || continue
      spec=${specdir%/}; spec=${spec##*/}
      printf '续做活跃 Spec：%s；运行 bash scripts/ai-resume.sh owner %s\n' "$spec" "$spec"
      exit 0
    done
    row=$(selected_pending)
    if [ -z "$row" ]; then
      printf '暂无待办任务。维护者直接向 AI 提需求，由 AI 使用 intake 收录。\n'
    else
      id=${row%%|*}
      if [ -e "$POOL/NEXT" ]; then
        printf '下一项：%s（人工指定）\n' "$id"
      else
        printf '下一项：%s（按收录顺序）\n' "$id"
      fi
      printf '原始需求：%s\n' "$(summary_for "$POOL/$id.md")"
      printf '原件：%s/%s.md；开始：bash scripts/ai-task-pool.sh start-next\n' "$POOL" "$id"
    fi
    ;;
  archive)
    [ "$#" -eq 2 ] || die "用法：archive <feat-id>"
    feat=$2
    valid_feat "$feat" || die "Spec ID 无效：$feat"
    lock_pool
    source_dir="process/specs/active/$feat"
    [ -d "$source_dir" ] || die "活跃 Spec 不存在：$feat"
    target_parent="process/specs/archive/$(date +%Y-%m)"
    mkdir -p "$target_parent"
    [ ! -e "$target_parent/$feat" ] || die "归档目标已存在：$target_parent/$feat"
    mv -- "$source_dir" "$target_parent/$feat" || die "归档移动失败：$feat"
    printf '✅ 已归档 %s：%s/%s\n' "$feat" "$target_parent" "$feat"
    ;;
  start-next)
    [ "$#" -eq 1 ] || die "start-next 不接受参数"
    lock_pool
    for specdir in process/specs/active/*/; do
      [ -d "$specdir" ] || continue
      spec=${specdir%/}; spec=${spec##*/}
      printf '续做活跃 Spec：%s；运行 bash scripts/ai-resume.sh owner %s\n' "$spec" "$spec"
      exit 0
    done
    row=$(selected_pending)
    [ -n "$row" ] || die "暂无可启动的待办任务"
    task_id=${row%%|*}
    f=$(task_file "$task_id")
    feat="feat-${task_id,,}"
    [ "$(field "$f" '关联 Spec')" = 无 ] && [ "$(field "$f" '队列状态')" = 待办 ] || die "任务不是未关联的待办：$task_id"
    [ ! -e "process/specs/active/$feat" ] || die "Spec ID 已占用：$feat"
    if find process/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$feat" -print -quit 2>/dev/null | grep -q .; then
      die "Spec ID 已归档，不能重用：$feat"
    fi
    LINK_TMP=$(mktemp "$POOL/.link.XXXXXX") || die "无法暂存任务关联"
    sed "s/^- 关联 Spec: 无$/- 关联 Spec: $feat/" "$f" >"$LINK_TMP" || die "无法暂存任务关联"
    [ "$(field "$LINK_TMP" '关联 Spec')" = "$feat" ] || die "任务关联字段无效"
    AI_HARNESS_SOURCE_TASK="$f" bash scripts/ai-new-spec.sh "$feat" || die "创建 Spec 失败；任务仍未关联"
    START_SPEC="process/specs/active/$feat"
    mv -f -- "$LINK_TMP" "$f" || die "无法更新任务关联；正在回滚新建 Spec"
    LINK_TMP=""
    START_SPEC=""
    if [ -e "$POOL/NEXT" ] && [ "$(cat "$POOL/NEXT")" = "$task_id" ]; then
      rm -f -- "$POOL/NEXT"
    fi
    printf '✅ %s 已关联 %s。先读任务原件，写完需求与方案后过 g1（计划）。\n' "$task_id" "$feat"
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac
