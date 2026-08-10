#!/usr/bin/env bash
# sync-origin.sh — fold upstream `origin/<detected-default>` changes into the local working
# branch without clobbering local context. AGENTS.md is merged surgically (preserving the
# local tail below the BASELINE-OWNED CONTENT marker); other baseline-owned files merge
# normally. A failed `git merge` — whether it left conflicts or refused over local changes —
# is never reported as success: real conflict pairs (.ours/.upstream) land directly under
# .team/federation/conflicts/, and transient temp files live under .team/federation/conflicts/scratch/.
#
# Local side (precedence): LOCAL_BRANCH > WORKING_BRANCH > current branch.
# Remote side (precedence): REMOTE (explicit) > origin/<detected-default>.
# The default branch name is detected via scripts/default-branch.sh, never hardcoded.
#
#   sync-origin.sh [--dry] [--yes]
#
#   --dry   show what would happen without writing anything
#   --yes   do not prompt; apply the AGENTS.md merge automatically (conflicts still surface)
#
# Exit codes:
#   0  synced cleanly (or nothing to do)
#   1  conflicts remain / user declined / a git merge failed (conflicts or refusal) / abort
#   3  no upstream available
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

note()  { printf '  %s\n' "$*"; }
warn()  { printf '  %s\n' "$*" >&2; }

BRANCH="${LOCAL_BRANCH:-${WORKING_BRANCH:-$(git symbolic-ref --short HEAD 2>/dev/null || echo main)}}"
if ! DEFAULT_B="$(scripts/default-branch.sh)"; then
  warn "cannot determine default branch"
  exit 3
fi
REMOTE="${REMOTE:-origin/${DEFAULT_B}}"
if ! git rev-parse --verify "$BRANCH" >/dev/null 2>&1; then
  warn "working branch '$BRANCH' does not exist locally"
  exit 3
fi
# --- guard: resolved local branch must be the checked-out HEAD ---------------
# sync-origin merges into HEAD (the checked-out branch), never into $BRANCH. If a caller
# overrides LOCAL_BRANCH/WORKING_BRANCH to a locally-existing but non-checked-out branch, the
# merge below would silently target the wrong branch. Refuse loudly instead.
CURRENT="$(git symbolic-ref --short HEAD 2>/dev/null || echo main)"
if [ "$BRANCH" != "$CURRENT" ]; then
  warn "refusing to sync: resolved local branch '$BRANCH' is not the checked-out branch '$CURRENT'"
  warn "sync-origin merges into HEAD; set WORKING_BRANCH/LOCAL_BRANCH to the checked-out branch, or check it out first."
  exit 1
fi
ME="$(basename "$0")"
DRY=""; AUTO=""
for a in "$@"; do
  case "$a" in
    --dry) DRY=1;; --yes) AUTO=1;; *) warn "unknown arg: $a";;
  esac
done
run() { # run CMD...  ; no-op when --dry
  if [ -n "$DRY" ]; then note "(dry) $*"; else "$@"; fi
}
ask() { # prompt arg -> proceed
  [ -n "$AUTO" ] && return 0
  printf '%s ' "$1 [y/N]?"
  local r; read -r r
  case "$r" in y|Y|yes|Yes|YES) return 0;; *) return 1;; esac
}

# --- 0. fetch upstream -------------------------------------------------------
git rev-parse --verify "$REMOTE" >/dev/null 2>&1 \
  || { warn "no upstream ref '$REMOTE'; nothing to sync"; exit 3; }
run git fetch "$(printf '%s' "$REMOTE" | cut -d/ -f1)"

# Scratch dir for transient temp files only (disposable; NOT human-reconciliation state).
# Real conflict pairs for the human go directly under .team/federation/conflicts/.
SCRATCH=".team/federation/conflicts/scratch"

