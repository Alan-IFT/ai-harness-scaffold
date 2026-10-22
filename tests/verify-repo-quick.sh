#!/usr/bin/env bash
# 本仓库开发期短检查；不产生正式 G4 验证摘要。
set -euo pipefail

case "${TARGET_FILE:-}" in
  *.sh|bin/ai-harness)
    echo '== 目标文件语法 =='
    bash -n "$TARGET_FILE"
    ;;
  template/.agents/skills/*|template/AGENTS.md|README.md)
    echo '== 项目指南体积 =='
    bash scripts/ai-check-bloat.sh
    ;;
esac

echo '== 未暂存 diff =='
git diff --check
echo '== 已暂存 diff =='
git diff --cached --check
