#!/usr/bin/env bash
# migrate-from-federation.sh — remove federation remnants from an existing taskcorps
# installation and install the new team files (release skill, PR capabilities, scripts).
#
#   migrate-from-federation.sh [TARGET_DIR]
#
# If TARGET_DIR is omitted, migrates the current repo (the taskcorps baseline itself).
# For project repos, pass the project root. For global installs, pass ~/.config/opencode
# or ~/.dsh.
#
# This script is idempotent: safe to re-run. It will:
#   1. Remove federation files (.team/federation/, federation commands/agents/skills)
#   2. Strip federation references from surviving team files
#   3. Update AGENTS.md (surgical merge if marker exists, full replace if not)
#   4. Install new files (release skill, PR templates, scripts)
#   5. Seed .team/context/pr-capabilities.md if missing
#
# After running, review the changes and commit them.
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASELINE="$(cd "$SCRIPT_DIR/../.." && pwd)"

TARGET="${1:-$BASELINE}"
[ -d "$TARGET" ] || { echo "migrate: not a directory: $TARGET" >&2; exit 2; }

note() { printf '  %s\n' "$*"; }
err()  { printf '  FAIL: %s\n' "$*"; }
changed=0

mark_changed() { changed=$((changed + 1)); }

# --- helpers ----------------------------------------------------------------
remove_if_exists() { # path
  if [ -e "$1" ]; then
    rm -rf "$1"
    note "  removed: $1"
    mark_changed
  fi
}

remove_if_present() { # path (file only, not dir)
  if [ -f "$1" ]; then
    rm -f "$1"
    note "  removed: $1"
    mark_changed
  fi
}

strip_lines_matching() { # file pattern
  local file="$1" pattern="$2"
  if [ -f "$file" ]; then
    local tmp="${file}.tmp"
    grep -v -E "$pattern" "$file" > "$tmp" 2>/dev/null || true
    if [ -s "$tmp" ]; then
      mv -f "$tmp" "$file"
      note "  stripped federation refs from: $file"
      mark_changed
    else
      rm -f "$tmp"
    fi
  fi
}

# --- 1. Remove federation files ---------------------------------------------
note "== Step 1: removing federation files =="

# Federation directories
remove_if_exists "$TARGET/.team/federation"
remove_if_exists "$TARGET/.team/scripts/drift-check.sh"
remove_if_exists "$TARGET/.team/scripts/sync-origin.sh"
remove_if_exists "$TARGET/.team/scripts/validate-team.sh"

# Federation agents, skills, commands (opencode layout)
remove_if_present "$TARGET/.opencode/agents/federation.md"
remove_if_exists "$TARGET/.opencode/skills/federation"
for f in "$TARGET"/.opencode/commands/federation-*.md; do
  [ -f "$f" ] || continue
  remove_if_present "$f"
done

# Root-level federation files (feed-tracker has these at repo root)
for f in "$TARGET"/federation*.md; do
  [ -f "$f" ] || continue
  remove_if_present "$f"
done

# Global install: clean federation state from .team/
remove_if_exists "$TARGET/.team/federation/releases"
remove_if_exists "$TARGET/.team/federation/catalog"

echo

# --- 2. Strip federation references from surviving files --------------------
note "== Step 2: stripping federation references =="

# pm.md — remove federation: allow from permissions block
if [ -f "$TARGET/.opencode/agents/pm.md" ]; then
  strip_lines_matching "$TARGET/.opencode/agents/pm.md" '^\s*federation:\s*allow\s*$'
  # Also strip any federation-related operating rules if they exist
  strip_lines_matching "$TARGET/.opencode/agents/pm.md" 'federation'
fi

# bootstrap skill — strip federation registration and catalog references
if [ -f "$TARGET/.opencode/skills/bootstrap/SKILL.md" ]; then
  strip_lines_matching "$TARGET/.opencode/skills/bootstrap/SKILL.md" 'federation'
  strip_lines_matching "$TARGET/.opencode/skills/bootstrap/SKILL.md" 'catalog'
  strip_lines_matching "$TARGET/.opencode/skills/bootstrap/SKILL.md" 'baseline\.md'
