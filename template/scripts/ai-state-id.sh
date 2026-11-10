#!/usr/bin/env bash
# 当前代码状态的便携指纹：全仓计算，只排除流程记录。
# 流程记录统一放在 process/ 下，不参与指纹；索引内容提交后保持稳定。
set -uo pipefail

git rev-parse --is-inside-work-tree >/dev/null || { echo "状态指纹需要 Git 仓库：当前目录不在 Git 工作区，或 Git 读不了它（原因见上一行）；新项目先运行 git init" >&2; exit 1; }

target="${1:-}"
[ -f "$target" ] || { echo "目标文件不存在：$target" >&2; exit 1; }

hash_stream() { sha256sum | awk '{print $1}'; }
hash_file() { hash_stream < "$1"; }

{
  printf 'global\\0'
  git ls-files --stage -z -- . ':(exclude)process/**'
  git diff --binary -- . ':(exclude)process/**'
  while IFS= read -r -d '' path; do
    case "$path" in process/*) continue ;; esac
    [ -f "$path" ] || continue
    printf 'untracked:%s\\0' "$path"
    hash_file "$path"
  done < <(git ls-files --others --exclude-standard -z)
  printf 'target:%s\\0' "$target"
  hash_file "$target"
} | hash_stream
