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

# --- failure-path tests -------------------------------------------------------

# M4: stitch preserves percent signs in owned/tail (no printf interpolation)
dir="$(mktemp -d)"
baseline="$dir/baseline.md"
consumer="$dir/consumer.md"
output="$dir/output.md"
printf '# Baseline\n\n%s\n' "$MARKER" > "$baseline"
cat > "$consumer" <<EOF
# Consumer

$MARKER

## Local settings
Use %s for format strings and 100%% for literal percent.
EOF
"$MERGE_SCRIPT" "$baseline" "" "$consumer" "$output" 2>/dev/null
check "stitch_preserves_percent" "grep -q '100%%' '$output'"
check "stitch_preserves_format_s" "grep -q '%s for format' '$output'"
rm -rf "$dir"

# M5: stitch preserves leading dashes in tail (YAML-safe)
dir="$(mktemp -d)"
baseline="$dir/baseline.md"
consumer="$dir/consumer.md"
output="$dir/output.md"
printf '# Baseline\n\n%s\n' "$MARKER" > "$baseline"
cat > "$consumer" <<EOF
# Consumer

$MARKER

## Local settings
- bullet one
- bullet two with dashes
EOF
"$MERGE_SCRIPT" "$baseline" "" "$consumer" "$output" 2>/dev/null
check "stitch_preserves_leading_dashes" "grep -q 'bullet one' '$output'"
check "stitch_preserves_bullet_two" "grep -q 'bullet two with dashes' '$output'"
rm -rf "$dir"

# M6: usage rejects wrong arg count
rc=0
bash "$MERGE_SCRIPT" 2>/dev/null || rc=$?
check "usage_no_args" "[ $rc -ne 0 ]"
rc=0
bash "$MERGE_SCRIPT" a b c d e 2>/dev/null || rc=$?
check "usage_too_many_args" "[ $rc -ne 0 ]"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