fi

# handoff skill — strip federation state from description
if [ -f "$TARGET/.opencode/skills/handoff/SKILL.md" ]; then
  strip_lines_matching "$TARGET/.opencode/skills/handoff/SKILL.md" 'federation'
fi

echo

# --- 3. Update AGENTS.md ----------------------------------------------------
note "== Step 3: updating AGENTS.md =="

BASELINE_AGENTS="$BASELINE/AGENTS.md"
TARGET_AGENTS="$TARGET/AGENTS.md"

if [ -f "$BASELINE_AGENTS" ] && [ -f "$TARGET_AGENTS" ]; then
  # Use surgical merge if merge-agents.sh is available
  MERGE_SCRIPT="$TARGET/.team/scripts/merge-agents.sh"
  if [ ! -x "$MERGE_SCRIPT" ] && [ -x "$BASELINE/.team/scripts/merge-agents.sh" ]; then
    MERGE_SCRIPT="$BASELINE/.team/scripts/merge-agents.sh"
  fi

  if [ -x "$MERGE_SCRIPT" ]; then
    TMP_OUT="${TARGET_AGENTS}.migrate.new"
    if "$MERGE_SCRIPT" "$BASELINE_AGENTS" "" "$TARGET_AGENTS" "$TMP_OUT" 2>/dev/null; then
      mv -f "$TMP_OUT" "$TARGET_AGENTS"
      note "  AGENTS.md: surgically merged (local tail preserved)"
      mark_changed
    else
      # Merge failed (conflict or no marker) — overwrite with baseline
      cp -p "$BASELINE_AGENTS" "$TARGET_AGENTS"
      note "  AGENTS.md: merge failed; overwritten with baseline version"
      mark_changed
      rm -f "$TMP_OUT"
    fi
  else
    # No merge script available — full overwrite
    cp -p "$BASELINE_AGENTS" "$TARGET_AGENTS"
    note "  AGENTS.md: overwritten with baseline version (no merge script)"
    mark_changed
  fi
elif [ -f "$BASELINE_AGENTS" ] && [ ! -f "$TARGET_AGENTS" ]; then
  cp -p "$BASELINE_AGENTS" "$TARGET_AGENTS"
  note "  AGENTS.md: copied from baseline"
  mark_changed
else
  err "  AGENTS.md: baseline or target file missing; skipped"
fi

echo

# --- 4. Install new files ---------------------------------------------------
note "== Step 4: installing new team files =="

# Determine target type
TARGET_TYPE=""
if [ -d "$TARGET/.opencode" ]; then
  TARGET_TYPE="opencode"
elif [ -d "$TARGET/.agents" ] || [ -f "$TARGET/.env" ] || [ -f "$TARGET/settings.yaml" ]; then
  TARGET_TYPE="deepseek"
else
  # Default to opencode layout for unknown targets
  TARGET_TYPE="opencode"
fi
note "  target type: $TARGET_TYPE"

