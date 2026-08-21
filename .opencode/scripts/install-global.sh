#!/usr/bin/env bash
# install-global.sh — install the taskcorps team files into one or more tool config directories.
#
# Targets (discovered automatically, user picks which to install into):
#   Opencode global:   ~/.config/opencode/
#   Deepseek global:   ~/.dsh/
#   Opencode projects: ~/Projects/*/.opencode/
#   Deepseek projects: ~/Projects/*/.agents/
#
# Design notes:
#  - Source is the taskcorps working tree (.opencode/ + AGENTS.md + CLAUDE.md), never a
#    release snapshot — there is no versioning in the new model.
#  - Opencode targets get the full team: agents/, commands/, skills/, templates/ copied
#    into the target's .opencode/ subdirs; AGENTS.md is surgically merged (local tail
#    preserved below the marker); CLAUDE.md is copied.
#  - Deepseek targets get team files mapped into .agents/ subdirs as reference docs;
#    the harness's own root AGENTS.md is never touched.
#  - User-owned config files are NEVER overwritten: opencode.json[c], .gitignore,
#    package*.json, node_modules/ for opencode; .env, settings.yaml, .credentials.yaml,
#    cordis.patch.yml, profiles/, sessions/, storages/ for deepseek.
#  - Idempotent: safe to re-run; existing files are overwritten (that's the point), but
#    user-owned excludes are preserved.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# --- helpers ----------------------------------------------------------------
note() { printf '  %s\n' "$*"; }
err()  { printf '  FAIL: %s\n' "$*"; return 1; }

copy_file() { # src dst
  if cp -p "$1" "$2" 2>/dev/null; then
    note "  + $(basename "$2")"
    return 0
  else
    err "  failed to copy $(basename "$1") to $2"
    return 1
  fi
}

copy_tree() { # src_dir dst_dir
  # Copies all files from src_dir into dst_dir, creating dst_dir if needed.
  # Does NOT recurse into subdirectories of src_dir (flat copy).
  mkdir -p "$2"
  local src="$1" dst="$2" count=0
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    if cp -p "$f" "$dst/"; then
      count=$((count + 1))
    fi
  done
  note "  + $count file(s) → $(basename "$dst")/"
}

# Surgical AGENTS.md merge: replace baseline-owned content above the marker,
# preserve the consumer's local tail below it. Uses merge-agents.sh.
merge_agents() { # baseline_agents_md consumer_agents_md outfile
  local baseline="$1" consumer="$2" outfile="$3"
  local script="$ROOT/.opencode/scripts/merge-agents.sh"
  if [ ! -x "$script" ]; then
    err "merge-agents.sh not found or not executable at $script"
    return 1
  fi
  if "$script" "$baseline" "" "$consumer" "$outfile"; then
    return 0
  else
    err "could not auto-merge $consumer; conflict pair left in place"
    return 1
  fi
}

# --- install into an opencode target -----------------------------------------
install_opencode() { # target_dir
  local target="$1"
  note "== Installing into opencode target: $target =="

  # Create target subdirs
  mkdir -p "$target/agents" "$target/commands" "$target/skills" "$target/templates"

  # AGENTS.md — surgical merge (preserve local tail below marker)
  if [ -f "$target/AGENTS.md" ]; then
    if merge_agents "$ROOT/AGENTS.md" "$target/AGENTS.md" "$target/AGENTS.md.new"; then
      mv -f "$target/AGENTS.md.new" "$target/AGENTS.md"
      note "  AGENTS.md: surgically merged (local tail preserved)"
    else
      cp -p "$ROOT/AGENTS.md" "$target/AGENTS.md.new"
      note "  AGENTS.md: merge failed; wrote release to AGENTS.md.new (original untouched)"
    fi
  else
    copy_file "$ROOT/AGENTS.md" "$target/AGENTS.md"
  fi

  # CLAUDE.md — copy if we have one (baseline may not, depending on setup)
  [ -f "$ROOT/CLAUDE.md" ] && copy_file "$ROOT/CLAUDE.md" "$target/CLAUDE.md"

  # agents, commands, skills, templates — flat copy
  copy_tree "$ROOT/.opencode/agents"   "$target/agents"
  copy_tree "$ROOT/.opencode/commands" "$target/commands"
  copy_tree "$ROOT/.opencode/templates" "$target/templates"
  copy_tree "$ROOT/.opencode/scripts"  "$target/scripts"

  # skills — preserve <name>/SKILL.md structure
  for d in "$ROOT"/.opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name
    name=$(basename "$d")
    mkdir -p "$target/skills/$name"
    [ -e "$d/SKILL.md" ] && copy_file "$d/SKILL.md" "$target/skills/$name/SKILL.md"
  done
}

