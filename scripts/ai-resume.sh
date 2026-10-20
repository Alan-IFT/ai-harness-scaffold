#!/usr/bin/env bash
# ==============================================================================
# ai-resume.sh — 跨工具接盘快照
# 输出：上下文体检 → 阶段门 → 活跃 spec 与断点 → 未提交改动 → 接力指令
# ==============================================================================
set -u

echo "=="
echo "🔄 AI HARNESS: CROSS-TOOL HANDOFF & RESUME SNAPSHOT (跨工具接力快照)"
echo "=="

# 0. 上下文健康度
echo -e "\n[0] 上下文体积体检"
bash scripts/ai-check-bloat.sh || true

# 1. 阶段门（下一门 + 阻断原因 + 红线基线）
echo -e "\n[1] 阶段门状态"
if [ -f scripts/ai-gate.sh ]; then
  bash scripts/ai-gate.sh status || true
else
  echo "  (缺少 scripts/ai-gate.sh)"
fi

# 2. 活跃 spec 与断点
echo -e "\n[2] 活跃 Spec 与断点"
if [ -d docs/specs/active ]; then
  found=0
  for spec in docs/specs/active/*/; do
    [ -d "$spec" ] || continue
    found=1
    spec=${spec%/}
    echo "  📂 $spec"
    if [ -f "$spec/tasks.md" ]; then
      echo "  --- 当前未完成任务 ---"
      grep -E '^- \[ \]|<<< CURRENT' "$spec/tasks.md" | head -n 4 || true
      echo "  --- WIP 交接区（上一位 Agent 留下的）---"
      sed -n '/Current WIP/,$p' "$spec/tasks.md" | head -n 20 || true
    fi
    latest=$(ls -1t "$spec"/reports/verify-*.log 2>/dev/null | head -n 1)
    if [ -n "$latest" ]; then
      echo "  --- 上次增量验证 ---"
      grep -E '^# (result|verify|target|checks)' "$latest" 2>/dev/null | sed 's/^/  /' || true
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

echo ""
echo "=="
echo "💡 [给当前 AI Agent 的接力指令]"
echo "1. 先看 [1] 的「下一门」：门禁未过，不要开始编码。"
echo "2. 有未提交改动 → 先 git diff 看懂上一步；结合 [2] 的 WIP 区继续，严禁推倒重写已通过验证的代码。"
echo "3. 按任务的代码路径读 @docs/architecture/00-INDEX.md，只加载命中的那 1 篇模块活文档。"
echo "4. 本地只跑 bash scripts/ai-verify.sh <file>；全量测试交给 CI，不要把全量输出拉进上下文。"
echo "5. G6 是人工验收门：到点就停下等人，不要自己 pass。"
echo "=="
