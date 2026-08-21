#!/usr/bin/env bash
# install-global.sh — install the taskcorps team files into one or more tool config directories.
#
# Targets (discovered automatically, user picks which to install into):
#   Opencode global:   ~/.config/opencode/
#   Deepseek global:   ~/.dsh/
#   Opencode projects: ~/Projects/*/.opencode/
#   Deepseek projects: ~/Projects/*/.agents/
#
# Flags:
#   --all            install into all discovered targets (non-interactive)
#   --target TYPE|PATH  install into a single target (repeatable)
#   --targets-file FILE  read newline-delimited TYPE|PATH targets from FILE
#   --dry-run        print what would be done without writing
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
#  - Adapter-based: canonical files (.opencode/agents/*.md) have tool-agnostic frontmatter.
#    Adapters inject tool-specific fields during install via manifest-driven discovery.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
cd "$ROOT"

# --- args ---------------------------------------------------------------------
usage() {
  echo "Usage: install-global.sh [--all] [--target TYPE|PATH]... [--targets-file FILE] [--dry-run]"
  exit 1
}

ALL_MODE=0
DRY_RUN=0
declare -a TARGET_ARGS=()
TARGETS_FILE=""

while [ $# -gt 0 ]; do
  case "$1" in
    --all)          ALL_MODE=1; shift ;;
    --target)       TARGET_ARGS+=("$2"); shift 2 ;;
    --targets-file) TARGETS_FILE="$2"; shift 2 ;;
    --dry-run)      DRY_RUN=1; shift ;;
    *)              usage ;;
  esac
done

if [ "$ALL_MODE" -eq 1 ] && [ "${#TARGET_ARGS[@]}" -gt 0 ]; then
  echo "Cannot combine --all with --target." >&2
  usage
fi

if [ -n "$TARGETS_FILE" ] && [ "${#TARGET_ARGS[@]}" -gt 0 ]; then
  echo "Cannot combine --targets-file with --target." >&2
  usage
fi

# --- helpers ------------------------------------------------------------------
note() { printf '  %s\n' "$*"; }
err()  { printf '  FAIL: %s\n' "$*" >&2; return 1; }

copy_file() { # src dst
  cp -p "$1" "$2"
  note "  + $(basename "$2")"
}