# --- install into a deepseek target ------------------------------------------
install_deepseek() { # target_dir
  local target="$1"
  note "== Installing into deepseek target: $target =="

  # Create target subdirs (new layout for taskcorps reference docs)
  mkdir -p "$target/.agents/notes/agents" \
           "$target/.agents/notes/commands" \
           "$target/.agents/notes/templates"

  # AGENTS.md — do NOT touch the harness's own root standing orders.
  # The deepseek harness reads AGENTS.md as its own instructions; overwriting it
  # with taskcorps content would break the harness. Instead, install taskcorps
  # AGENTS.md as a reference doc the agent can discover.
  if [ -f "$ROOT/AGENTS.md" ]; then
    copy_file "$ROOT/AGENTS.md" "$target/.agents/notes/taskcorps-AGENTS.md"
    note "  AGENTS.md: installed as .agents/notes/taskcorps-AGENTS.md (root AGENTS.md untouched)"
  fi

  [ -f "$ROOT/CLAUDE.md" ] && \
    copy_file "$ROOT/CLAUDE.md" "$target/.agents/notes/taskcorps-CLAUDE.md"

  # agents → .agents/notes/agents/<role>.md
  copy_tree "$ROOT/.opencode/agents" "$target/.agents/notes/agents"

  # commands → .agents/notes/commands/<name>.md
  copy_tree "$ROOT/.opencode/commands" "$target/.agents/notes/commands"

  # templates → .agents/notes/templates/<name>.md
  copy_tree "$ROOT/.opencode/templates" "$target/.agents/notes/templates"

  # skills → .agents/skills/<name>/SKILL.md (alongside existing dsh-* skills)
  for d in "$ROOT"/.opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name
    name=$(basename "$d")
    mkdir -p "$target/.agents/skills/$name"
    [ -e "$d/SKILL.md" ] && copy_file "$d/SKILL.md" "$target/.agents/skills/$name/SKILL.md"
  done
}

# --- user-owned file excludes (never overwrite) ------------------------------
is_user_owned_opencode() { # path
  case "$(basename "$1")" in
    opencode.json|opencode.jsonc|.gitignore|package.json|package-lock.json|bun.lock) return 0 ;;
  esac
  case "$1" in
    */node_modules/*) return 0 ;;
  esac
  return 1
}

is_user_owned_deepseek() { # path
  case "$(basename "$1")" in
    .env|settings.yaml|.credentials.yaml|cordis.patch.yml) return 0 ;;
  esac
  case "$1" in
    */profiles/*|*/sessions/*|*/storages/*) return 0 ;;
  esac
  return 1
}

# --- discover targets -------------------------------------------------------
declare -a TARGETS=()   # "type|path"
declare -a LABELS=()    # human-readable label per target

# Opencode global
if [ -d "$HOME/.config/opencode" ]; then
  TARGETS+=("opencode|$HOME/.config/opencode")
  LABELS+=("Opencode global (~/.config/opencode/)")
fi

# Deepseek global
if [ -d "$HOME/.dsh" ]; then
  TARGETS+=("deepseek|$HOME/.dsh")
  LABELS+=("Deepseek global (~/.dsh/)")
fi

# Opencode project-local
for d in "$HOME"/Projects/*/.opencode; do
  [ -d "$d" ] || continue
  local project
  project=$(basename "$(dirname "$d")")
  TARGETS+=("opencode|$d")
  LABELS+=("Opencode project ($project)")
done

# Deepseek project-local
for d in "$HOME"/Projects/*/.agents; do
  [ -d "$d" ] || continue
  local project
  project=$(basename "$(dirname "$d")")
  TARGETS+=("deepseek|$d")
  LABELS+=("Deepseek project ($project)")
done

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "== install-global: no targets found =="
  echo "  Expected directories:"
  echo "    ~/.config/opencode/  (opencode global)"
  echo "    ~/.dsh/              (deepseek global)"
  echo "    ~/Projects/<name>/.opencode/  (opencode project)"
  echo "    ~/Projects/<name>/.agents/    (deepseek project)"
  echo "  Nothing to do."
  exit 0
fi

# --- prompt for selection ---------------------------------------------------
echo "== install-global: discovered ${#TARGETS[@]} target(s) =="
for i in "${!LABELS[@]}"; do
  printf '  [%d] %s\n' "$((i + 1))" "${LABELS[$i]}"
done
printf '  [a] all\n'
printf '  [q] quit\n'
echo

read -rp "Install into which? (comma-separated indices, 'a' for all, or 'q' to quit): " choice

case "$choice" in
  q|Q) echo "Aborted."; exit 0 ;;
  a|A) SELECTED=("${!TARGETS[@]}") ;;
  *)    # Parse comma-separated indices
    SELECTED=()
    IFS=',' read -ra PARTS <<< "$choice"
    for p in "${PARTS[@]}"; do
      p=$(echo "$p" | tr -d ' ')
      if [[ "$p" =~ ^[0-9]+$ ]] && [ "$p" -ge 1 ] && [ "$p" -le "${#TARGETS[@]}" ]; then
        SELECTED+=("$((p - 1))")
      else
        echo "Invalid selection: $p (expected 1-${#TARGETS[@]})"
        exit 1
      fi
    done
    [ "${#SELECTED[@]}" -gt 0 ] || { echo "No valid selections."; exit 1; }
    ;;
esac

# --- install ---------------------------------------------------------------
fail=0
for idx in "${SELECTED[@]}"; do
  IFS='|' read -r type path <<< "${TARGETS[$idx]}"
  case "$type" in
    opencode) install_opencode "$path" || fail=1 ;;
    deepseek) install_deepseek "$path" || fail=1 ;;
    *)        err "unknown target type: $type"; fail=1 ;;
  esac
done

echo
if [ "$fail" -eq 0 ]; then
  echo "install-global: done. Restart your coding tool for changes to load."
else
  echo "install-global: completed with errors (see above)."
fi
exit "$fail"
