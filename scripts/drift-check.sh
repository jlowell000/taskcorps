#!/usr/bin/env bash
# drift-check.sh — reconcile the local working branch with upstream origin/<detected-default>.
#
# The local repo is the baseline's working source of truth, but it may carry local context
# on the working branch that upstream (origin/<detected-default>) doesn't have, and may lag
# behind new upstream releases. This script classifies the relationship so the federation
# agent can decide whether a sync is needed and how safe it is.
#
# Local side (precedence): LOCAL_BRANCH > WORKING_BRANCH > current branch.
# Remote side (precedence): REMOTE (explicit) > origin/<detected-default>.
# The default branch name is detected via scripts/default-branch.sh, never hardcoded.
#
# Exit codes:
#   0  CLEAN or AHEAD (safe; nothing blocking)
#   1  BEHIND or DIVERGED — origin has changes the working branch does not (release needed)
#   2  dirty working tree (baseline-owned tracked files modified, uncommitted)
#   3  ambiguous (no upstream / cannot determine default / working branch missing)
#
# Never modifies anything: fetch is the only network/disk write, and it only updates git's
# remote-tracking refs.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

note() { printf '  %s\n' "$*"; }

BRANCH="${LOCAL_BRANCH:-${WORKING_BRANCH:-$(git symbolic-ref --short HEAD 2>/dev/null || echo main)}}"
if ! DEFAULT_B="$(scripts/default-branch.sh)"; then
  note "warn: cannot determine default branch"
  exit 3
fi
REMOTE="${REMOTE:-origin/${DEFAULT_B}}"
if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  note "warn: working branch '$BRANCH' does not exist locally"
  exit 3
fi

echo "== drift-check: '$BRANCH' vs '$REMOTE' =="

# 1. fetch upstream (network; consumes no files)
if ! git fetch "$(printf '%s' "$REMOTE" | cut -d/ -f1)" 2>/dev/null; then
  note "warn: fetch failed — is there a usable remote?"
fi

# 2. relationship to upstream
if ! git rev-parse --verify "$REMOTE" >/dev/null 2>&1; then
  note "no upstream ref '$REMOTE' — cannot compare"
  exit 3
fi

echo "== uncommitted baseline-owned changes (dirty check) =="
# 3. uncommitted changes to working tree (tracked files), excluding ignored runtime state.
#    Dirty wins over BEHIND/AHEAD (a dirty tree gates releases regardless of drift).
dirty="$(git status --porcelain | grep -v '^??' || true)"
if [ -n "$dirty" ]; then
  echo "$dirty" | sed 's/^/    /'
  note "dirty: uncommitted baseline-owned changes present — gate releases on a clean tree"
  exit 2
fi

behind="$(git rev-list "$BRANCH..$REMOTE" --count 2>/dev/null || echo 0)"
ahead="$(git rev-list "$REMOTE..$BRANCH" --count 2>/dev/null || echo 0)"

echo "  ahead: $ahead   behind: $behind"

if [ "$behind" -gt 0 ] && [ "$ahead" -gt 0 ]; then
  note "DIVERGED: local has $ahead unpushed + upstream has $behind unpulled"
  exit 1
elif [ "$behind" -gt 0 ]; then
  note "BEHIND: upstream '$REMOTE' has $behind commits not on '$BRANCH' — sync requested"
  exit 1
elif [ "$ahead" -gt 0 ]; then
  note "AHEAD: '$BRANCH' has $ahead commits upstream lacks (local context) — no push by default"
fi

note "clean (or only ignored runtime state) — no blocking drift"
exit 0