#!/usr/bin/env bash
# ai-new-spec.sh — 从模板新建 Spec（requirements.md、tasks.md、reports/）
# 用法：bash scripts/ai-new-spec.sh <feat>
set -u

FEAT="${1:-}"
case "$FEAT" in
  ''|.|..|*[!A-Za-z0-9._-]*) echo "❌ 功能名只允许字母/数字/点/下划线/连字符（例如 feat-user-auth）: $FEAT" >&2; exit 1 ;;
esac
DIR="process/specs/active/$FEAT"
TPL="${AI_HARNESS_TEMPLATE_DIR:-process/specs/_templates}"
[ ! -e "$DIR" ] || { echo "⚠️  目录已存在，未覆盖: $DIR" >&2; exit 1; }
if find process/specs/archive -mindepth 2 -maxdepth 2 -type d -name "$FEAT" 2>/dev/null | grep -q .; then
  echo "❌ Spec ID 已归档，不能重用: $FEAT" >&2; exit 1
fi
for f in requirements.md tasks.md; do
  [ -f "$TPL/$f" ] || { echo "❌ 模板缺失: $TPL/$f" >&2; exit 1; }
done

mkdir -p "$DIR/reports" || exit 1
for f in requirements.md tasks.md; do
  sed -e "s/{{FEATURE_NAME}}/$FEAT/g" -e "s/{{DATE}}/$(date +%Y-%m-%d)/g" "$TPL/$f" >"$DIR/$f" \
    || { rm -rf "$DIR"; exit 1; }
done
if [ -n "${AI_HARNESS_SOURCE_TASK:-}" ]; then
  sed -i "s#^- \*\*需求来源\*\*:.*#- **需求来源**: \`$AI_HARNESS_SOURCE_TASK\`（原始需求与更新）#" "$DIR/requirements.md"
  grep -qF "$AI_HARNESS_SOURCE_TASK" "$DIR/requirements.md" \
    || { rm -rf "$DIR"; echo "❌ requirements.md 模板缺少「需求来源」行" >&2; exit 1; }
fi
echo "✅ 已创建 $DIR：写好 requirements.md 与 tasks.md 后运行 bash scripts/ai-gate.sh pass $FEAT g1"
