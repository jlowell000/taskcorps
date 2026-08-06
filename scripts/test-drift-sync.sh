#!/usr/bin/env bash
# test-drift-sync.sh — standalone TDD test for scripts/drift-check.sh + scripts/sync-origin.sh.
# Builds throwaway repos under mktemp -d (bare repo as `origin` at a local path, fully offline),
# copies the three scripts into the throwaway repo, and exercises the drift/sync behavior per
# the T2 spec test plan. Exit 0 iff all tests pass; exit 1 otherwise.
set -uo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPTS="$REPO/scripts"

pass=0
fail=0
declare -a failures

# --- harness helpers ----------------------------------------------------------

# setup <default> — create a bare origin (default branch <default>) + a work clone, and copy
# the three scripts into work/scripts/. Sets globals: TMP, ORIGIN, WORK, DEFAULT.
setup() {
  DEFAULT="$1"
  TMP="$(mktemp -d)"
  ORIGIN="$TMP/origin.git"
  WORK="$TMP/work"
  git init -q --bare "$ORIGIN"
  git -C "$ORIGIN" symbolic-ref HEAD "refs/heads/$DEFAULT"
  # seed an initial commit on the default branch so clone yields a working branch
  local seed="$TMP/seed"
  git init -q "$seed"
  git -C "$seed" config user.email t@t
  git -C "$seed" config user.name t
  git -C "$seed" checkout -q -b "$DEFAULT"
  echo base > "$seed/file.txt"
  git -C "$seed" add file.txt
  git -C "$seed" commit -q -m base
  git -C "$seed" remote add origin "$ORIGIN"
  git -C "$seed" push -q -u origin "$DEFAULT"
  rm -rf "$seed"
  git clone -q "$ORIGIN" "$WORK"
  git -C "$WORK" config user.email t@t
  git -C "$WORK" config user.name t
  git -C "$WORK" symbolic-ref refs/remotes/origin/HEAD "refs/remotes/origin/$DEFAULT"
  mkdir -p "$WORK/scripts"
  cp "$SCRIPTS/default-branch.sh" "$SCRIPTS/drift-check.sh" "$SCRIPTS/sync-origin.sh" "$WORK/scripts/"
  chmod +x "$WORK/scripts/"*.sh
}

# origin_commit <branch> <msg> — add a commit to <branch> on origin via a temp clone.
origin_commit() {
  local branch="$1" msg="$2"
  local oc="$TMP/oc"
  git clone -q "$ORIGIN" "$oc"
  git -C "$oc" config user.email t@t
  git -C "$oc" config user.name t
  git -C "$oc" checkout -q "$branch"
  echo "$msg" >> "$oc/file.txt"
  git -C "$oc" add file.txt
  git -C "$oc" commit -q -m "$msg"
  git -C "$oc" push -q origin "$branch"
  rm -rf "$oc"
}

# local_commit <msg> — commit on the current branch of work without pushing.
local_commit() {
  echo "$1" >> "$WORK/file.txt"
  git -C "$WORK" add file.txt
  git -C "$WORK" commit -q -m "$1"
}

# run_script <script> [VAR=val ...] [--arg ...] — run a copied script with cwd inside work,
# capturing rc/out/err. Env assignments (VAR=val) and script args (--arg) are supported.
run_script() {
  local script="$1"; shift
  local envs=() args=()
  for a in "$@"; do
    case "$a" in
      *=*) envs+=("$a") ;;
      *) args+=("$a") ;;
    esac
  done
  if (cd "$WORK" && env "${envs[@]}" "./scripts/$script" "${args[@]}" >out 2>err); then
    rc=0
  else
    rc=$?
  fi
  out="$(cd "$WORK" && cat out)"
  err="$(cd "$WORK" && cat err)"
}

# check <name> <expected_rc> [+substr ...] [-substr ...] — assert rc and stdout substrings.
check() {
  local name="$1" exp_rc="$2"; shift 2
  local ok=1
  [ "$rc" -eq "$exp_rc" ] || ok=0
  for a in "$@"; do
    case "$a" in
      +*) case "$out" in *"${a#+}"*) : ;; *) ok=0 ;; esac ;;
      -*) case "$out" in *"${a#-}"*) ok=0 ;; *) : ;; esac ;;
    esac
  done
  if [ "$ok" -eq 1 ]; then
    pass=$((pass+1))
    printf 'PASS %s\n' "$name"
  else
    fail=$((fail+1))
    failures+=("$name")
    printf 'FAIL %s (rc=%s out=<%s> err=<%s>)\n' "$name" "$rc" "$out" "$err"
  fi
}

# --- C1a: drift_clean ---------------------------------------------------------
setup main
run_script drift-check.sh
check 'C1a drift_clean' 0 '+clean' '+origin/main'
rm -rf "$TMP"

# --- C1b: drift_ahead --------------------------------------------------------
setup main
local_commit ahead
run_script drift-check.sh
check 'C1b drift_ahead' 0 '+AHEAD'
rm -rf "$TMP"

# --- C1c: drift_behind ------------------------------------------------------
setup main
origin_commit main behind
run_script drift-check.sh
check 'C1c drift_behind' 1 '+BEHIND'
rm -rf "$TMP"

# --- C1d: drift_diverge -----------------------------------------------------
setup main
local_commit local
origin_commit main remote
run_script drift-check.sh
check 'C1d drift_diverge' 1 '+DIVERGED'
rm -rf "$TMP"

# --- C1e: drift_detected_default_remote -------------------------------------
setup develop
origin_commit develop ahead
run_script drift-check.sh
check 'C1e drift_detected_default_remote' 1 '+BEHIND' '+origin/develop' '-origin/main'
rm -rf "$TMP"

