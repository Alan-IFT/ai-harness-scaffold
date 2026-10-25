#!/usr/bin/env bash
# CLI smoke: init installs a working harness; retrofit dry-run is read-only and retrofit keeps existing files.
set -euo pipefail

ROOT=$(cd "$(dirname "$0")/.." && pwd)
CLI="$ROOT/bin/ai-harness"
TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

bash "$CLI" init "$TMP/new" --no-git >/dev/null
grep -q '^version=2.0.0$' "$TMP/new/.ai-harness/version"
(cd "$TMP/new" && bash scripts/ai-gate.sh status >/dev/null && bash scripts/ai-task-pool.sh next >/dev/null)

mkdir -p "$TMP/old/docs/specs"
printf 'own rules\n' > "$TMP/old/AGENTS.md"
printf '# api\n' > "$TMP/old/docs/specs/api.md"
before=$(find "$TMP/old" -type f | sort | xargs cat | md5sum)
bash "$CLI" retrofit "$TMP/old" --dry-run >/dev/null
[ "$before" = "$(find "$TMP/old" -type f | sort | xargs cat | md5sum)" ] || { echo 'dry-run wrote files' >&2; exit 1; }

bash "$CLI" retrofit "$TMP/old" --no-git --skip-doctor >/dev/null
grep -qx 'own rules' "$TMP/old/AGENTS.md"
test -f "$TMP/old/.ai-harness/suggested/AGENTS.md"
test -f "$TMP/old/docs/specs/api.md"
(cd "$TMP/old" && bash scripts/ai-gate.sh status >/dev/null)

echo 'cli-smoke: PASS'