# Install scripts (source of truth: .opencode/scripts/)
# Copy to both .opencode/scripts/ (canonical) and .team/scripts/ (runtime compatibility)
mkdir -p "$TARGET/.opencode/scripts" "$TARGET/.team/scripts"
for f in "$BASELINE"/.opencode/scripts/*; do
  [ -e "$f" ] || continue
  cp -p "$f" "$TARGET/.opencode/scripts/"
  cp -p "$f" "$TARGET/.team/scripts/"
  chmod +x "$TARGET/.opencode/scripts/$(basename "$f")" "$TARGET/.team/scripts/$(basename "$f")"
  note "  + .opencode/scripts/$(basename "$f")"
  mark_changed
done

if [ "$TARGET_TYPE" = "opencode" ]; then
  # Install release skill
  mkdir -p "$TARGET/.opencode/skills/release"
  if [ -f "$BASELINE/.opencode/skills/release/SKILL.md" ]; then
    cp -p "$BASELINE/.opencode/skills/release/SKILL.md" "$TARGET/.opencode/skills/release/SKILL.md"
    note "  + .opencode/skills/release/SKILL.md"
    mark_changed
  fi
fi

if [ "$TARGET_TYPE" = "deepseek" ]; then
  # Install release skill into .agents/skills/
  mkdir -p "$TARGET/.agents/skills/release"
  if [ -f "$BASELINE/.opencode/skills/release/SKILL.md" ]; then
    cp -p "$BASELINE/.opencode/skills/release/SKILL.md" "$TARGET/.agents/skills/release/SKILL.md"
    note "  + .agents/skills/release/SKILL.md"
    mark_changed
  fi
fi

# Seed PR capabilities if missing
if [ ! -f "$TARGET/.team/context/pr-capabilities.md" ]; then
  mkdir -p "$TARGET/.team/context"
  if [ -f "$BASELINE/.opencode/templates/pr-capabilities.md" ]; then
    cp -p "$BASELINE/.opencode/templates/pr-capabilities.md" "$TARGET/.team/context/pr-capabilities.md"
    note "  + .team/context/pr-capabilities.md (fill in with project facts)"
    mark_changed
  fi
else
  note "  ~ .team/context/pr-capabilities.md (exists, skipped)"
fi

# If PR capabilities show not enabled, copy the setup doc
if [ -f "$TARGET/.team/context/pr-capabilities.md" ]; then
  if ! grep -q 'Enabled: yes' "$TARGET/.team/context/pr-capabilities.md" 2>/dev/null; then
    if [ -f "$BASELINE/.opencode/templates/enable-pr-setup.md" ]; then
      cp -p "$BASELINE/.opencode/templates/enable-pr-setup.md" "$TARGET/.team/context/enable-pr-setup.md"
      note "  + .team/context/enable-pr-setup.md (PR not enabled; see this file to enable)"
      mark_changed
    fi
  fi
fi

echo

# --- 5. Seed .team/ skeleton if needed --------------------------------------
note "== Step 5: seeding .team/ skeleton =="

if [ ! -f "$TARGET/.team/scripts/init-project.sh" ]; then
  cp -p "$BASELINE/.opencode/scripts/init-project.sh" "$TARGET/.team/scripts/"
  chmod +x "$TARGET/.team/scripts/init-project.sh"
  note "  + .team/scripts/init-project.sh"
  mark_changed
fi

# Ensure .team/ subdirs exist
for d in context/adrs tasks checkpoints archive proposals scripts; do
  mkdir -p "$TARGET/.team/$d"
done

# Create backlog.md and status.md if missing
if [ ! -f "$TARGET/.team/backlog.md" ]; then
  cat > "$TARGET/.team/backlog.md" <<'EOF'
# Backlog

pm-owned. No active run.

| Id | Title | Size | Depends on | Status | Owner |
| --- | --- | --- | --- | --- | --- |
| (empty) | — | — | — | — | — |

## Open / parked

(none)
EOF
  note "  + .team/backlog.md"
  mark_changed
fi

if [ ! -f "$TARGET/.team/status.md" ]; then
  cat > "$TARGET/.team/status.md" <<'EOF'
# Status

Live "who owns what / stage" board.

 | Task | Stage | Owner | Next | Notes |
 | --- | --- | --- | --- | --- |
 | (none) | — | — | — | — |

## Open / parked

(none)
EOF
  note "  + .team/status.md"
  mark_changed
fi

echo

# --- 6. Report --------------------------------------------------------------
echo "== migrate-from-federation: complete =="
echo "  Changed: $changed item(s)"
echo
echo "  Next steps:"
echo "    1. Review the changes (git diff or git status)"
echo "    2. Commit: git add -A && git commit -m 'migrate: remove federation, add release skill'"
echo "    3. If PR creation is enabled in .team/context/pr-capabilities.md, run /release"
echo "       to push approved retro proposals."
echo "    4. If PR creation is not enabled, see .team/context/enable-pr-setup.md"
echo
echo "  Targets migrated: $TARGET"
echo "  Target type: $TARGET_TYPE"
