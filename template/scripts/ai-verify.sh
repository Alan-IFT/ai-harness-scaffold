#!/usr/bin/env bash
# ==============================================================================
# ai-verify.sh — 增量极速验证（本地可信的最低门槛）
# 设计原则：未验证 ≠ 通过。没有任何真实检查被执行时，本脚本必须失败。
#
# 用法：bash scripts/ai-verify.sh [--quick] --spec <feature> <file_path>
# 无活跃 Spec 时可只传文件；恰好一个活跃 Spec 时兼容旧用法。
# 自动探测（工具已安装才跑）：ESLint / tsc / Vitest；ruff / pytest；go vet / go test
# 自定义：harness/verify.conf 里写  CUSTOM_CHECK="<命令，可用 $TARGET_FILE>"
# ==============================================================================
set -u

QUICK=0
if [ "${1:-}" = "--quick" ]; then QUICK=1; shift; fi
SPEC_NAME=""
if [ "${1:-}" = "--spec" ]; then
  SPEC_NAME="${2:-}"
  shift 2
  case "$SPEC_NAME" in ''|.|..|*[!A-Za-z0-9._-]*) echo "❌ 无效 Spec 名称: $SPEC_NAME" >&2; exit 1 ;; esac
fi
TARGET_FILE="${1:-}"
if [ -z "$TARGET_FILE" ]; then
  echo "❌ 错误: 请指定要验证的文件路径！"
  echo "👉 用法: bash scripts/ai-verify.sh [--quick] --spec <feature> <file_path>"
  exit 1
fi
if [ ! -f "$TARGET_FILE" ]; then
  echo "❌ 错误: 文件不存在: $TARGET_FILE"
  exit 1
fi
case "$TARGET_FILE" in
  /*|../*|*/../*|[A-Za-z]:/*|[A-Za-z]:\\*)
    echo "❌ 请使用项目内的相对文件路径，确保验证摘要能跨工作区复用: $TARGET_FILE" >&2
    exit 1 ;;
esac
case "$TARGET_FILE" in
  *//*|*/./*)
    echo "❌ 请使用无重复分隔符或中间 ./ 的规范化项目路径: $TARGET_FILE" >&2
    exit 1 ;;
esac
if [ "$QUICK" -eq 0 ]; then
  stable_target="$TARGET_FILE"
  while [ "${stable_target#./}" != "$stable_target" ]; do stable_target="${stable_target#./}"; done
  case "$stable_target" in
    docs/specs/*|docs/metrics.md|docs/task-pool/*)
      echo "❌ 正式验证目标不能选归档时会移动或更新的流程文件: $TARGET_FILE" >&2
      exit 1 ;;
  esac
fi
export TARGET_FILE

# 验证前确定归属，避免多任务时把结果写错 Spec。
REPORT_DIR=""; SPEC_DIR=""
if [ -n "$SPEC_NAME" ]; then
  SPEC_DIR="docs/specs/active/$SPEC_NAME"
  [ -d "$SPEC_DIR" ] || { echo "❌ 找不到活跃 Spec: $SPEC_NAME" >&2; exit 1; }
elif [ -d docs/specs/active ]; then
  count=0; only=""
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    count=$((count + 1)); only="$d"
  done < <(find docs/specs/active -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  if [ "$count" -gt 1 ]; then
    echo "❌ 有 $count 个活跃 Spec，请显式指定 --spec <feature>" >&2
    exit 1
  fi
  if [ "$count" -eq 1 ]; then
    SPEC_DIR="$only"; SPEC_NAME="$(basename "$only")"
    echo "ℹ️  已关联唯一活跃 Spec: $SPEC_NAME（建议显式传 --spec）"
  fi
fi
[ -n "$SPEC_DIR" ] && REPORT_DIR="$SPEC_DIR/reports"

# --- 红线预算（当前项目 harness/redlines.conf 是唯一阈值来源）---
. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1
ai_config_load harness/redlines.conf VERIFY_MAX_SECONDS VERIFY_MAX_ATTEMPTS || exit 1

START_TIME=$(date +%s)
LOG=$(mktemp "${TMPDIR:-/tmp}/ai-verify-XXXXXX.log" 2>/dev/null || printf '/tmp/ai-verify-%s.log' "$$")
CHECKS=0
FAIL=0

run_check() {   # $1=显示名；其余=要执行的命令
  local name="$1"; shift
  local t0 t1 rc
  CHECKS=$((CHECKS + 1))
  t0=$(date +%s)
  echo "  -> $name"
  { echo "### $name"; "$@"; } >>"$LOG" 2>&1
  rc=$?
  t1=$(date +%s)
  if [ "$rc" -eq 0 ]; then
    printf '     ✅ %s (%ss)\n' "$name" "$((t1 - t0))"
  else
    printf '     ❌ %s (%ss, exit %s)\n' "$name" "$((t1 - t0))" "$rc"
    FAIL=1
  fi
}

# 报告落盘前脱敏：token / secret / password / key 等一律 [REDACTED]（跨 BSD/GNU sed）
redact() {
  sed -E \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*)[^[:space:]",;]+/\1\2[REDACTED]/g' \
    -e 's/([Tt]oken|[Ss]ecret|[Pp]assword|[Pp]asswd|api[_-]?[Kk]ey|access[_-]?[Kk]ey|private[_-]?[Kk]ey|[Aa]uthorization|[Bb]earer)([[:space:]]*[:=][[:space:]]*")[^"]+"/\1\2[REDACTED]"/g' \
    -e 's#://[^/[:space:]]*:[^@/[:space:]]*@#://[REDACTED]@#g' \
    -e 's/-----BEGIN [A-Z ]*PRIVATE KEY-----.*/-----BEGIN PRIVATE KEY----- [REDACTED]/' \
    -e 's/(ghp_|gho_|github_pat_)[A-Za-z0-9_]{10,}/\1[REDACTED]/g' \
    -e 's/AKIA[0-9A-Z]{16}/AKIA[REDACTED]/g'
}

