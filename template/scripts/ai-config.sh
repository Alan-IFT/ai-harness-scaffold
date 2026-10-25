#!/usr/bin/env bash
# 供脚手架脚本 source；当前项目的 harness/redlines.conf 是阈值唯一来源。

ai_config_load() {
  local config="${1:-}" key value normalized
  shift || return 1
  if [ ! -f "$config" ]; then
    printf '❌ 缺少配置 %s；请从脚手架模板补齐项目配置，勿使用隐含默认值\n' "$config" >&2
    return 1
  fi
  # 不继承宿主环境或先前命令留下的同名值。
  for key in "$@"; do unset "$key"; done
  # 配置由当前项目维护者管理；仅加载项目内的明确文件。
  . "$config" || { printf '❌ 无法读取配置 %s\n' "$config" >&2; return 1; }
  for key in "$@"; do
    value="${!key-}"
    case "$value" in
      ''|*[!0-9]*) printf '❌ %s 缺少正整数配置键 %s\n' "$config" "$key" >&2; return 1 ;;
    esac
    normalized="${value#"${value%%[!0]*}"}"
    if [ -z "$normalized" ]; then
      printf '❌ %s 的 %s 必须大于 0\n' "$config" "$key" >&2
      return 1
    fi
    # Bash/test 的整数范围依平台变化；限定到跨平台安全的 32 位正整数。
    if [ "${#normalized}" -gt 10 ] || { [ "${#normalized}" -eq 10 ] && [[ "$normalized" > 2147483647 ]]; }; then
      printf '❌ %s 的 %s 超出可安全比较的整数范围\n' "$config" "$key" >&2
      return 1
    fi
    printf -v "$key" '%s' "$normalized"
  done
}

# 流程记录在 process/；旧版 docs/ 下的布局须先由 ai-harness upgrade 迁移，避免两套状态分叉。
# 只认 harness 创建的标记，项目自有的 docs/specs/*.md 不算旧布局。
ai_require_process_layout() {
  [ -d docs/specs/active ] || [ -d docs/specs/archive ] || [ -d docs/specs/_templates ] \
    || [ -f docs/task-pool/README.md ] || return 0
  if [ -e process ] || [ -L process ]; then
    printf '❌ process/ 与旧布局（docs/specs 或 docs/task-pool）并存；先人工核对 process/ 内容，再把旧目录合并进 process/ 或删除其中一份\n' >&2
  else
    printf '❌ 检测到旧布局（docs/specs 或 docs/task-pool）；请运行 ai-harness upgrade 迁移到 process/\n' >&2
  fi
  return 1
}
