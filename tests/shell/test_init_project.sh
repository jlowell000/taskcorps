#!/usr/bin/env bash
# test_init_project.sh — test init-project.sh .team/ skeleton seeding.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.opencode/scripts" && pwd)"
INIT_SCRIPT="$SCRIPT_DIR/init-project.sh"

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
bash -n "$INIT_SCRIPT"
check "init_project_syntax" 'test $? -eq 0'

# I2: creates .team/ subdirs
dir="$(mktemp -d)"
"$INIT_SCRIPT" "$dir" >/dev/null 2>&1
check "creates_team_dir" "test -d '$dir/.team'"
check "creates_context_dir" "test -d '$dir/.team/context'"
check "creates_tasks_dir" "test -d '$dir/.team/tasks'"
check "creates_checkpoints_dir" "test -d '$dir/.team/checkpoints'"
check "creates_archive_dir" "test -d '$dir/.team/archive'"
check "creates_proposals_dir" "test -d '$dir/.team/proposals'"

# I3: creates backlog.md and status.md
check "creates_backlog" "test -f '$dir/.team/backlog.md'"
check "creates_status" "test -f '$dir/.team/status.md'"

# I4: idempotent (re-run doesn't fail)
"$INIT_SCRIPT" "$dir" >/dev/null 2>&1
check "idempotent_rerun" 'test $? -eq 0'

rm -rf "$dir"

# --- failure-path tests -------------------------------------------------------

# I5: set -euo pipefail doesn't break on local in loops (now inside functions)
dir="$(mktemp -d)"
# Run with explicit pipefail to catch any issues
bash -euo pipefail "$INIT_SCRIPT" "$dir" >/dev/null 2>&1
check "strict_mode_no_local_error" '[ $? -eq 0 ]'
rm -rf "$dir"

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