has_dep() { grep -q "\"$1\"" package.json 2>/dev/null; }

# quick 只运行项目显式配置的 QUICK_CHECK，避免自动探测触发昂贵的全量工具。
if [ "$QUICK" -eq 0 ]; then
# ---------------------------------------------------------------- Node / TS --
if [ -f package.json ]; then
  if [ ! -d node_modules ]; then
    echo "  ℹ️  未安装 node_modules，跳过 JS/TS 检查（先 npm ci）"
  else
    has_dep eslint && [ -x node_modules/.bin/eslint ] \
      && run_check "ESLint 单文件" node_modules/.bin/eslint "$TARGET_FILE" --max-warnings=0
    has_dep typescript && [ -x node_modules/.bin/tsc ] \
      && run_check "TypeScript 增量类型检查" node_modules/.bin/tsc --noEmit --incremental
    has_dep vitest && [ -x node_modules/.bin/vitest ] \
      && run_check "Vitest 关联单测" node_modules/.bin/vitest related "$TARGET_FILE" --run
  fi
fi

# -------------------------------------------------------------------- Python --
if [ -f pyproject.toml ] || [ -f requirements.txt ]; then
  if command -v ruff >/dev/null 2>&1; then
    run_check "Ruff 单文件" ruff check "$TARGET_FILE"
  else
    echo "  ℹ️  未安装 ruff，跳过 Python lint"
  fi
  if command -v python >/dev/null 2>&1 && python -c 'import pytest' >/dev/null 2>&1; then
    case "$(basename "$TARGET_FILE")" in
      test_*.py|*_test.py) run_check "Pytest 单文件" python -m pytest -q "$TARGET_FILE" ;;
      *)
        paired="$(dirname "$TARGET_FILE")/test_$(basename "$TARGET_FILE")"
        [ -f "$paired" ] && run_check "Pytest 关联单测" python -m pytest -q "$paired"
        ;;
    esac
  else
    echo "  ℹ️  未安装 pytest，跳过 Python 测试"
  fi
fi

# ------------------------------------------------------------------------ Go --
if [ -f go.mod ] && command -v go >/dev/null 2>&1; then
  PKG_DIR="./$(dirname "$TARGET_FILE")"
  run_check "Go vet ($PKG_DIR)"  go vet "$PKG_DIR"
  run_check "Go test ($PKG_DIR)" go test "$PKG_DIR"
fi
fi # --quick 跳过自动工具探测

# ------------------------------------------------------- 自定义检查（可选） --
[ -f harness/verify.conf ] && . harness/verify.conf 2>/dev/null || true
if [ "$QUICK" -eq 1 ]; then
  if [ -n "${QUICK_CHECK:-}" ]; then
    run_check "快速检查 (harness/verify.conf)" bash -c "$QUICK_CHECK"
  fi
elif [ -n "${CUSTOM_CHECK:-}" ]; then
  run_check "自定义检查 (harness/verify.conf)" bash -c "$CUSTOM_CHECK"
fi

END_TIME=$(date +%s)
DUR=$((END_TIME - START_TIME))