# --- C1f: drift_working_branch_override -------------------------------------
setup main
git -C "$WORK" checkout -q -b feature
local_commit feat
git -C "$WORK" checkout -q main
run_script drift-check.sh WORKING_BRANCH=feature
check 'C1f drift_working_branch_override' 0 '+AHEAD' '+feature'
rm -rf "$TMP"

# --- C2a: sync_merges_detected_default --------------------------------------
setup develop
origin_commit develop ahead
run_script sync-origin.sh --yes
if [ "$rc" -eq 0 ] && git -C "$WORK" merge-base --is-ancestor origin/develop develop >/dev/null 2>&1; then
  pass=$((pass+1)); printf 'PASS C2a sync_merges_detected_default\n'
else
  fail=$((fail+1)); failures+=('C2a sync_merges_detected_default')
  printf 'FAIL C2a sync_merges_detected_default (rc=%s out=<%s> err=<%s>)\n' "$rc" "$out" "$err"
fi
rm -rf "$TMP"

# --- C2b: sync_working_branch_override ---------------------------------------
setup main
git -C "$WORK" checkout -q -b feature
origin_commit main ahead
run_script sync-origin.sh WORKING_BRANCH=feature --yes
if [ "$rc" -eq 0 ] && git -C "$WORK" merge-base --is-ancestor origin/main feature >/dev/null 2>&1; then
  pass=$((pass+1)); printf 'PASS C2b sync_working_branch_override\n'
else
  fail=$((fail+1)); failures+=('C2b sync_working_branch_override')
  printf 'FAIL C2b sync_working_branch_override (rc=%s out=<%s> err=<%s>)\n' "$rc" "$out" "$err"
fi
rm -rf "$TMP"

# --- C2c: sync_noop_when_current ---------------------------------------------
setup main
run_script sync-origin.sh --yes
if [ "$rc" -eq 0 ] && [ "$(git -C "$WORK" rev-parse HEAD)" = "$(git -C "$WORK" rev-parse origin/main)" ]; then
  pass=$((pass+1)); printf 'PASS C2c sync_noop_when_current\n'
else
  fail=$((fail+1)); failures+=('C2c sync_noop_when_current')
  printf 'FAIL C2c sync_noop_when_current (rc=%s out=<%s> err=<%s>)\n' "$rc" "$out" "$err"
fi
rm -rf "$TMP"

# --- C3a: drift_dirty_exit2 --------------------------------------------------
setup main
echo dirty >> "$WORK/file.txt"
run_script drift-check.sh
check 'C3a drift_dirty_exit2' 2
rm -rf "$TMP"

# --- C3b: drift_no_upstream_exit3 --------------------------------------------
setup main
git -C "$WORK" remote remove origin
run_script drift-check.sh
check 'C3b drift_no_upstream_exit3' 3 '+cannot compare'
rm -rf "$TMP"

# --- C3c: sync_dry_no_write --------------------------------------------------
setup main
origin_commit main ahead
before="$(git -C "$WORK" rev-parse HEAD)"
run_script sync-origin.sh --dry
after="$(git -C "$WORK" rev-parse HEAD)"
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ]; then
  pass=$((pass+1)); printf 'PASS C3c sync_dry_no_write\n'
else
  fail=$((fail+1)); failures+=('C3c sync_dry_no_write')
  printf 'FAIL C3c sync_dry_no_write (rc=%s before=%s after=%s out=<%s> err=<%s>)\n' "$rc" "$before" "$after" "$out" "$err"
fi
rm -rf "$TMP"

# --- C4a: sync_never_pushes --------------------------------------------------
setup main
origin_commit main ahead
before="$(git -C "$WORK" ls-remote origin)"
run_script sync-origin.sh --yes
after="$(git -C "$WORK" ls-remote origin)"
if [ "$rc" -eq 0 ] && [ "$before" = "$after" ]; then
  pass=$((pass+1)); printf 'PASS C4a sync_never_pushes\n'
else
  fail=$((fail+1)); failures+=('C4a sync_never_pushes')
  printf 'FAIL C4a sync_never_pushes (rc=%s out=<%s> err=<%s>)\n' "$rc" "$out" "$err"
fi
rm -rf "$TMP"

# --- C4b: guard_no_push_in_scripts -------------------------------------------
if grep -n 'git push' "$SCRIPTS/drift-check.sh" "$SCRIPTS/sync-origin.sh" >/dev/null 2>&1; then
  fail=$((fail+1)); failures+=('C4b guard_no_push_in_scripts')
  printf 'FAIL C4b guard_no_push_in_scripts (git push found in drift-check/sync-origin)\n'
else
  pass=$((pass+1)); printf 'PASS C4b guard_no_push_in_scripts\n'
fi

# --- C5: validate_team_green -------------------------------------------------
if (cd "$REPO" && ./scripts/validate-team.sh >/dev/null 2>&1); then
  pass=$((pass+1)); printf 'PASS C5 validate_team_green\n'
else
  fail=$((fail+1)); failures+=('C5 validate_team_green')
  printf 'FAIL C5 validate_team_green (validate-team.sh exited non-zero)\n'
fi

# --- G1: guard_default_branch_untouched --------------------------------------
if git -C "$REPO" diff --exit-code -- scripts/default-branch.sh scripts/validate-team.sh >/dev/null 2>&1; then
  pass=$((pass+1)); printf 'PASS G1 guard_default_branch_untouched\n'
else
  fail=$((fail+1)); failures+=('G1 guard_default_branch_untouched')
  printf 'FAIL G1 guard_default_branch_untouched (diff in default-branch.sh/validate-team.sh)\n'
fi

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0