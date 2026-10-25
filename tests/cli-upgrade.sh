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
grep -q '^version=2.0.0$' "$TARGET/.ai-harness/version"
sed -i 's/^version=2.0.0$/version=1.0.0/' "$TARGET/.ai-harness/version"
printf '\n# local customization\n' >> "$TARGET/AGENTS.md"
printf '\n# template update\n' >> "$TMP/source/template/scripts/ai-task-pool.sh"
printf '#!/usr/bin/env bash\n' > "$TMP/source/template/scripts/ai-future.sh"
printf 'project state\n' > "$TARGET/process/task-pool/T-000002.md"
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
test -f "$TARGET/process/task-pool/T-000002.md"
grep -q '^version=1.0.0$' "$TARGET/.ai-harness/version"
test -f "$TARGET/.ai-harness/suggested/AGENTS.md.upgrade-$(hash_one "$TMP/source/template/AGENTS.md" | cut -c1-12)"

# The maintainer merges/reviews the custom file, then records its new baseline.
bash "$CLI" upgrade "$TARGET" --accept-custom AGENTS.md > "$TMP/accepted-output"
grep -q '已确认合并的定制文件' "$TMP/accepted-output"
grep -q '^version=2.0.0$' "$TARGET/.ai-harness/version"
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

# Managed files removed from the template: delete untouched copies, keep and report edited or accepted ones.
RSRC="$TMP/retire-source"
mkdir -p "$RSRC"
cp -R "$ROOT/bin" "$ROOT/template" "$RSRC/"
RCLI="$RSRC/bin/ai-harness"
printf '#!/usr/bin/env bash\necho old\n' > "$RSRC/template/scripts/ai-old.sh"
for name in clean edited accepted dry legacy forged; do bash "$RCLI" init "$TMP/ret-$name" --no-git >/dev/null; done
printf '\n# local edit\n' >> "$TMP/ret-edited/scripts/ai-old.sh"
printf '\n# local edit\n' >> "$TMP/ret-accepted/scripts/ai-old.sh"
if bash "$RCLI" upgrade "$TMP/ret-accepted" > "$TMP/ret-accept-pre" 2>&1; then
  echo 'expected conflict before accepting customization' >&2; exit 1
fi
bash "$RCLI" upgrade "$TMP/ret-accepted" --accept-custom scripts/ai-old.sh > /dev/null
rm "$TMP/ret-legacy/.ai-harness/manifest.tsv"
mkdir -p "$TMP/ret-forged/src"
cp "$TMP/ret-forged/scripts/ai-old.sh" "$TMP/ret-forged/src/app.sh"
forged_hash=$(hash_one "$TMP/ret-forged/src/app.sh")
printf '%s\t%s\t%s\n' "$forged_hash" "$forged_hash" src/app.sh >> "$TMP/ret-forged/.ai-harness/manifest.tsv"
rm "$RSRC/template/scripts/ai-old.sh"

bash "$RCLI" upgrade "$TMP/ret-clean" > "$TMP/ret-clean-output"
test ! -e "$TMP/ret-clean/scripts/ai-old.sh"
grep -q -- '- scripts/ai-old.sh' "$TMP/ret-clean-output"
if grep -q $'\tscripts/ai-old.sh$' "$TMP/ret-clean/.ai-harness/manifest.tsv"; then echo 'retired file left in manifest' >&2; exit 1; fi

if bash "$RCLI" upgrade "$TMP/ret-edited" > "$TMP/ret-edited-output" 2>&1; then
  echo 'expected edited retired file to be reported' >&2; exit 1
fi
grep -q '# local edit' "$TMP/ret-edited/scripts/ai-old.sh"
grep -q '转为项目文件' "$TMP/ret-edited-output"
bash "$RCLI" upgrade "$TMP/ret-edited" > "$TMP/ret-edited-again"
grep -q '# local edit' "$TMP/ret-edited/scripts/ai-old.sh"
if grep -q 'ai-old.sh' "$TMP/ret-edited-again"; then echo 'retired file reported twice' >&2; exit 1; fi

