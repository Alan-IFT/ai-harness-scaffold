#!/usr/bin/env bash
# 供脚手架脚本 source；当前项目的 harness/redlines.conf 是阈值唯一来源。

ai_config_load() {
  local config="${1:-}" key value
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
    [[ "$value" =~ ^[1-9][0-9]{0,8}$ ]] || { printf '❌ %s 的 %s 须为正整数\n' "$config" "$key" >&2; return 1; }
  done
}
