#!/usr/bin/env bash
# init-project.sh — lightweight project initialization: seed .team/ skeleton and update
# .gitignore. Does NOT copy team files or run discovery (use /scrum-init for that).
#
#   init-project.sh [TARGET_DIR]
#
# Idempotent: safe to re-run; existing files are preserved (won't overwrite).
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

TARGET="${1:-.}"
[ -d "$TARGET" ] || { echo "init-project: not a directory: $TARGET" >&2; exit 2; }

note() { printf '  %s\n' "$*"; }

TEAM="$TARGET/.team"

# --- seed .team/ skeleton ---------------------------------------------------
mkdir -p "$TEAM/context/adrs" \
         "$TEAM/tasks" \
         "$TEAM/checkpoints" \
         "$TEAM/archive" \
         "$TEAM/proposals" \
         "$TEAM/scripts"

# Copy skeleton files from templates if they don't already exist
for f in "$ROOT"/.opencode/templates/*.md; do
  [ -e "$f" ] || continue
  local name
  name=$(basename "$f")
  case "$name" in
    brief.md)   dest="$TEAM/tasks/EXAMPLE.md" ;;
    spec.md)    dest="$TEAM/context/spec-example.md" ;;
    *)          dest="$TEAM/$name" ;;
  esac
  if [ ! -f "$dest" ]; then
    cp -p "$f" "$dest"
    note "  + .team/$(basename "$dest")"
  else
    note "  ~ .team/$(basename "$dest") (exists, skipped)"
  fi
done

# Create backlog.md and status.md if missing
if [ ! -f "$TEAM/backlog.md" ]; then
  cat > "$TEAM/backlog.md" <<'EOF'
# Backlog

pm-owned. No active run.

| Id | Title | Size | Depends on | Status | Owner |
| --- | --- | --- | --- | --- | --- |
| (empty) | — | — | — | — | — |

## Open / parked

(none)
EOF
  note "  + .team/backlog.md"
fi

if [ ! -f "$TEAM/status.md" ]; then
  cat > "$TEAM/status.md" <<'EOF'
# Status

Live "who owns what / stage" board.

 | Task | Stage | Owner | Next | Notes |
 | --- | --- | --- | --- | --- |
 | (none) | — | — | — | — |

## Open / parked

(none)
EOF
  note "  + .team/status.md"
fi

# Seed context files if missing
if [ ! -f "$TEAM/context/stack.md" ]; then
  cat > "$TEAM/context/stack.md" <<'EOF'
# Stack (discovery snapshot)

designer-owned. Populated by `scrum-init` bootstrap from the real project — never invent facts.

## Project

- Working type: <application / library / baseline team definition>
- Language(s): <languages>

## Toolchain

- Package manager: <npm / pnpm / pip / cargo / go / etc., or n/a>
- Build command: <command, or n/a>
- Runtime: <runtime, or n/a>

## Repo

- Git: <initialized / not a git repo>
- Default branch: <detected or n/a>
- CI: <CI system, or none discovered>

## Notes

- <anything the team should know>
EOF
  note "  + .team/context/stack.md"
fi

if [ ! -f "$TEAM/context/test-harness.md" ]; then
  cat > "$TEAM/context/test-harness.md" <<'EOF'
# Test Harness

designer-owned. What "green" means for this project.

## Commands

- Run all:   <test command>
- Run one:   <test command with filter>
- Coverage:  <coverage command, or n/a>

## Baseline run at init

> Not yet discovered.

## Notes

- <anything unusual about the test setup>
EOF
  note "  + .team/context/test-harness.md"
fi

# --- copy team scripts ------------------------------------------------------
# Scripts are versioned in .opencode/scripts/ (the source of truth). Copy them to
# .team/scripts/ at runtime so agents can find them via the .team/ path.
mkdir -p "$TEAM/scripts"
for f in "$ROOT"/.opencode/scripts/*; do
  [ -e "$f" ] || continue
  cp -p "$f" "$TEAM/scripts/"
  note "  + .team/scripts/$(basename "$f")"
done

# --- update .gitignore ------------------------------------------------------
GITIGNORE="$TARGET/.gitignore"
[ -f "$GITIGNORE" ] || touch "$GITIGNORE"

# Add .team/ block if missing
if ! grep -qF '# Taskcorps runtime workspace' "$GITIGNORE" 2>/dev/null; then
  cat >> "$GITIGNORE" <<'EOF'

# Taskcorps runtime workspace — NOT tracked
.team/
EOF
  note "  + .gitignore: added .team/"
else
  note "  ~ .gitignore: .team/ already present"
fi

echo
echo "init-project: done. .team/ skeleton ready at $TEAM"
echo "  Next: run /scrum-init to copy team files and discover the project."
