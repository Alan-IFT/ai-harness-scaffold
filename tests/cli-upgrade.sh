#!/usr/bin/env bash
# CLI upgrade regression: safe managed updates, customization, legacy installs and dry-run.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT
mkdir -p "$TMP/source"
cp -R "$ROOT/bin" "$ROOT/template" "$TMP/source/"
CLI="$TMP/source/bin/ai-harness"
TARGET="$TMP/project"

bash "$CLI" init "$TARGET" --no-git >/dev/null
grep -q $'\tscripts/ai-task-pool.sh$' "$TARGET/.ai-harness/manifest.tsv"
grep -q '^version=1.1.0$' "$TARGET/.ai-harness/version"
sed -i 's/^version=1.1.0$/version=1.0.0/' "$TARGET/.ai-harness/version"
printf '\n# local customization\n' >> "$TARGET/AGENTS.md"
printf '\n# template update\n' >> "$TMP/source/template/scripts/ai-task-pool.sh"
printf '#!/usr/bin/env bash\n' > "$TMP/source/template/scripts/ai-future.sh"
printf 'project state\n' > "$TARGET/docs/task-pool/T-000002.md"
cp "$TARGET/AGENTS.md" "$TMP/agents-before"
find "$TARGET" -type f -print0 | sort -z | xargs -0 sha256sum > "$TMP/before"

if bash "$CLI" upgrade "$TARGET" --dry-run > "$TMP/dry-output" 2>&1; then
  echo 'expected dry-run conflict' >&2; exit 1
fi
find "$TARGET" -type f -print0 | sort -z | xargs -0 sha256sum > "$TMP/after"
cmp "$TMP/before" "$TMP/after"
grep -q '只读预演' "$TMP/dry-output"

if bash "$CLI" upgrade "$TARGET" > "$TMP/upgrade-output" 2>&1; then
  echo 'expected customization conflict' >&2; exit 1
fi
cmp "$TARGET/AGENTS.md" "$TMP/agents-before"
grep -q '# template update' "$TARGET/scripts/ai-task-pool.sh"
test -f "$TARGET/scripts/ai-future.sh"
test -f "$TARGET/docs/task-pool/T-000002.md"
grep -q '^version=1.0.0$' "$TARGET/.ai-harness/version"
test -f "$TARGET/.ai-harness/suggested/AGENTS.md.upgrade-$(sha256sum "$TMP/source/template/AGENTS.md" | cut -c1-12)"

# The maintainer merges/reviews the custom file, then records its new baseline.
bash "$CLI" upgrade "$TARGET" --accept-custom AGENTS.md > "$TMP/accepted-output"
grep -q '已确认合并的定制文件' "$TMP/accepted-output"
grep -q '^version=1.1.0$' "$TARGET/.ai-harness/version"
bash "$CLI" upgrade "$TARGET" > "$TMP/repeat-output"
cmp "$TARGET/AGENTS.md" "$TMP/agents-before"
grep -q '0 个冲突' "$TMP/repeat-output"
printf '\n# changed upstream again\n' >> "$TMP/source/template/AGENTS.md"
if bash "$CLI" upgrade "$TARGET" > "$TMP/new-conflict-output" 2>&1; then
  echo 'expected a new conflict after upstream changes' >&2; exit 1
fi

# Legacy installs have no baseline: copy missing files, preserve all differing files.
LEGACY="$TMP/legacy"
bash "$CLI" init "$LEGACY" --no-git >/dev/null
rm "$LEGACY/.ai-harness/manifest.tsv" "$LEGACY/scripts/ai-future.sh"
printf '\n# legacy edit\n' >> "$LEGACY/AGENTS.md"
if bash "$CLI" upgrade "$LEGACY" > "$TMP/legacy-output" 2>&1; then
  echo 'expected legacy conflict' >&2; exit 1
fi
test -f "$LEGACY/scripts/ai-future.sh"
grep -q '# legacy edit' "$LEGACY/AGENTS.md"

# A symlink in a managed path must abort before writing anything.
LINKED="$TMP/linked"
bash "$CLI" init "$LINKED" --no-git >/dev/null
mv "$LINKED/scripts" "$LINKED/scripts-original"
ln -s "$LINKED/scripts-original" "$LINKED/scripts"
if [ -L "$LINKED/scripts" ]; then
  if bash "$CLI" upgrade "$LINKED" > "$TMP/link-output" 2>&1; then
    echo 'expected symlink rejection' >&2; exit 1
  fi
  grep -q '升级路径不安全' "$TMP/link-output"
fi
echo 'cli-upgrade: PASS'
