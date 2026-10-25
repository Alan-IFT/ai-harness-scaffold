#!/usr/bin/env bash
# 当前代码状态的便携指纹：全仓计算，只排除流程记录。
# 流程记录（docs/specs/**、docs/metrics.md、docs/task-pool/**）不参与指纹；索引内容提交后保持稳定。
set -uo pipefail

# --spec 为兼容旧调用保留，不影响结果。
if [ "${1:-}" = "--spec" ]; then shift 2 2>/dev/null || shift; fi
target="${1:-}"
[ -f "$target" ] || { echo "目标文件不存在：$target" >&2; exit 1; }

hash_stream() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else cksum | awk '{print $1 "-" $2}'; fi
}
hash_file() { hash_stream < "$1"; }

{
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'global\\0'
    git ls-files --stage -z -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md' ':(exclude)docs/task-pool/**'
    git diff --binary -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md' ':(exclude)docs/task-pool/**'
    while IFS= read -r -d '' path; do
      case "$path" in docs/specs/*|docs/metrics.md|docs/task-pool/*) continue ;; esac
      [ -f "$path" ] || continue
      printf 'untracked:%s\\0' "$path"
      hash_file "$path"
    done < <(git ls-files --others --exclude-standard -z)
  else
    printf 'no-git\\n'
  fi
  printf 'target:%s\\0' "$target"
  hash_file "$target"
} | hash_stream
