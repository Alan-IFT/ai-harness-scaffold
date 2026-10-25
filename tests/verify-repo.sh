#!/usr/bin/env bash
# 本仓库的完整验证阶段；由 harness/verify.conf 调用，不分发到目标项目。
set -u

run_phase() {
  local name="$1" start=$SECONDS rc
  shift
  printf '== %s ==\n' "$name"
  "$@"
  rc=$?
  if [ "$rc" -eq 0 ]; then
    printf '== %s: PASS (%ss) ==\n' "$name" "$((SECONDS - start))"
  else
    printf '== %s: FAIL (%ss, exit %s) ==\n' "$name" "$((SECONDS - start))" "$rc" >&2
  fi
  return "$rc"
}

case "${TARGET_FILE:-}" in
  *.sh|bin/ai-harness) run_phase '目标文件语法' bash -n "$TARGET_FILE" || exit $? ;;
esac
# 便宜的错误先拒绝，避免带着空白错误跑数分钟自检。
run_phase '未暂存 diff' git diff --check || exit $?
run_phase '已暂存 diff' git diff --cached --check || exit $?
run_phase '模板自检' bash template/scripts/harness-selftest.sh || exit $?
run_phase 'CLI 回归' bash tests/cli-smoke.sh || exit $?
