#!/usr/bin/env bash
# 项目任务池：任务原文保存在 process/task-pool；进度由关联 Spec 的位置派生。
set -euo pipefail

POOL=process/task-pool
usage() {
  cat <<'EOF'
用法：
  bash scripts/ai-task-pool.sh add <原始需求>
  bash scripts/ai-task-pool.sh intake <原始需求>
  bash scripts/ai-task-pool.sh list
  bash scripts/ai-task-pool.sh next
  bash scripts/ai-task-pool.sh start-next
  bash scripts/ai-task-pool.sh archive <feat-id>
待办按收录 ID 排序，任务文件里写「- 优先: 是」的排在前面。
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
cleanup_lock() { rmdir "$POOL/.lock"; }
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
pending_rows() { # 输出「优先序|ID|文件」：写了「- 优先: 是」的排前面，其余按 ID
  local f id state spec rank
  for f in "$POOL"/T-*.md; do
    [ -f "$f" ] || continue
    id=$(basename "$f" .md)
    valid_id "$id" || continue
    state=$(field "$f" '队列状态')
    spec=$(field "$f" '关联 Spec')
    case "$state" in 待办|暂缓|取消) ;; *) die "$id 的队列状态无效：$state" ;; esac
    [ -n "$spec" ] || die "$id 缺少关联 Spec 字段"
    [ "$state" = 待办 ] && [ "$spec" = 无 ] || continue
    [ "$(field "$f" '优先')" = 是 ] && rank=0 || rank=1
    printf '%s|%s|%s\n' "$rank" "$id" "$f"
  done | sort -t '|' -k1,2
}
selected_pending() { pending_rows | sed -n '1s/^[01]|//p'; }
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
    # 编号同时避开已有任务文件与 feat-t-* Spec 目录：任务文件删了，Spec 目录仍可能占着号
    max=0
    for f in "$POOL"/T-*.md process/specs/active/feat-t-* process/specs/archive/*/feat-t-*; do
      [ -e "$f" ] || continue
      id=$(basename "$f" .md); id=${id#feat-}; id=${id^^}
      valid_id "$id" || continue
      n=$((10#${id#T-}))
      [ "$n" -le "$max" ] || max=$n
    done
    printf -v id 'T-%06d' "$((max + 1))"
    f="$POOL/$id.md"
    {
      printf '# %s\n\n' "$id"
      printf -- '- 队列状态: 待办\n- 关联 Spec: 无\n- 创建日期: %s\n\n' "$(date +%Y-%m-%d)"
      printf '## 原始需求\n\n%s\n\n## 补充与变更\n\n' "$title"
    } >"$f"
    printf '✅ 已收集 %s：%s\n' "$id" "$f"
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
      if [ "$(field "$POOL/$id.md" '优先')" = 是 ]; then
        printf '下一项：%s（维护者指定优先）\n' "$id"
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
    for g in g1 g2 g3; do
      grep -qE "^$g[[:space:]]" "$source_dir/.gates" 2>/dev/null || die "$feat 的 $g 未通过，拒绝归档"
    done
    bash scripts/ai-gate.sh check "$feat" g3 >/dev/null 2>&1 \
      || die "$feat 的审查已失效（通过后代码或审查记录有变），拒绝归档：运行 bash scripts/ai-gate.sh check $feat g3 查看原因"
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
    AI_HARNESS_SOURCE_TASK="$f" bash scripts/ai-new-spec.sh "$feat" >/dev/null || die "创建 Spec 失败；任务仍未关联"
    sed -i "s/^- 关联 Spec: 无$/- 关联 Spec: $feat/" "$f"
    printf '✅ %s 已关联 %s。先读任务原件，写完需求与方案后过 g1（计划）。\n' "$task_id" "$feat"
    ;;
  -h|--help|help) usage ;;
  *) usage >&2; exit 1 ;;
esac