if [ "$CHECKS" -eq 0 ]; then
  echo ""
  echo "❌ 未执行任何真实检查 —— 本次视为【未验证】（未验证 ≠ 通过）"
  echo "   接入方式（任一）："
  if [ "$QUICK" -eq 1 ]; then
    echo "   在 harness/verify.conf 配置 QUICK_CHECK（可用 \$TARGET_FILE）"
  else
    echo "   安装项目工具链，或在 harness/verify.conf 配置 CUSTOM_CHECK（可用 \$TARGET_FILE）"
  fi
  FAIL=1
fi

RESULT=PASS; [ "$FAIL" -ne 0 ] && RESULT=FAIL

if [ "$QUICK" -eq 1 ]; then
  if [ "$RESULT" = FAIL ]; then tail -n 20 "$LOG" | redact | sed 's/^/   /'; fi
  rm -f "$LOG"
  echo "快速检查：$RESULT（$CHECKS 项，${DUR}s）；不生成 G4 验证摘要"
  [ "$RESULT" = PASS ]
  exit $?
fi

if [ "$FAIL" -ne 0 ]; then
  echo ""
  echo "   失败摘要（日志末尾 20 行，已脱敏）："
  tail -n 20 "$LOG" | redact | sed 's/^/   /'
fi

# --- 成本包络：同一目标连续失败计数（触顶=黄卡，必须停下等人，不硬闯） ---
if [ -n "$SPEC_DIR" ]; then
  ATT="$SPEC_DIR/.attempts"
  if [ "$RESULT" = FAIL ]; then
    n=0
    [ -f "$ATT" ] && n=$(tr -dc '0-9' <"$ATT" 2>/dev/null | head -c 4)
    [ -n "$n" ] || n=0
    n=$((n + 1))
    printf '%s\n' "$n" >"$ATT"
    if [ "$n" -ge "$VERIFY_MAX_ATTEMPTS" ]; then
      echo ""
      echo "🟡 [黄卡] 同一目标已连续失败 $n 次（上限 ${VERIFY_MAX_ATTEMPTS}）：停止第 $((n + 1)) 次硬闯。"
      echo "   请把 WIP 区更新为「已尝试方案 + 卡点 + 下一个疑点」后向人说明；"
      echo "   若判断是方向错误：回退到最近一次通过验证的提交，并同步 ai-gate.sh reset 相关门。"
    fi
  else
    rm -f "$ATT"
  fi
fi

if [ -n "$REPORT_DIR" ]; then
  mkdir -p "$REPORT_DIR"
  OUT="$REPORT_DIR/verify-$(date +%Y%m%d-%H%M%S)-$$.log"
  {
    echo "# verify: ai-verify.sh"
    echo "# target: $TARGET_FILE"
    echo "# result: $RESULT"
    echo "# checks: $CHECKS  failed: $FAIL  duration: ${DUR}s"
    redact <"$LOG"
  } >"$OUT"
  echo "📄 验证报告: $OUT"
  STATE_ID=$(bash scripts/ai-state-id.sh --spec "$SPEC_NAME" "$TARGET_FILE") || { rm -f "$LOG"; exit 1; }
  SUMMARY="$SPEC_DIR/verification.md"
  {
    echo "# 增量验证摘要（随项目文档和 Git 交接）"
    echo ""
    echo "- spec: $SPEC_NAME"
    echo "- target: $TARGET_FILE"
    echo "- result: $RESULT"
    echo "- checks: $CHECKS"
    echo "- state: $STATE_ID"
    echo "- command: bash scripts/ai-verify.sh --spec $SPEC_NAME $TARGET_FILE"
    echo "- verified_at_utc: $(date -u +%Y-%m-%dT%H:%M:%SZ)"
    echo ""
    echo "详细输出仅在本地 reports/；代码内容或 Git 暂存状态变化后重新验证，同一索引内容提交后仍有效。"
  } >"$SUMMARY"
  echo "📝 可交接摘要: $SUMMARY"
else
  echo "ℹ️  未关联活跃 Spec，本次验证不生成接力摘要"
fi
rm -f "$LOG"

if [ "$DUR" -gt "$VERIFY_MAX_SECONDS" ]; then
  echo "⚠️  超出预算 ${VERIFY_MAX_SECONDS}s（实际 ${DUR}s）：验证正在变慢，检查是否误跑了全量。"
fi

if [ "$RESULT" = PASS ]; then
  echo "✅ 增量验证通过（$CHECKS 项检查，${DUR}s）"
  exit 0
fi
echo "❌ 增量验证失败（$CHECKS 项检查，${DUR}s）"
exit 1
