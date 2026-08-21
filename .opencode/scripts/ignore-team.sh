#!/usr/bin/env bash
# ignore-team.sh — add (or remove) git-ignore rules for the scrum team's agent files in a
# target project's .gitignore.
#
#   ignore-team.sh [--track] [--ignore] [--dry] [TARGET_DIR]
#
# The scrum team installs these files into a project:
#   AGENTS.md  CLAUDE.md  opencode.json  .opencode/
# In a NON-baseline repo these are usually tooling the project's remote doesn't want
# committed, so the default is to git-ignore them. In the baseline repo itself they ARE
# tracked (they are the source of truth). This script makes that choice explicit and
# reversible.
#
# Modes:
#   --ignore  (default) append ignore rules so the agent files are NOT committed.
#   --track   remove those ignore rules so the agent files ARE committed.
#   --target DIR   operate on DIR/.gitignore (default: current directory).
#
# Idempotent: safe to re-run; never duplicates rules; never touches .team/ rules.
set -u

TARGET="."
MODE="ignore"
for a in "$@"; do
  case "$a" in
    --ignore) MODE="ignore";;
    --track)  MODE="track";;
    --target) TARGET="";; # handled below (expects next arg)
    -*) echo "ignore-team: unknown arg '$a'" >&2; exit 2;;
    *) [ -z "$TARGET" ] && TARGET="$a" || TARGET="$a";;
  esac
done
[ -n "$TARGET" ] || { echo "ignore-team: --target requires a directory" >&2; exit 2; }

GITIGNORE="$TARGET/.gitignore"
[ -d "$TARGET" ] || { echo "ignore-team: not a directory: $TARGET" >&2; exit 2; }
[ -f "$GITIGNORE" ] || touch "$GITIGNORE"

BLOCK_HEADER="# Taskcorps agent files — NOT tracked (tooling; remotes may not want them)"
BLOCK_BODY='AGENTS.md
CLAUDE.md
opencode.json
.opencode/'

# --- remove any existing block (idempotent re-add) ---------------------------
awk -v hdr="$BLOCK_HEADER" '
  $0 == hdr { skip=1; next }
  skip && /^\.opencode\/$/ { skip=0; next }
  !skip { print }
' "$GITIGNORE" > "$GITIGNORE.tmp" && mv "$GITIGNORE.tmp" "$GITIGNORE"

if [ "$MODE" = "ignore" ]; then
  printf '\n%s\n%s\n' "$BLOCK_HEADER" "$BLOCK_BODY" >> "$GITIGNORE"
  echo "ignore-team: agent files will NOT be committed ($TARGET)"
else
  echo "ignore-team: agent files will be committed ($TARGET)"
fi
exit 0