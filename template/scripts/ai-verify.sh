#!/usr/bin/env bash
# ==============================================================================
# ai-verify.sh — 增量极速验证（本地可信的最低门槛）
# 设计原则：未验证 ≠ 通过。没有任何真实检查被执行时，本脚本必须失败。
#
# 用法：bash scripts/ai-verify.sh <file_path>
# 自动探测（工具已安装才跑）：ESLint / tsc / Vitest；ruff / pytest；go vet / go test
# 自定义：harness/verify.conf 里写  CUSTOM_CHECK="<命令，可用 $TARGET_FILE>"
# ==============================================================================
set -u

TARGET_FILE="${1:-}"
if [ -z "$TARGET_FILE" ]; then
  echo "❌ 错误: 请指定要验证的文件路径！"
  echo "👉 用法: bash scripts/ai-verify.sh <file_path>"
  exit 1
fi
if [ ! -e "$TARGET_FILE" ]; then
  echo "❌ 错误: 文件不存在: $TARGET_FILE"
  exit 1
fi
export TARGET_FILE

# --- 红线预算（harness/redlines.conf 是唯一阈值来源）---
VERIFY_MAX_SECONDS=120
[ -f harness/redlines.conf ] && . harness/redlines.conf 2>/dev/null || true
case "${VERIFY_MAX_SECONDS:-}" in ''|*[!0-9]*) VERIFY_MAX_SECONDS=120 ;; esac
VERIFY_MAX_ATTEMPTS=${VERIFY_MAX_ATTEMPTS:-3}
case "${VERIFY_MAX_ATTEMPTS:-}" in ''|*[!0-9]*) VERIFY_MAX_ATTEMPTS=3 ;; esac

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
      && run_check "Vitest 关联单测" node_modules/.bin/vitest related "$TARGET_FILE" --run --passWithNoTests
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

# ------------------------------------------------------- 自定义检查（可选） --
[ -f harness/verify.conf ] && . harness/verify.conf 2>/dev/null || true
if [ -n "${CUSTOM_CHECK:-}" ]; then
  run_check "自定义检查 (harness/verify.conf)" bash -c "$CUSTOM_CHECK"
fi

END_TIME=$(date +%s)
DUR=$((END_TIME - START_TIME))

if [ "$CHECKS" -eq 0 ]; then
  echo ""
  echo "❌ 未执行任何真实检查 —— 本次视为【未验证】（未验证 ≠ 通过）"
  echo "   接入方式（任一）："
  echo "   1) 装好项目工具链后重跑（自动探测 ESLint/tsc/Vitest、ruff/pytest、go vet/test）"
  echo "   2) 在 harness/verify.conf 写：CUSTOM_CHECK=\"<你的命令，可用 \$TARGET_FILE>\""
  rm -f "$LOG"
  exit 1
fi

RESULT=PASS; [ "$FAIL" -ne 0 ] && RESULT=FAIL

# --- 关联唯一活跃 spec：报告与失败计数都落在这里 ---
REPORT_DIR=""; SPEC_DIR=""
if [ -d docs/specs/active ]; then
  count=0; only=""
  while IFS= read -r d; do
    [ -n "$d" ] || continue
    count=$((count + 1)); only="$d"
  done < <(find docs/specs/active -mindepth 1 -maxdepth 1 -type d 2>/dev/null)
  if [ "$count" -eq 1 ] && [ -n "$only" ]; then SPEC_DIR="$only"; REPORT_DIR="$only/reports"; fi
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
  OUT="$REPORT_DIR/verify-$(date +%Y%m%d-%H%M%S).log"
  {
    echo "# verify: ai-verify.sh"
    echo "# target: $TARGET_FILE"
    echo "# result: $RESULT"
    echo "# checks: $CHECKS  failed: $FAIL  duration: ${DUR}s"
    redact <"$LOG"
  } >"$OUT"
  echo "📄 验证报告: $OUT"
else
  echo "ℹ️  未关联到唯一活跃 spec，报告未落盘（不影响本次结论）"
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
