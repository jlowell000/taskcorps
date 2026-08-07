#!/usr/bin/env bash
# test-install-global-sed.sh — throwaway-repo TDD test for the registry-update sed in
# scripts/install-global.sh. Reproduces the bug: the old pattern `\| v[0-9.]*\|` never matches
# a row like `| global | HOST | PATH | v0.2.0 | — |` (space before the trailing pipe), so the
# version column is not updated (silent no-op). Asserts the version DOES update.
set -u

fail=0
pass=0
failures=()

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

REPO="$TMP/repo"
mkdir -p "$REPO/scripts" "$REPO/.team/federation/releases/v1.0.0" "$REPO/.team/federation/catalog"
# The script chdirs to the repo root (parent of scripts/) and reads a hardcoded registry +
# changelog, so it must live at scripts/install-global.sh in the throwaway repo.
cp "$ROOT/scripts/install-global.sh" "$REPO/scripts/install-global.sh"
cat > "$REPO/.team/federation/changelog.md" <<'EOF'
**CURRENT_VERSION: v1.0.0** (the top row is always the current release)
EOF
# Seed a stale global-host row (host id is deterministic: global-<user>-<host>).
GID="global-$(whoami)-$(hostname)"
printf '| global | %s | /tmp/fake | v0.2.0 | — |\n' "$GID" > "$REPO/.team/federation/registry.md"

# Run the REAL script with GLOBAL pointed at a throwaway dir (avoids touching ~/.config).
GLOBAL="$TMP/global" bash "$REPO/scripts/install-global.sh" >/dev/null 2>&1
rc=$?

if [ "$rc" -eq 0 ]; then
  pass=$((pass+1)); printf 'PASS S1 script_exits_zero\n'
else
  fail=$((fail+1)); failures+=('S1 script_exits_zero'); printf 'FAIL S1 script_exits_zero (rc=%s)\n' "$rc"
fi

# The version column must be updated from v0.2.0 to v1.0.0 (the actual sed bug). The path
# column is rewritten by the script to the real GLOBAL dir, so assert only the version.
if grep -Eq "^\\| global \\| $GID \\| .* \\| v1\\.0\\.0 \\|" "$REPO/.team/federation/registry.md"; then
  pass=$((pass+1)); printf 'PASS S2 version_updated_to_current\n'
else
  fail=$((fail+1)); failures+=('S2 version_updated_to_current')
  printf 'FAIL S2 version_updated_to_current\n  registry now:\n'
  sed 's/^/    /' "$REPO/.team/federation/registry.md"
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
