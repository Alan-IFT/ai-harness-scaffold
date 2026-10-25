#!/usr/bin/env bash
# 当前代码状态的便携指纹：全仓计算，只排除流程记录。
# 流程记录统一放在 process/ 下，不参与指纹；索引内容提交后保持稳定。
set -uo pipefail

target="${1:-}"
[ -f "$target" ] || { echo "目标文件不存在：$target" >&2; exit 1; }

hash_stream() { sha256sum | awk '{print $1}'; }
hash_file() { hash_stream < "$1"; }

{
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'global\\0'
    git ls-files --stage -z -- . ':(exclude)process/**'
    git diff --binary -- . ':(exclude)process/**'
    while IFS= read -r -d '' path; do
      case "$path" in process/*) continue ;; esac
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