if bash "$RCLI" upgrade "$TMP/ret-accepted" > "$TMP/ret-accepted-output" 2>&1; then
  echo 'expected accepted retired file to be reported' >&2; exit 1
fi
grep -q '# local edit' "$TMP/ret-accepted/scripts/ai-old.sh"

snapshot "$TMP/ret-dry" > "$TMP/ret-dry-before"
bash "$RCLI" upgrade "$TMP/ret-dry" --dry-run > "$TMP/ret-dry-output"
snapshot "$TMP/ret-dry" > "$TMP/ret-dry-after"
cmp "$TMP/ret-dry-before" "$TMP/ret-dry-after"
grep -q '1 个待删除' "$TMP/ret-dry-output"

bash "$RCLI" upgrade "$TMP/ret-legacy" > /dev/null 2>&1 || true
test -f "$TMP/ret-legacy/scripts/ai-old.sh"

bash "$RCLI" upgrade "$TMP/ret-forged" > /dev/null
test -f "$TMP/ret-forged/src/app.sh"
test ! -e "$TMP/ret-forged/scripts/ai-old.sh"

# 2.0: process records move from docs/ to process/ exactly once, refusing before any write.
MSRC="$TMP/migrate-source"
mkdir -p "$MSRC"
cp -R "$ROOT/bin" "$ROOT/template" "$MSRC/"
MCLI="$MSRC/bin/ai-harness"
make_legacy() { # <dir>; rebuild the 1.x layout from a fresh install
  local d=$1
  mkdir -p "$d/docs"
  mv "$d/process/specs" "$d/docs/specs"
  mv "$d/process/task-pool" "$d/docs/task-pool"
  mv "$d/process/metrics.md" "$d/docs/metrics.md"
  rmdir "$d/process"
  sed -i 's#\tprocess/#\tdocs/#' "$d/.ai-harness/manifest.tsv"
  sed -i 's#^process/#docs/#' "$d/.gitignore" "$d/.cursorignore" "$d/.claudeignore"
  sed -i 's#process/specs/active/#docs/specs/active/#' "$d/harness/redlines.conf"
  sed -i 's/^version=2.0.0$/version=1.1.0/' "$d/.ai-harness/version"
  mkdir -p "$d/docs/specs/archive/2026-10/feat-a"
  printf 'archived spec\n' > "$d/docs/specs/archive/2026-10/feat-a/requirements.md"
  printf 'task text\n' > "$d/docs/task-pool/T-000001.md"
  printf '| metrics row |\n' >> "$d/docs/metrics.md"
}
expect_refusal() { # <dir> <message>
  snapshot "$1" > "$TMP/refuse-before"
  if bash "$MCLI" upgrade "$1" > "$TMP/refuse-output" 2>&1; then echo "expected refusal: $2" >&2; exit 1; fi
  grep -q "$2" "$TMP/refuse-output"
  snapshot "$1" > "$TMP/refuse-after"
  cmp "$TMP/refuse-before" "$TMP/refuse-after"
}

MIG="$TMP/mig-ok"
bash "$MCLI" init "$MIG" --no-git >/dev/null
make_legacy "$MIG"
mkdir -p "$MIG/docs/specs/active/.feat-x.tmp.abc123"
printf 'own spec\n' > "$MIG/docs/specs/api.md"
for f in docs/specs/archive/2026-10/feat-a/requirements.md docs/task-pool/T-000001.md docs/metrics.md; do
  hash_one "$MIG/$f" > "$TMP/hash-$(basename "$f")"
done
cp "$MIG/harness/redlines.conf" "$TMP/redlines-before"
snapshot "$MIG" > "$TMP/mig-dry-before"
bash "$MCLI" upgrade "$MIG" --dry-run > "$TMP/mig-dry-output"
snapshot "$MIG" > "$TMP/mig-dry-after"
cmp "$TMP/mig-dry-before" "$TMP/mig-dry-after"
grep -q '将迁移 docs/specs/archive → process/specs/archive' "$TMP/mig-dry-output"
grep -q '将改写旧路径引用: .ai-harness/manifest.tsv' "$TMP/mig-dry-output"

