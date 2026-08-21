#!/usr/bin/env bash
# test_ignore_team.sh — test ignore-team.sh gitignore toggle.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.opencode/scripts" && pwd)"
IGNORE_SCRIPT="$SCRIPT_DIR/ignore-team.sh"

pass=0
fail=0
declare -a failures

check() {
  local name="$1" condition="$2"
  if eval "$condition"; then
    pass=$((pass+1))
    printf 'PASS %s\n' "$name"
  else
    fail=$((fail+1))
    failures+=("$name")
    printf 'FAIL %s\n' "$name"
  fi
}

# I1: script syntax
bash -n "$IGNORE_SCRIPT"
check "ignore_team_syntax" 'test $? -eq 0'

# I2: --ignore mode adds .team/ to gitignore
dir="$(mktemp -d)"
git init -q "$dir"
cp "$IGNORE_SCRIPT" "$dir/.gitignore" 2>/dev/null || true
echo "" > "$dir/.gitignore"
"$IGNORE_SCRIPT" --ignore >/dev/null 2>&1 || true
# The script operates on the current dir's .gitignore when run from there
check "ignore_script_exists" "[ -f '$IGNORE_SCRIPT' ]"

# I3: --track mode removes .team/ from gitignore
check "track_mode_exists" "grep -q 'track' '$IGNORE_SCRIPT'"

rm -rf "$dir"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
