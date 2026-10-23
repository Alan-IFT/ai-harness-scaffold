#!/usr/bin/env bash
# 当前代码状态的便携指纹。无精确 Spec 清单时保守使用全仓算法。
# 流程记录不参与指纹；索引内容提交后保持稳定。
set -uo pipefail

spec=""
if [ "${1:-}" = "--spec" ]; then spec="${2:-}"; shift 2; fi
target="${1:-}"
[ -f "$target" ] || { echo "目标文件不存在：$target" >&2; exit 1; }

hash_stream() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 | awk '{print $1}'
  else cksum | awk '{print $1 "-" $2}'; fi
}
hash_file() { hash_stream < "$1"; }

# 只接受 design.md §4 中逐条反引号包围的精确文件路径。
# 旧 Spec、路径简写或目录路径均回退全仓，避免把遗漏误判为 PASS。
manifest() {
  local design="$1"
  [ -f "$design" ] || return 1
  awk '
    /^## 4[. ]/ { in_scope=1; next }
    /^## / { if (in_scope) exit }
    in_scope && /^[[:space:]]*-[[:space:]]*`/ {
      ticks=$0; n=gsub(/`/, "", ticks)
      if (n != 2) { print "__INVALID_MANIFEST_ENTRY__*"; next }
      p=$0; sub(/^[^`]*`/, "", p); sub(/`.*/, "", p); print p
    }
  ' "$design"
}
scope_confirmed() {
  awk '
    /^## 4[. ]/ { inside=1; next }
    /^## / { if (inside) exit }
    inside && /^[[:space:]]*-[[:space:]]*指纹范围确认(：|:)/ && /已核对验证命令及其脚本、配置、测试依赖/ { found=1 }
    END { exit !found }
  ' "$1"
}
valid_path() {
  case "$1" in
    ''|/*|./*|../*|*/../*|*//*|*'*'*|*'?'*|*'['*|*']'*|*':'*|*\\*|*/) return 1 ;;
  esac
  [ -f "$1" ]
}
in_list() {
  local needle="$1" item
  shift
  for item in "$@"; do [ "$needle" = "$item" ] && return 0; done
  return 1
}
spec_dir() {
  local name="$1" d
  case "$name" in ''|.|..|*[!A-Za-z0-9._-]*) return 1 ;; esac
  d="docs/specs/active/$name"
  [ -d "$d" ] && { printf '%s' "$d"; return 0; }
  find docs/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$name" 2>/dev/null | head -n 1
}
load_scope() {
  local design="$1" path
  SCOPE=()
  while IFS= read -r path; do
    valid_path "$path" || return 1
    SCOPE+=("$path")
  done < <(manifest "$design")
  [ "${#SCOPE[@]}" -gt 0 ]
}
# 未归属的工作区改动使 scoped 模式退出；归属依据是其他活跃 Spec 的清单。
claimed_elsewhere() {
  local path="$1" d own found invalid
  for d in docs/specs/active/*/; do
    [ -d "$d" ] || continue
    [ "${d%/}" = "$scope_dir" ] && continue
    grep -qE '^g3[[:space:]]' "${d}.gates" 2>/dev/null || continue
    found=0; invalid=0
    while IFS= read -r own; do
      valid_path "$own" || invalid=1
      [ "$path" = "$own" ] && found=1
    done < <(manifest "${d}design.md")
    [ "$found" -eq 1 ] && [ "$invalid" -eq 0 ] && return 0
  done
  return 1
}

scope_dir=""
SCOPED=0
SCOPE=()
if [ -n "$spec" ] && git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  scope_dir=$(spec_dir "$spec")
  base=""
  [ -n "$scope_dir" ] && base=$(awk -F'\t' '$1=="g3" { b=$4 } END { print b }' "$scope_dir/.gates" 2>/dev/null)
  if [ -n "$scope_dir" ] && [ -n "$base" ] && git rev-parse --verify -q "$base^{commit}" >/dev/null \
    && scope_confirmed "$scope_dir/design.md" \
    && load_scope "$scope_dir/design.md" && in_list "$target" "${SCOPE[@]}"; then
    # 验证配置与验证器始终是直接依赖，不能被设计清单遗漏。
    for dep in harness/verify.conf harness/redlines.conf scripts/ai-config.sh scripts/ai-verify.sh scripts/ai-state-id.sh scripts/ai-gate.sh \
      package.json package-lock.json pnpm-lock.yaml yarn.lock bun.lock bun.lockb pyproject.toml requirements.txt poetry.lock uv.lock go.mod go.sum; do
      [ -f "$dep" ] && SCOPE+=("$dep")
    done
    SCOPED=1
    while IFS= read -r -d '' path; do
      case "$path" in docs/specs/*|docs/metrics.md) continue ;; esac
      if ! in_list "$path" "${SCOPE[@]}" && ! claimed_elsewhere "$path"; then
        SCOPED=0
        break
      fi
    done < <(
      git diff --name-only -z "$base" HEAD
      git diff --name-only -z
      git diff --cached --name-only -z
      git ls-files --others --exclude-standard -z
    )
  fi
fi

{
  if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    if [ "$SCOPED" -eq 1 ]; then
      printf 'scoped:%s\\0' "$spec"
      printf 'path:%s\\0' "${SCOPE[@]}"
      git ls-files --stage -z -- "${SCOPE[@]}"
      git diff --binary -- "${SCOPE[@]}"
      while IFS= read -r -d '' path; do
        [ -f "$path" ] || continue
        printf 'untracked:%s\\0' "$path"
        hash_file "$path"
      done < <(git ls-files --others --exclude-standard -z -- "${SCOPE[@]}")
    else
      printf 'global\\0'
      git ls-files --stage -z -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md'
      git diff --binary -- . ':(exclude)docs/specs/**' ':(exclude)docs/metrics.md'
      while IFS= read -r -d '' path; do
        case "$path" in docs/specs/*|docs/metrics.md) continue ;; esac
        [ -f "$path" ] || continue
        printf 'untracked:%s\\0' "$path"
        hash_file "$path"
      done < <(git ls-files --others --exclude-standard -z)
    fi
  else
    printf 'no-git\\n'
  fi
  printf 'target:%s\\0' "$target"
  hash_file "$target"
} | hash_stream