bash "$MCLI" upgrade "$MIG" > "$TMP/mig-output" 2>&1
grep -q '0 个冲突' "$TMP/mig-output"
grep -q 'ALLOWED_WRITE_DIRS' "$TMP/mig-output"
cmp "$TMP/redlines-before" "$MIG/harness/redlines.conf"
for f in specs/archive/2026-10/feat-a/requirements.md task-pool/T-000001.md metrics.md; do
  [ "$(hash_one "$MIG/process/$f")" = "$(cat "$TMP/hash-$(basename "$f")")" ] || { echo "content changed: $f" >&2; exit 1; }
done
test -d "$MIG/process/specs/active/.feat-x.tmp.abc123"
test ! -e "$MIG/docs/specs/active" && test ! -e "$MIG/docs/task-pool" && test ! -e "$MIG/docs/metrics.md"
test -f "$MIG/docs/specs/api.md"
grep -q $'\tprocess/specs/_templates/design.md$' "$MIG/.ai-harness/manifest.tsv"
if grep -q $'\tdocs/' "$MIG/.ai-harness/manifest.tsv"; then echo 'legacy manifest rows left' >&2; exit 1; fi
grep -q '^process/specs/archive/\*\*' "$MIG/.cursorignore"
grep -q '^version=2.0.0$' "$MIG/.ai-harness/version"
(cd "$MIG" && bash scripts/ai-gate.sh status >/dev/null && bash scripts/ai-task-pool.sh list | grep -q T-000001)
bash "$MCLI" upgrade "$MIG" > "$TMP/mig-again" 2>&1
grep -q '0 个冲突' "$TMP/mig-again"
if grep -q '流程记录迁移' "$TMP/mig-again"; then echo 'migration ran twice' >&2; exit 1; fi

# Interrupted after moving directories: the next upgrade completes the reference rewrite.
sed -i 's#\tprocess/#\tdocs/#' "$MIG/.ai-harness/manifest.tsv"
sed -i 's#^process/#docs/#' "$MIG/.cursorignore"
bash "$MCLI" upgrade "$MIG" > "$TMP/mig-heal" 2>&1
grep -q '0 个冲突' "$TMP/mig-heal"
if grep -q $'\tdocs/' "$MIG/.ai-harness/manifest.tsv"; then echo 'interrupted manifest not healed' >&2; exit 1; fi
grep -q '^process/specs/archive/\*\*' "$MIG/.cursorignore"

MIG_ACTIVE="$TMP/mig-active"
bash "$MCLI" init "$MIG_ACTIVE" --no-git >/dev/null
make_legacy "$MIG_ACTIVE"
mkdir -p "$MIG_ACTIVE/docs/specs/active/feat-live"
expect_refusal "$MIG_ACTIVE" '活跃 Spec'

MIG_BOTH="$TMP/mig-both"
bash "$MCLI" init "$MIG_BOTH" --no-git >/dev/null
make_legacy "$MIG_BOTH"
mkdir -p "$MIG_BOTH/process"
expect_refusal "$MIG_BOTH" 'process/ 已存在'

if command -v git >/dev/null 2>&1; then
  MIG_GIT="$TMP/mig-git"
  bash "$MCLI" init "$MIG_GIT" --no-git >/dev/null
  make_legacy "$MIG_GIT"
  (cd "$MIG_GIT" && git init -q && git add -A && git -c user.name=t -c user.email=t@example.invalid commit -qm legacy)
  bash "$MCLI" upgrade "$MIG_GIT" > "$TMP/mig-git-output" 2>&1
  git -C "$MIG_GIT" status --porcelain | grep -q '^R  docs/task-pool/T-000001.md -> process/task-pool/T-000001.md$'
  test ! -e "$MIG_GIT/docs/specs"
fi

# A fresh retrofit into a project with its own docs/specs/*.md is not a legacy layout.
OWN="$TMP/own-specs"
mkdir -p "$OWN/docs/specs"
printf '# api\n' > "$OWN/docs/specs/api.md"
bash "$MCLI" retrofit "$OWN" --no-git --skip-doctor >/dev/null
(cd "$OWN" && bash scripts/ai-gate.sh status >/dev/null)
test -f "$OWN/docs/specs/api.md"
echo 'cli-upgrade: PASS'
