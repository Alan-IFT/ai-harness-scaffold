#!/usr/bin/env bash
# 自用入口：Spec 模板仍来自 template/，不复制第二份。
export AI_HARNESS_TEMPLATE_DIR="$(dirname "$0")/../template/process/specs/_templates"
exec bash "$(dirname "$0")/../template/scripts/ai-new-spec.sh" "$@"
