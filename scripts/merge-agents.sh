#!/usr/bin/env bash
# merge-agents.sh — surgically merge a baseline AGENTS.md into a consumer's AGENTS.md,
# replacing only the baseline-owned content ABOVE the "BASELINE-OWNED CONTENT" marker while
# preserving the consumer's project-specific tail BELOW it.
#
#   merge-agents.sh <baseline> <prev> <consumer> <outfile>
#
#   <baseline>  the newly released AGENTS.md (already ends with the marker)
#   <prev>      the consumer's previous baseline snapshot
#               (catalog/<consumer>/<ver>/AGENTS.md); pass "" when none exists
#   <consumer>  the consumer's current AGENTS.md on disk
#   <outfile>   path to write the merged result
#
# Exit codes:
#   0  merged (or consumer is a pure baseline copy -> adopted wholesale)
#   2  conflict: consumer has no marker AND can't be cleanly split from <prev>;
#      the human must reconcile (outfile is NOT written)
#
# The merge never loses data: a consumer with no marker is either a pure baseline copy
# (identical to <prev>) -> adopt the new baseline wholesale, or it carries custom content
# that cannot be split reliably -> conflict.
set -u

MARK_PAT='BASELINE-OWNED CONTENT'

baseline="$1"; prev="${2:-}"; consumer="${3:-}"; outfile="$4"
note() { echo "merge-agents: $*" >&2; }

[ -f "$baseline" ]  || { note "baseline not found: $baseline"; exit 127; }
[ -n "$consumer" ] && [ -f "$consumer" ] || { note "consumer not found: $consumer"; exit 127; }

# Owned portion = the whole released baseline; it already ends with the marker.
owned="$(cat "$baseline")"

# Tail = the consumer's content strictly AFTER its own marker line (preserved verbatim).
mln="$(grep -n -m1 -F "$MARK_PAT" "$consumer" 2>/dev/null | cut -d: -f1)"
if [ -n "$mln" ]; then
  tail="$(tail -n "+$((mln+1))" "$consumer")"
else
  # No marker on the consumer. Decide by comparing against the previous snapshot:
  #   - prev exists AND consumer bytes-identical to it  -> pristine baseline copy,
  #     so adopt the new release wholesale.
  #   - otherwise we cannot prove where the append boundary is -> conflict.
  if [ -n "$prev" ] && [ -f "$prev" ] && cmp -s "$prev" "$consumer"; then
    cp -p "$baseline" "$outfile"; note "pure baseline copy -> adopted new release wholesale"; exit 0
  fi
  note "CONFLICT: consumer '$consumer' has no marker yet and differs from prev; cannot split safely"
  exit 2
fi

# --- stitch: owned release + (blank line separator) + preserved consumer tail ---
{
  printf '%s\n' "$owned"
  printf '\n%s\n' "$tail"
} > "$outfile"
note "merged: owned(baseline) + preserved tail ($(printf '%s' "$tail" | wc -l) lines)"
exit 0