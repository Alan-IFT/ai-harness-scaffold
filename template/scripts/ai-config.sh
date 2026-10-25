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
