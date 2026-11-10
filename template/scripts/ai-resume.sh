#!/usr/bin/env bash
# ==============================================================================
# ai-resume.sh — 跨工具接盘快照
# 用法：owner [feat] | review <feat> <base-ref>
# ==============================================================================
set -u

usage() {
  cat <<'EOF'
用法：
  bash scripts/ai-resume.sh owner [feat]
  bash scripts/ai-resume.sh review <feat> <base-ref>
EOF
}

fail() { echo "❌ $*" >&2; usage >&2; exit 2; }
valid_feat() {
  case "$1" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ -d "process/specs/active/$1" ]
}

ROLE="${1:-}"
case "$ROLE" in
  -h|--help) usage; exit 0 ;;
  owner)
    [ "$#" -le 2 ] || fail "owner 只接受可选的 Spec ID"
    FEATURE="${2:-}"
    if [ -n "$FEATURE" ]; then valid_feat "$FEATURE" || fail "找不到活跃 Spec 或 ID 无效：$FEATURE"; fi
    ;;
  review)
    [ "$#" -eq 3 ] || fail "review 需要活跃 Spec ID 和本次变更的基准提交"
    FEATURE=$2
    BASE=$3
    valid_feat "$FEATURE" || fail "找不到活跃 Spec 或 ID 无效：$FEATURE"
    case "$BASE" in ''|-*) fail "无效基准提交：$BASE" ;; esac
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || fail "review 需要 Git 仓库与可核验的完整 diff"
    git rev-parse --verify "$BASE^{commit}" >/dev/null 2>&1 || fail "无法解析基准提交：$BASE"
    git merge-base --is-ancestor "$BASE" HEAD >/dev/null 2>&1 || fail "基准提交不是当前 HEAD 的祖先；请提供本需求开始前的提交"
    spec_dir="process/specs/active/$FEATURE"
    grep -qE '^- result: PASS$' "$spec_dir/verification.md" 2>/dev/null || fail "verification.md 尚无 PASS；先完成正式验证"
    saved=$(sed -n 's/^- state: //p' "$spec_dir/verification.md" | head -n 1)
    [ "$(bash scripts/ai-state-id.sh 2>/dev/null)" = "$saved" ] || fail "verification.md 已过期；先重新正式验证"
    changed=$({ git diff --name-only "$BASE"...HEAD; git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } | sort -u)
    [ -n "$changed" ] || fail "从 $BASE 到当前没有可审查的变更；请提供正确基准"
    echo "== review 接手：$FEATURE =="
    echo "独立审查必读：$spec_dir/requirements.md（原话、AC）、tasks.md（方案与任务）、verification.md，以及 .agents/skills/code-review.md。"
    echo "基准：$BASE；读取完整提交 diff：git diff $BASE...HEAD；另核对 git diff、git diff --cached 与未跟踪文件全文。"
    echo "变更路径（核对归属与相关契约）："
    printf '%s\n' "$changed"
    echo "不使用实现者自述代替原件；此接手输出不代表审查已通过。"
    exit 0
    ;;
  *) fail "未知角色：$ROLE" ;;
esac

echo "=="
echo "🔄 AI HARNESS: CROSS-TOOL HANDOFF & RESUME SNAPSHOT (跨工具接力快照)"
echo "=="

# 1. 阶段门（下一门 + 阻断原因）
echo -e "\n[1] 阶段门状态"
bash scripts/ai-gate.sh status "$FEATURE" || true

# 2. 活跃 spec 与断点
echo -e "\n[2] 活跃 Spec 与断点"
found=0
for spec in process/specs/active/*/; do
  [ -d "$spec" ] || continue
  [ -z "$FEATURE" ] || [ "$(basename "$spec")" = "$FEATURE" ] || continue
  found=1
  spec=${spec%/}
  echo "  📂 $spec"
  if [ -f "$spec/tasks.md" ]; then
    echo "  --- 当前未完成任务 ---"
    grep -E '^- \[ \]' "$spec/tasks.md" | head -n 4 || true
    echo "  --- WIP 交接区（上一位 Agent 留下的）---"
    sed -n '/^## 4\./,$p' "$spec/tasks.md" || true
  fi
  if [ -f "$spec/verification.md" ]; then
    echo "  --- 可交接验证摘要 ---"
    grep -E '^- (result|state|verified_at_utc):' "$spec/verification.md" | sed 's/^/  /' || true
    saved=$(sed -n 's/^- state: //p' "$spec/verification.md" | head -n 1)
    if [ -n "$saved" ]; then
      current=$(bash scripts/ai-state-id.sh 2>/dev/null || true)
      [ "$current" = "$saved" ] || echo "  ⚠️  验证摘要已过期：代码或提交在验证后变化"
    fi
  fi
  if [ -f "$spec/.attempts" ]; then
    echo "  🟡 连续验证失败：$(tr -dc '0-9' <"$spec/.attempts") 次（触顶必须停下等人）"
  fi
done
[ "$found" -eq 1 ] || echo "  当前无活跃 Spec"

# 2a. 持久任务池：先续做活跃 Spec；完成后选下一条待办
echo -e "\n[2a] 任务池下一步"
bash scripts/ai-task-pool.sh next || true

# 3. 工作区残局
echo -e "\n[3] 工作区未提交的半成品 (Git Dirty State)"
if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git status -s
  echo -e "\n  --- 正在编辑的文件（下一个 Agent 必须重读，不要凭记忆）---"
  { git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } | sort -u
  echo -e "\n[4] 变更统计与最近提交"
  git diff --stat
  git log -n 3 --oneline 2>/dev/null || echo "  暂无提交记录"
else
  echo "  (尚未初始化 Git 仓库；建议 git init，否则无法用 diff 接力)"
fi
