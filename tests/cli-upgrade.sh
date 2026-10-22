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

hash_one() {
  local output
  if command -v sha256sum >/dev/null 2>&1; then output=$(sha256sum "$1") || return 1
  else output=$(shasum -a 256 "$1") || return 1; fi
  printf '%s\n' "${output%% *}"
}
snapshot() {
  find "$1" -type f | LC_ALL=C sort | while IFS= read -r file; do
    hash=$(hash_one "$file") || exit 1
    printf '%s %s\n' "$hash" "$file"
  done
}

bash "$CLI" init "$TARGET" --no-git >/dev/null
grep -q $'\tscripts/ai-task-pool.sh$' "$TARGET/.ai-harness/manifest.tsv"
grep -q '^version=1.1.0$' "$TARGET/.ai-harness/version"
sed -i 's/^version=1.1.0$/version=1.0.0/' "$TARGET/.ai-harness/version"
printf '\n# local customization\n' >> "$TARGET/AGENTS.md"
printf '\n# template update\n' >> "$TMP/source/template/scripts/ai-task-pool.sh"
printf '#!/usr/bin/env bash\n' > "$TMP/source/template/scripts/ai-future.sh"
printf 'project state\n' > "$TARGET/docs/task-pool/T-000002.md"
cp "$TARGET/AGENTS.md" "$TMP/agents-before"
snapshot "$TARGET" > "$TMP/before"

if bash "$CLI" upgrade "$TARGET" --dry-run > "$TMP/dry-output" 2>&1; then
  echo 'expected dry-run conflict' >&2; exit 1
fi
snapshot "$TARGET" > "$TMP/after"
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
test -f "$TARGET/.ai-harness/suggested/AGENTS.md.upgrade-$(hash_one "$TMP/source/template/AGENTS.md" | cut -c1-12)"

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
mkdir -p "$TMP/real-parent"
cp -R "$TARGET" "$TMP/real-parent/project"
ln -s "$TMP/real-parent" "$TMP/parent-link"
if [ -L "$TMP/parent-link" ]; then
  if bash "$CLI" upgrade "$TMP/parent-link/project" > "$TMP/parent-link-output" 2>&1; then
    echo 'expected parent symlink rejection' >&2; exit 1
  fi
  grep -q '目标路径含符号链接' "$TMP/parent-link-output"
  if command -v cygpath >/dev/null 2>&1; then
    parent_win=$(cygpath -m "$TMP/parent-link/project")
    if bash "$CLI" upgrade "$parent_win" > "$TMP/parent-win-output" 2>&1; then
      echo 'expected Windows parent symlink rejection' >&2; exit 1
    fi
    grep -q '目标路径含符号链接' "$TMP/parent-win-output"
  fi
fi
ln -s "$TARGET" "$TMP/project-link"
if [ -L "$TMP/project-link" ]; then
  if bash "$CLI" upgrade "$TMP/project-link/" > "$TMP/trailing-link-output" 2>&1; then
    echo 'expected trailing slash symlink rejection' >&2; exit 1
  fi
  grep -q '目标路径含符号链接' "$TMP/trailing-link-output"
fi
if command -v cygpath >/dev/null 2>&1; then
  for windows_target in "$(cygpath -m "$TARGET")" "$(cygpath -w "$TARGET")"; do
    if bash "$CLI" upgrade "$windows_target" --dry-run > "$TMP/windows-output" 2>&1; then
      echo 'expected existing customization conflict' >&2; exit 1
    fi
    grep -q '只读预演' "$TMP/windows-output"
  done
fi

# A partial source listing or failed digest must stop before changing the target.
mkdir -p "$TMP/fake-find" "$TMP/fake-hash"
printf '#!/usr/bin/env bash\nprintf "%%s\\n" "$AI_HARNESS_TEST_TEMPLATE_FILE"\nexit 1\n' > "$TMP/fake-find/find"
printf '#!/usr/bin/env bash\nexit 1\n' > "$TMP/fake-hash/sha256sum"
chmod +x "$TMP/fake-find/find" "$TMP/fake-hash/sha256sum"
snapshot "$TARGET" > "$TMP/failure-before"
if AI_HARNESS_TEST_TEMPLATE_FILE="$TMP/source/template/AGENTS.md" PATH="$TMP/fake-find:$PATH" bash "$CLI" upgrade "$TARGET" > "$TMP/find-failure-output" 2>&1; then
  echo 'expected template enumeration failure' >&2; exit 1
fi
grep -q '无法完整枚举模板文件' "$TMP/find-failure-output"
if PATH="$TMP/fake-hash:$PATH" bash "$CLI" upgrade "$TARGET" > "$TMP/hash-failure-output" 2>&1; then
  echo 'expected digest failure' >&2; exit 1
fi
grep -q '无法计算模板哈希' "$TMP/hash-failure-output"
snapshot "$TARGET" > "$TMP/failure-after"
cmp "$TMP/failure-before" "$TMP/failure-after"
echo 'cli-upgrade: PASS'
