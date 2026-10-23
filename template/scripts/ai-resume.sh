#!/usr/bin/env bash
# ==============================================================================
# ai-resume.sh — 跨工具接盘快照
# 用法：owner [feat] | worker <feat> <task-id> | review <feat> <base-ref>
# owner 保留完整接手；worker 和 review 只给各自需要的项目入口。
# ==============================================================================
set -u

usage() {
  cat <<'EOF'
用法：
  bash scripts/ai-resume.sh owner [feat]
  bash scripts/ai-resume.sh worker <feat> <task-id>
  bash scripts/ai-resume.sh review <feat> <base-ref>
旧式 ai-resume.sh [feat] 已移除；请显式选择角色。
EOF
}

fail() { echo "❌ $*" >&2; usage >&2; exit 2; }
valid_feat() {
  case "$1" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac
  [ -d "docs/specs/active/$1" ]
}

ROLE="${1:-}"
case "$ROLE" in
  -h|--help) usage; exit 0 ;;
  owner)
    [ "$#" -le 2 ] || fail "owner 只接受可选的 Spec ID"
    FEATURE="${2:-}"
    if [ -n "$FEATURE" ]; then valid_feat "$FEATURE" || fail "找不到活跃 Spec 或 ID 无效：$FEATURE"; fi
    ;;
  worker)
    [ "$#" -eq 3 ] || fail "worker 需要活跃 Spec ID 和 Task 编号"
    FEATURE=$2
    TASK=$3
    valid_feat "$FEATURE" || fail "找不到活跃 Spec 或 ID 无效：$FEATURE"
    case "$TASK" in ''|0|0*|*[!0-9]*) fail "Task 编号必须是正整数" ;; esac
    task_file="docs/specs/active/$FEATURE/tasks.md"
    [ -f "$task_file" ] || fail "缺少任务原件：$task_file"
    task_body=$(awk -v task="$TASK" '
      /^## / { if (found) exit }
      /^- \[[ xX]\] (\*\*)?Task / {
        if (found) exit
        title=$0
        sub(/^- \[[ xX]\] (\*\*)?Task /, "", title)
        if (match(title,/^[0-9]+/)) {
          number=substr(title,RSTART,RLENGTH)
          # 全角冒号不能放进 []：字节 locale 下会把「（」等同首字节的字符误当分隔符。
          rest=substr(title,RLENGTH+1); suffix=substr(rest,1,1)
          if (number == task && (suffix == ":" || suffix == " " || index(rest, "：") == 1)) found=1
        }
      }
      found { print }
    ' "$task_file")
    [ -n "$task_body" ] || fail "tasks.md 中找不到 Task $TASK"
    printf '%s\n' "$task_body" | grep -qE '涉及文件.*`[^\`]+`' || fail "Task $TASK 缺少明确的涉及文件"
    printf '%s\n' "$task_body" | grep -q 'path/to/' && fail "Task $TASK 的涉及文件仍是占位路径"
    echo "== worker 接手：$FEATURE / Task $TASK =="
    echo "必读原件：AGENTS.md；$task_file 的本任务与 §4 WIP；相关 requirements.md §2/§3 和 design.md 对应章节。"
    echo "任务边界（以下来自 $task_file）："
    printf '%s\n' "$task_body"
    echo "变更前核对：git status --short；只读本任务涉及文件的 diff。需要扩范围时回到设计与门禁。"
    exit 0
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
    git diff --name-only "$BASE"...HEAD >/dev/null 2>&1 || fail "无法读取从基准到 HEAD 的完整提交 diff"
    spec_dir="docs/specs/active/$FEATURE"
    for file in requirements.md design.md tasks.md verification.md; do
      [ -f "$spec_dir/$file" ] || fail "缺少审查原件：$spec_dir/$file"
    done
    grep -qE '^- result: PASS$' "$spec_dir/verification.md" || fail "verification.md 尚无 G4 PASS；先完成正式验证"
    grep -qE '^- state: [^[:space:]]+' "$spec_dir/verification.md" || fail "verification.md 缺少可核验状态"
    target=$(sed -n 's/^- target: //p' "$spec_dir/verification.md" | head -n 1)
    saved=$(sed -n 's/^- state: //p' "$spec_dir/verification.md" | head -n 1)
    [ -n "$target" ] && [ -f "$target" ] || fail "verification.md 的目标文件不存在；先完成正式验证"
    current=$(bash scripts/ai-state-id.sh --spec "$FEATURE" "$target" 2>/dev/null) || fail "无法核对验证摘要状态"
    [ "$current" = "$saved" ] || fail "verification.md 已过期；先重新正式验证"
    changed=$({ git diff --name-only "$BASE"...HEAD; git diff --name-only; git diff --cached --name-only; git ls-files --others --exclude-standard; } | sort -u)
    [ -n "$changed" ] || fail "从 $BASE 到当前没有可审查的变更；请提供正确基准"
    echo "== review 接手：$FEATURE =="
    echo "独立审查必读：$spec_dir/requirements.md（原话、§2.3、AC）、design.md（覆盖矩阵、文件清单）、tasks.md（追溯）、verification.md，以及 .agents/skills/code-review.md。"
    echo "基准：$BASE；读取完整提交 diff：git diff $BASE...HEAD；另核对 git diff、git diff --cached 与未跟踪文件全文。"
    echo "变更路径（核对归属与相关契约）："
    printf '%s\n' "$changed"
    echo "不使用实现者自述代替原件；此接手输出不代表 G5 已通过。"
    exit 0
    ;;
  *) fail "未知角色或旧式调用：$ROLE" ;;
