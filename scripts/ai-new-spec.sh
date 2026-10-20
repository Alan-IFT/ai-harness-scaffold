#!/usr/bin/env bash
# ==============================================================================
# ai-new-spec.sh — 从模板生成一整套新功能 Spec（requirements/design/tasks + reports）
# 用法：bash scripts/ai-new-spec.sh <feat-name>
# ==============================================================================
set -u

FEAT_NAME="${1:-}"
if [ -z "$FEAT_NAME" ]; then
  echo "❌ 错误: 请提供功能名称（例如: feat-user-auth）"
  echo "👉 用法: bash scripts/ai-new-spec.sh <feat-name>"
  exit 1
fi
case "$FEAT_NAME" in
  *[!A-Za-z0-9._-]*)
    echo "❌ 错误: 功能名只允许字母/数字/点/下划线/连字符: $FEAT_NAME"
    exit 1
    ;;
esac

TARGET_DIR="docs/specs/active/$FEAT_NAME"
if [ -d "$TARGET_DIR" ]; then
  echo "⚠️  目录已存在，未覆盖: $TARGET_DIR"
  exit 1
fi
if [ ! -d docs/specs/_templates ]; then
  echo "❌ 错误: 找不到 docs/specs/_templates/（请在仓库根目录运行）"
  exit 1
fi

mkdir -p "$TARGET_DIR/reports"
TODAY=$(date +%Y-%m-%d)

for file in requirements.md design.md tasks.md; do
  src="docs/specs/_templates/$file"
  if [ ! -f "$src" ]; then
    echo "❌ 错误: 模板缺失: $src"
    exit 1
  fi
  sed -e "s/{{FEATURE_NAME}}/$FEAT_NAME/g" \
      -e "s/{{DATE}}/$TODAY/g" \
      "$src" >"$TARGET_DIR/$file"
done

echo "✅ 已创建: $TARGET_DIR"
echo "   - $TARGET_DIR/requirements.md"
echo "   - $TARGET_DIR/design.md"
echo "   - $TARGET_DIR/tasks.md"
echo "   - $TARGET_DIR/reports/        (由 ai-verify.sh 自动写入验证报告)"
echo ""
echo "下一步（见 @.agents/skills/new-spec.md）："
echo "1. 访谈式澄清需求后填 requirements.md 的 §0 四项必答 + AC 表"
echo "2. 写 design.md：依赖序实现、垂直切片、检查点、文件清单、对抗自审"
echo "3. 写 tasks.md：3~6 个原子任务 + 上下文清单 + WIP 区"
echo "4. bash scripts/ai-gate.sh check $FEAT_NAME g1  (然后 g2 / g3)；过门后停下等人工评审"
