#!/usr/bin/env bash
# 自用入口：测试 template/ 原始机制。
exec bash "$(dirname "$0")/../template/scripts/harness-selftest.sh" "$@"