copy_flat() { # src_dir dst_dir
  # Flat copy — does NOT recurse into subdirs of src.
  mkdir -p "$2"
  local src="$1" dst="$2"
  for f in "$src"/*; do
    [ -e "$f" ] || continue
    cp -p "$f" "$dst/"
  done
  note "  + flat copy → $(basename "$dst")/"
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
  local rc=0
  "$script" "$baseline" "" "$consumer" "$outfile" || rc=$?
  if [ "$rc" -eq 0 ]; then
    return 0
  elif [ "$rc" -eq 2 ]; then
    # Conflict: consumer has custom content that can't be split safely.
    # Write baseline to .md.new as a fallback so the human can reconcile.
    err "merge conflict in $consumer (exit 2); wrote baseline to ${outfile}.new"
    cp -p "$baseline" "${outfile}.new"
    return 2
  else
    err "could not auto-merge $consumer (exit $rc)"
    return 1
  fi
}

# --- adapters -----------------------------------------------------------------
# Canonical agent files have tool-agnostic frontmatter. Adapters inject tool-specific
# fields during install. Adapters are discovered from .opencode/scripts/adapters/*/
# directories containing manifest.yaml.

check_python() {
  if command -v python3 >/dev/null 2>&1; then
    echo "python3"
  elif command -v python >/dev/null 2>&1; then
    echo "python"
  else
    echo ""
  fi
}

run_adapter() { # adapter_name source target agents_md
  local adapter_name="$1"
  local source="$2"
  local target="$3"
  local agents_md="$4"
  local adapter_dir="$ROOT/.opencode/scripts/adapters/$adapter_name"
  local adapter_script="$adapter_dir/run.py"
  local python_cmd

  python_cmd=$(check_python)
  if [ -z "$python_cmd" ]; then
    err "Python not found; cannot run adapter $adapter_name"
    return 1
  fi

  if [ ! -f "$adapter_script" ]; then
    note "  Adapter $adapter_name not found (missing run.py), skipping"
    return 0
  fi

  if [ ! -f "$adapter_dir/manifest.yaml" ]; then
    note "  Adapter $adapter_name missing manifest.yaml, skipping"
    return 0
  fi

  "$python_cmd" "$adapter_script" "$source" "$target" "$agents_md"
}

# Run adapters pre-filtered by discover.py for the given target type
run_adapters_for_target() { # target_type source_dir target_dir agents_md
  local target_type="$1"
  local source_dir="$2"
  local target_dir="$3"
  local agents_md="$4"
  local python_cmd
  local adapter_name

  python_cmd=$(check_python)
  if [ -z "$python_cmd" ]; then
    note "  Python not found; skipping adapter-based transforms"
    return 0
  fi

  # Discover adapters filtered by target type (filtering moved into discover.py)
  local adapters_list
  adapters_list=$("$python_cmd" "$ROOT/.opencode/scripts/adapters/discover.py" --target-type "$target_type")

  while IFS='|' read -r adapter_name priority generates_types; do
    [ -z "$adapter_name" ] && continue

    note "  Running adapter: $adapter_name"
    if ! run_adapter "$adapter_name" "$source_dir" "$target_dir" "$agents_md"; then
      err "  Adapter $adapter_name failed"
      return 1
    fi
  done <<< "$adapters_list"
}

# --- install into an opencode target ------------------------------------------
install_opencode() { # target_dir
  local target="$1"

  # Skip if target is the baseline itself (already has these files)
  if [ "$target" = "$ROOT" ] || [ "$target" = "$ROOT/.opencode" ]; then
    note "== Skipping opencode target: $target (is baseline) =="
    return 0
  fi

  note "== Installing into opencode target: $target =="

  # Create target subdirs
  mkdir -p "$target/agents" "$target/commands" "$target/skills" "$target/templates"

  # AGENTS.md — surgical merge (preserve local tail below marker)
  if [ -f "$target/AGENTS.md" ]; then
    if merge_agents "$ROOT/AGENTS.md" "$target/AGENTS.md" "$target/AGENTS.md"; then
      note "  AGENTS.md: surgically merged (local tail preserved)"
    else
      rc=$?
      if [ "$rc" -eq 2 ]; then
        note "  AGENTS.md: merge conflict; baseline saved to AGENTS.md.new (original untouched)"
      else
        err "  AGENTS.md: merge failed (exit $rc)"
        return 1
      fi
    fi
  else
    copy_file "$ROOT/AGENTS.md" "$target/AGENTS.md"
  fi

  # CLAUDE.md — copy if we have one (baseline may not, depending on setup)
  [ -f "$ROOT/CLAUDE.md" ] && copy_file "$ROOT/CLAUDE.md" "$target/CLAUDE.md"

  # agents, commands, skills, templates — flat copy (canonical, tool-agnostic)
  copy_flat "$ROOT/.opencode/agents"   "$target/agents"
  copy_flat "$ROOT/.opencode/commands" "$target/commands"
  copy_flat "$ROOT/.opencode/templates" "$target/templates"
  copy_flat "$ROOT/.opencode/scripts"  "$target/scripts"

  # skills — preserve <name>/SKILL.md structure
  for d in "$ROOT"/.opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name
    name=$(basename "$d")
    mkdir -p "$target/skills/$name"
    [ -e "$d/SKILL.md" ] && copy_file "$d/SKILL.md" "$target/skills/$name/SKILL.md"
  done

  # Run adapters for this target
  run_adapters_for_target "opencode" "$ROOT/.opencode" "$target" "$ROOT/AGENTS.md" || return 1
}

# --- install into a deepseek target ------------------------------------------
install_deepseek() { # target_dir
  local target="$1"

  # Skip if target is the baseline itself (already has these files)
  if [ "$target" = "$ROOT" ]; then
    note "== Skipping deepseek target: $target (is baseline) =="
    return 0
  fi

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
  copy_flat "$ROOT/.opencode/agents" "$target/.agents/notes/agents"

  # Run adapters for this target
  run_adapters_for_target "deepseek" "$ROOT" "$target" "$ROOT/AGENTS.md" || return 1

  # commands → .agents/notes/commands/<name>.md
  copy_flat "$ROOT/.opencode/commands" "$target/.agents/notes/commands"

  # templates → .agents/notes/templates/<name>.md
  copy_flat "$ROOT/.opencode/templates" "$target/.agents/notes/templates"

  # skills → .agents/skills/<name>/SKILL.md (alongside existing dsh-* skills)
  for d in "$ROOT"/.opencode/skills/*/; do
    [ -e "$d" ] || continue
    local name
    name=$(basename "$d")
    mkdir -p "$target/.agents/skills/$name"
    [ -e "$d/SKILL.md" ] && copy_file "$d/SKILL.md" "$target/.agents/skills/$name/SKILL.md"
  done
}

# --- user-owned file excludes (never overwrite) -------------------------------
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

# --- target discovery ---------------------------------------------------------
declare -a TARGETS=()   # "type|path"
declare -a LABELS=()    # human-readable label per target

add_target() { # type path label
  TARGETS+=("$1|$2")
  LABELS+=("$3")
}

discover_targets() {
  # Opencode global
  if [ -d "$HOME/.config/opencode" ]; then
    add_target "opencode" "$HOME/.config/opencode" "Opencode global (~/.config/opencode/)"
  fi

  # Deepseek global
  if [ -d "$HOME/.dsh" ]; then
    add_target "deepseek" "$HOME/.dsh" "Deepseek global (~/.dsh/)"
  fi

  # Opencode project-local
  for d in "$HOME"/Projects/*/.opencode; do
    [ -d "$d" ] || continue
    # Skip the baseline itself
    [ "$(cd "$d" && pwd)" = "$ROOT" ] && continue
    local project
    project=$(basename "$(dirname "$d")")
    add_target "opencode" "$d" "Opencode project ($project)"
  done

  # Deepseek project-local
  for d in "$HOME"/Projects/*/.agents; do
    [ -d "$d" ] || continue
    # Skip the baseline itself
    [ "$(cd "$d" && pwd)" = "$ROOT" ] && continue
    local project
    project=$(basename "$(dirname "$d")")
    add_target "deepseek" "$d" "Deepseek project ($project)"
  done
}

load_targets_from_file() { # file
  local file="$1"
  [ -f "$file" ] || { err "targets-file not found: $file"; return 1; }
  while IFS='|' read -r type path; do
    # skip blanks and comments
    [ -z "$type" ] && continue
    case "$type" in
      \#*) continue ;;
    esac
    # trim whitespace
    type=$(echo "$type" | xargs)
    path=$(echo "$path" | xargs)
    case "$type" in
      opencode|deepseek) ;;
      *) err "invalid target type in targets-file: $type"; return 1 ;;
    esac
    [ -d "$path" ] || { err "target path not a directory: $path"; return 1; }
    add_target "$type" "$path" "$type @ $path"
  done < "$file"
}

# If explicit targets provided via --target, use them directly (skip discovery)
if [ "${#TARGET_ARGS[@]}" -gt 0 ]; then
  for t in "${TARGET_ARGS[@]}"; do
    IFS='|' read -r type path <<< "$t"
    case "$type" in
      opencode|deepseek) ;;
      *) err "invalid --target type: $type (expected opencode or deepseek)"; exit 1 ;;
    esac
    [ -d "$path" ] || { err "target path not a directory: $path"; exit 1; }
    add_target "$type" "$path" "$type @ $path"
  done
elif [ -n "$TARGETS_FILE" ]; then
  load_targets_from_file "$TARGETS_FILE"
else
  discover_targets
fi

if [ "${#TARGETS[@]}" -eq 0 ]; then
  echo "== install-global: no targets found =="
  echo "  Expected directories:"
  echo "    ~/.config/opencode/  (opencode global)"
  echo "    ~/.dsh/              (deepseek global)"
  echo "    ~/Projects/<name>/.opencode/  (opencode project)"
  echo "    ~/Projects/<name>/.agents/    (deepseek project)"
  echo "  Or use --targets-file FILE with newline-delimited TYPE|PATH entries."
  echo "  Nothing to do."
  exit 0
fi

# --- select targets -----------------------------------------------------------
SELECTED=()

if [ "$ALL_MODE" -eq 1 ]; then
  SELECTED=("${!TARGETS[@]}")
elif [ "${#TARGET_ARGS[@]}" -gt 0 ] || [ -n "$TARGETS_FILE" ]; then
  # Explicit targets were already loaded; select them all
  SELECTED=("${!TARGETS[@]}")
elif [ "$DRY_RUN" -eq 1 ]; then
  # Dry-run still needs selection; default to all for convenience
  SELECTED=("${!TARGETS[@]}")
else
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
fi

# --- install ------------------------------------------------------------------
if [ "$DRY_RUN" -eq 1 ]; then
  echo "== install-global: dry-run — would install into ${#SELECTED[@]} target(s) =="
  for idx in "${SELECTED[@]}"; do
    echo "  ${LABELS[$idx]}"
  done
  exit 0
fi

fail=0
for idx in "${SELECTED[@]}"; do
  IFS='|' read -r type path <<< "${TARGETS[$idx]}"
  case "$type" in
    opencode)
      if ! install_opencode "$path"; then
        err "install_opencode failed for $path"
        fail=1
      fi
      ;;
    deepseek)
      if ! install_deepseek "$path"; then
        err "install_deepseek failed for $path"
        fail=1
      fi
      ;;
    *) err "unknown target type: $type"; fail=1 ;;
  esac
done

echo
if [ "$fail" -eq 0 ]; then
  echo "install-global: done. Restart your coding tool for changes to load."
else
  echo "install-global: completed with errors (see above)."
fi
exit "$fail"
