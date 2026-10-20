#!/usr/bin/env bash
# 自用入口：机制只维护在 template/scripts/。
exec bash "$(dirname "$0")/../template/scripts/ai-state-id.sh" "$@"
