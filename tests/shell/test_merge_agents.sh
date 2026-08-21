#!/usr/bin/env bash
# test_merge_agents.sh — test merge-agents.sh surgical merge.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.opencode/scripts" && pwd)"
MERGE_SCRIPT="$SCRIPT_DIR/merge-agents.sh"

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

# M1: script syntax
bash -n "$MERGE_SCRIPT"
check "merge_agents_syntax" 'test $? -eq 0'

# M2: merges baseline into empty consumer
dir="$(mktemp -d)"
baseline="$dir/baseline.md"
consumer="$dir/consumer.md"
output="$dir/output.md"
MARKER="Project-specific additions belong BELOW this line"
echo "# Baseline content" > "$baseline"
cat > "$consumer" <<EOF
# Team Contract

$MARKER

## My local settings
Some local content here.
EOF
"$MERGE_SCRIPT" "$baseline" "" "$consumer" "$output" 2>/dev/null
check "merge_empty_consumer" "[ -f '$output' ]"
check "merge_preserves_baseline" "grep -q 'Baseline content' '$output'"
rm -rf "$dir"

# M3: preserves local tail below marker
dir="$(mktemp -d)"
baseline="$dir/baseline.md"
consumer="$dir/consumer.md"
output="$dir/output.md"
cat > "$baseline" <<EOF
# Team Contract

$MARKER
EOF
cat > "$consumer" <<EOF
# Team Contract

$MARKER

## My local settings
Some local content here.
EOF
"$MERGE_SCRIPT" "$baseline" "" "$consumer" "$output" 2>/dev/null
check "merge_preserves_local_tail" "grep -q 'My local settings' '$output'"
rm -rf "$dir"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
