#!/usr/bin/env bash
# test-default-branch.sh — standalone TDD test for scripts/default-branch.sh.
# Builds throwaway repos in mktemp -d and runs the helper with cwd inside that repo,
# exercising each detection path deterministically and offline.
# Exit 0 iff all tests pass; exit 1 otherwise.
set -uo pipefail

HELPER="$(cd "$(dirname "$0")" && pwd)/default-branch.sh"

pass=0
fail=0
declare -a failures

# run_in <dir> — run the helper with cwd inside <dir>, capturing stdout/stderr.
# Sets: rc, out, err
run_in() {
  local dir="$1"
  if (cd "$dir" && "$HELPER" >out 2>err); then
    rc=0
  else
    rc=$?
  fi
  out="$(cd "$dir" && cat out)"
  err="$(cd "$dir" && cat err)"
}

# check <testname> <expected_rc> <expected_out> <expected_err_contains>
check() {
  local name="$1" exp_rc="$2" exp_out="$3" exp_err="$4"
  local ok=1
  if [ "$rc" -ne "$exp_rc" ]; then ok=0; fi
  if [ "$out" != "$exp_out" ]; then ok=0; fi
  if [ "$exp_err" = "" ]; then
    if [ -n "$err" ]; then ok=0; fi
  else
    case "$err" in
      *"$exp_err"*) : ;;
      *) ok=0 ;;
    esac
  fi
  if [ "$ok" -eq 1 ]; then
    pass=$((pass+1))
    printf 'PASS %s\n' "$name"
  else
    fail=$((fail+1))
    failures+=("$name")
    printf 'FAIL %s (rc=%s out=<%s> err=<%s>)\n' "$name" "$rc" "$out" "$err"
  fi
}

# --- C1: detects via origin/HEAD ----------------------------------------------
dir="$(mktemp -d)"
git init -q "$dir"
git -C "$dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
run_in "$dir"
check 'C1 detects_via_origin_head' 0 'main' ''
rm -rf "$dir"

# --- C2a: order origin/HEAD beats init.defaultBranch --------------------------
dir="$(mktemp -d)"
git init -q "$dir"
git -C "$dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
git -C "$dir" config init.defaultBranch develop
run_in "$dir"
check 'C2a order_origin_head_beats_config' 0 'main' ''
rm -rf "$dir"

# --- C2b: fallback init.defaultBranch -----------------------------------------
dir="$(mktemp -d)"
git init -q "$dir"
git -C "$dir" config init.defaultBranch develop
run_in "$dir"
check 'C2b fallback_init_default_branch' 0 'develop' ''
rm -rf "$dir"

# --- C2c: fallback main (no origin/HEAD, no init.defaultBranch) ---------------
dir="$(mktemp -d)"
git init -q "$dir"
run_in "$dir"
check 'C2c fallback_main' 0 'main' ''
rm -rf "$dir"

# --- C3: clean capture (use C1-style repo) -------------------------------------
dir="$(mktemp -d)"
git init -q "$dir"
git -C "$dir" symbolic-ref refs/remotes/origin/HEAD refs/remotes/origin/main
run_in "$dir"
check 'C3 clean_capture' 0 'main' ''
rm -rf "$dir"

# --- C4: no git repo -> exit non-zero ------------------------------------------
dir="$(mktemp -d)"
run_in "$dir"
check 'C4 no_git_repo_exits_nonzero' 1 '' 'default-branch.sh'
rm -rf "$dir"

# --- C5: other scripts untouched ------------------------------------------------
if [ -n "${VALIDATE_TEAM_RUNNING:-}" ]; then
  pass=$((pass+1)); printf 'PASS C5 other_scripts_untouched (skipped: invoked from validate-team.sh)\n'
elif git -C "$(cd "$(dirname "$0")/.." && pwd)" diff --exit-code -- \
    scripts/drift-check.sh scripts/sync-origin.sh scripts/validate-team.sh >/dev/null 2>&1; then
  pass=$((pass+1))
  printf 'PASS C5 other_scripts_untouched\n'
else
  fail=$((fail+1))
  failures+=('C5 other_scripts_untouched')
  printf 'FAIL C5 other_scripts_untouched (diff in drift-check/sync-origin/validate-team)\n'
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