# --- 1. AGENTS.md surgical merge (preserve local tail) ----------------------
if [ -f AGENTS.md ]; then
  if [ -n "$DRY" ]; then
    note "(dry) would surgically merge AGENTS.md (preserve local tail)"
  else
    rm -rf "$SCRATCH"; mkdir -p "$SCRATCH"
    # baseline = origin's AGENTS.md (materialize to a temp file); prev = our own last
    # baseline snapshot (catalog) if present; consumer = our current AGENTS.md on disk.
    base_tmp="$SCRATCH/AGENTS.md.upstream"
    git show "$REMOTE:AGENTS.md" > "$base_tmp"
    # prev = our last baseline snapshot (catalog) if present; otherwise fall back to the
    # previous baseline (merge-base) AGENTS.md so a pure baseline copy is adopted wholesale.
    prev_cat="$(ls .team/federation/catalog/*/v*/AGENTS.md 2>/dev/null | head -n1)"
    if [ -z "$prev_cat" ]; then
      mb="$(git merge-base HEAD "$REMOTE" 2>/dev/null)"
      prev_tmp="$SCRATCH/AGENTS.md.prev"
      if git show "$mb:AGENTS.md" > "$prev_tmp" 2>/dev/null; then
        prev_cat="$prev_tmp"
      else
        prev_cat=AGENTS.md
      fi
    fi
    if ask "surgically merge AGENTS.md (preserve local tail)"; then
      tmp="$SCRATCH/AGENTS.md.ours"
      if scripts/merge-agents.sh "$base_tmp" "$prev_cat" AGENTS.md "$tmp"; then
        cp -p "$tmp" AGENTS.md
        note "AGENTS.md: baseline-owned content updated; local tail preserved"
        # Commit the merged AGENTS.md so the git merge below isn't blocked by
        # uncommitted changes to the same file.
        git add AGENTS.md
        git commit -qm "sync: merge AGENTS.md (preserve local tail)"
      else
        # Cannot split the local AGENTS.md safely (merge-agents exit 2): record a real
        # conflict pair for the human (our current file + upstream's baseline), never
        # overwrite the local file.
        mkdir -p ".team/federation/conflicts"
        cp -p AGENTS.md ".team/federation/conflicts/AGENTS.md.ours" 2>/dev/null || true
        cp -p "$base_tmp" ".team/federation/conflicts/AGENTS.md.upstream" 2>/dev/null || true
        warn "AGENTS.md could not be auto-merged; conflict pair recorded in .team/federation/conflicts/"
        exit 1
      fi
    else
      note "declined AGENTS.md merge"
    fi
  fi
fi

# --- 2. merge the rest of the baseline on top of local main ----------------
if [ -n "$DRY" ]; then
  note "(dry) would run 'git merge $REMOTE' for the rest of the baseline"
  note "sync complete (dry)."
  exit 0
fi
if ! ask "run 'git merge $REMOTE' for the rest of the baseline"; then
  note "declined merge; leaving $REMOTE changes unapplied"; exit 0
fi
# Capture the merge's exit status: a merge that fails WITHOUT leaving conflicts (e.g. local
# uncommitted changes it refuses to overwrite) must still be a failure, not a "sync complete".
merge_rc=0
if git rev-list "$(git merge-base HEAD "$REMOTE")..$REMOTE" --count >/dev/null 2>&1 \
   && [ "$(git rev-list HEAD..$REMOTE --count)" -gt 0 ]; then
  if git merge --no-ff "$REMOTE" -m "sync: merge $REMOTE into $BRANCH ($(date +%F))"; then
    :
  else
    merge_rc=$?
    warn "git merge '$REMOTE' into '$BRANCH' failed (rc=$merge_rc)"
  fi
fi

# --- 3. detect a failed or conflicted merge -----------------------------------
# A failed `git merge` leaves UU/AA/DD markers in the tree. Surface each conflicted
# file to .team/federation/conflicts/ (consumer's version + upstream's version) and
# exit 1 so the caller knows the sync did not complete cleanly. A merge that failed
# WITHOUT leaving markers (local changes git refuses to overwrite, etc.) is not a
# success either — still exit 1.
conflicts="$(git status --porcelain 2>/dev/null | grep -E '^(UU|AA|DD)' | awk '{print $2}')"
if [ -n "$conflicts" ]; then
  warn "unresolved merge conflicts remain:"
  printf '%s\n' "$conflicts" | sed 's/^/    /'
  for f in $conflicts; do
    mkdir -p ".team/federation/conflicts/$(dirname "$f")"
    cp -p "$f" ".team/federation/conflicts/$f.ours" 2>/dev/null || true
    git show "$REMOTE:$f" > ".team/federation/conflicts/$f.upstream" 2>/dev/null || true
    note "conflict recorded: .team/federation/conflicts/$f.{ours,upstream}"
  done
  exit 1
fi
if [ "$merge_rc" -ne 0 ]; then
  warn "git merge failed without leaving tracked conflicts (rc=$merge_rc); working tree unchanged — review before continuing"
  exit 1
fi

# --- 4. report status --------------------------------------------------------
note "sync complete."
note "disposable scratch artifacts: $SCRATCH/ (real conflict pairs live in .team/federation/conflicts/)"
git status --short 2>/dev/null | sed 's/^/  /'
exit 0