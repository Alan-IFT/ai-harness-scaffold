#!/usr/bin/env bash
# 当前代码状态的便携指纹；Spec 与交付度量属于流程记录，不参与指纹。
# Git 仓库：索引内容 + 未暂存改动 + 未跟踪文件内容；无 Git：仅目标文件。
# 同一代码状态从「已暂存」到「已提交」应保持指纹不变；暂存新改动后需重新验证。
set -uo pipefail

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
    git ls-files --stage -z -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md'
    git diff --binary -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md'
    while IFS= read -r -d '' path; do
      case "$path" in docs/specs/*|docs/metrics.md) continue ;; esac
      [ -f "$path" ] || continue
      printf 'untracked:%s\0' "$path"
      hash_file "$path"
    done < <(git ls-files --others --exclude-standard -z)
  else
    printf 'no-git\n'
  fi
  printf 'target:%s\0' "$target"
  hash_file "$target"
} | hash_stream