esac

echo "=="
echo "🔄 AI HARNESS: CROSS-TOOL HANDOFF & RESUME SNAPSHOT (跨工具接力快照)"
echo "=="

# 0. 上下文健康度
echo -e "\n[0] 上下文体积体检"
bash scripts/ai-check-bloat.sh || true

# 1. 阶段门（下一门 + 阻断原因 + 红线基线）
echo -e "\n[1] 阶段门状态"
if [ -f scripts/ai-gate.sh ]; then
  bash scripts/ai-gate.sh status "$FEATURE" || true
else
  echo "  (缺少 scripts/ai-gate.sh)"
fi

# 2. 活跃 spec 与断点
echo -e "\n[2] 活跃 Spec 与断点"
if [ -d docs/specs/active ]; then
  found=0
  for spec in docs/specs/active/*/; do
    [ -d "$spec" ] || continue
    [ -z "$FEATURE" ] || [ "$(basename "$spec")" = "$FEATURE" ] || continue
    found=1
    spec=${spec%/}
    echo "  📂 $spec"
    if [ -f "$spec/tasks.md" ]; then
      echo "  --- 当前未完成任务 ---"
      grep -E '^- \[ \]|<<< CURRENT' "$spec/tasks.md" | head -n 4 || true
      echo "  --- WIP 交接区（上一位 Agent 留下的）---"
      sed -n '/^## 4\./,$p' "$spec/tasks.md" || true
    fi
    if [ -f "$spec/verification.md" ]; then
      echo "  --- 可交接验证摘要 ---"
      grep -E '^- (spec|target|result|checks|state|command|verified_at_utc):' "$spec/verification.md" | sed 's/^/  /' || true
      target=$(sed -n 's/^- target: //p' "$spec/verification.md" | head -n 1)
      saved=$(sed -n 's/^- state: //p' "$spec/verification.md" | head -n 1)
      if [ -f "$target" ] && [ -n "$saved" ]; then
        current=$(bash scripts/ai-state-id.sh --spec "$(basename "$spec")" "$target" 2>/dev/null || true)
        [ "$current" = "$saved" ] || echo "  ⚠️  验证摘要已过期：代码或提交在验证后变化"
      fi
    fi
    if [ -f "$spec/.attempts" ]; then
      echo "  🟡 连续验证失败：$(tr -dc '0-9' <"$spec/.attempts") 次（触顶必须停下等人）"
    fi
    if [ -f "$spec/.violations" ]; then
      echo "  🧾 审计事件：$(wc -l <"$spec/.violations" | tr -d ' ') 条（$spec/.violations）"
    fi
  done
  [ "$found" -eq 1 ] || echo "  当前无活跃 Spec。新建：bash scripts/ai-new-spec.sh <feat-name>"
fi

# 2a. 持久任务池：先续做活跃 Spec；完成后选下一条待办
echo -e "\n[2a] 任务池下一步"
if [ -f scripts/ai-task-pool.sh ]; then
  bash scripts/ai-task-pool.sh next || true
fi

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

# 5. 知识库（前置强注入 / 清理候选）
echo -e "\n[5] 知识库（前置强注入 / 清理候选）"
if [ -f scripts/ai-knowledge.sh ]; then
  bash scripts/ai-knowledge.sh ttl || true
else
  echo "  (缺少 scripts/ai-knowledge.sh)"
fi
for spec in docs/specs/active/*/; do
  [ -f "$spec/tasks.md" ] || continue
  [ -z "$FEATURE" ] || [ "$(basename "$spec")" = "$FEATURE" ] || continue
  inj=$(grep -E '注入知识' "$spec/tasks.md" | head -n 1 || true)
  [ -n "$inj" ] && echo "  ${spec%/} → $inj"
done

echo ""
echo "=="
echo "💡 [给当前 AI Agent 的接力指令]"
echo "1. 先看 [1] 的「下一门」：门禁未过，不要开始编码。"
echo "2. 有未提交改动 → 先 git diff 看懂上一步；结合 [2] 的 WIP 区继续，严禁推倒重写已通过验证的代码。"
echo "3. 按任务的代码路径读 docs/architecture/00-INDEX.md 和相关模块活文档。"
echo "4. 本地跑 bash scripts/ai-verify.sh --spec <feat> <file>；摘要写入 verification.md，详细日志留本机。"
echo "5. G6 由 Agent 核验；②③按当次人的决定或 G3 的明确条件委托推进，不推断授权。"
echo "=="
