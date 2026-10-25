#!/usr/bin/env bash
# ==============================================================================
# ai-new-spec.sh — 从模板生成一整套新功能 Spec
#   requirements.md / design.md / tasks.md / acceptance.md / verification.md + reports/
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
  .|..|*[!A-Za-z0-9._-]*)
    echo "❌ 错误: 功能名只允许字母/数字/点/下划线/连字符: $FEAT_NAME"
    exit 1
    ;;
esac

. "$(dirname "${BASH_SOURCE[0]}")/ai-config.sh" || exit 1

TARGET_DIR="process/specs/active/$FEAT_NAME"
if [ -d "$TARGET_DIR" ]; then
  echo "⚠️  目录已存在，未覆盖: $TARGET_DIR"
  exit 1
fi
ARCHIVED_DIR=$(find process/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$FEAT_NAME" -print -quit 2>/dev/null)
if [ -n "$ARCHIVED_DIR" ]; then
  echo "❌ 错误: Spec ID 已归档，不能重用: $ARCHIVED_DIR"
  exit 1
fi
TEMPLATE_DIR="${AI_HARNESS_TEMPLATE_DIR:-process/specs/_templates}"
if [ ! -d "$TEMPLATE_DIR" ]; then
  echo "❌ 错误: 找不到 Spec 模板目录: $TEMPLATE_DIR（请在仓库根目录运行）"
  exit 1
fi

for file in requirements.md design.md tasks.md acceptance.md verification.md; do
  src="$TEMPLATE_DIR/$file"
  if [ ! -f "$src" ]; then
    echo "❌ 错误: 模板缺失: $src"
    exit 1
  fi
done

if [ -n "${AI_HARNESS_SOURCE_TASK:-}" ]; then
  [[ "$AI_HARNESS_SOURCE_TASK" =~ ^process/task-pool/T-[0-9]{6}\.md$ ]] && [ -f "$AI_HARNESS_SOURCE_TASK" ] || {
    echo "❌ 错误: 任务来源文件无效: $AI_HARNESS_SOURCE_TASK"
    exit 1
  }
fi

mkdir -p process/specs/active
BUILD_DIR=$(mktemp -d "process/specs/active/.$FEAT_NAME.tmp.XXXXXX") || exit 1
cleanup_build() {
  [ -n "${BUILD_DIR:-}" ] || return 0
  for file in requirements.md design.md tasks.md acceptance.md verification.md requirements.md.tmp; do
    rm -f -- "$BUILD_DIR/$file"
  done
  rmdir "$BUILD_DIR/reports" "$BUILD_DIR" 2>/dev/null || true
}
trap cleanup_build EXIT
mkdir "$BUILD_DIR/reports" || exit 1
TODAY=$(date +%Y-%m-%d)

for file in requirements.md design.md tasks.md acceptance.md verification.md; do
  src="$TEMPLATE_DIR/$file"
  sed -e "s/{{FEATURE_NAME}}/$FEAT_NAME/g" \
      -e "s/{{DATE}}/$TODAY/g" \
      "$src" >"$BUILD_DIR/$file" || exit 1
done

if [ -n "${AI_HARNESS_SOURCE_TASK:-}" ]; then
  awk -v source="$AI_HARNESS_SOURCE_TASK" '
    /^- \*\*需求来源\*\*:/ { print "- **需求来源**: `" source "`（原始需求与更新）"; found=1; next }
    { print }
    END { if (!found) exit 1 }
  ' "$BUILD_DIR/requirements.md" >"$BUILD_DIR/requirements.md.tmp" || exit 1
  mv "$BUILD_DIR/requirements.md.tmp" "$BUILD_DIR/requirements.md" || exit 1
fi

[ ! -e "$TARGET_DIR" ] || { echo "⚠️  目录已存在，未覆盖: $TARGET_DIR"; exit 1; }
mv "$BUILD_DIR" "$TARGET_DIR" || exit 1
BUILD_DIR=""
trap - EXIT

echo "✅ 已创建: $TARGET_DIR"
echo "   - $TARGET_DIR/requirements.md  (含需求象限与分级依据)"
echo "   - $TARGET_DIR/design.md        (含 §0 模块关联)"
echo "   - $TARGET_DIR/tasks.md         (含 §1 上下文清单)"
echo "   - $TARGET_DIR/acceptance.md    (G6 核验证据与风险决定留痕)"
echo "   - $TARGET_DIR/verification.md  (跨 IDE 可交接的验证摘要)"
echo "   - $TARGET_DIR/reports/         (由 ai-verify.sh 自动写入验证报告)"
echo ""
echo "下一步（见 .agents/skills/new-spec.md）："
echo "1. 保留原始问题；访谈式澄清 §0 四项必答、需求象限与 AC 表；④转人工"
echo "2. 写 design.md：先在 §0 选对模块（必须已在 00-INDEX 登记），再写依赖序/切片/检查点/文件清单/对抗自审"
echo "3. 写 tasks.md：3~6 个原子任务 + 上下文清单 + WIP 区"
echo "4. bash scripts/ai-gate.sh check $FEAT_NAME g1；①~③继续 g2/g3，②③编码前记录人的前置决策"
