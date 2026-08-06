#!/usr/bin/env bash
# install-global.sh — sync the current RELEASED baseline snapshot into the machine-global
# opencode scope (~/.config/opencode/), register it as a `type: global` federated host, and
# take its catalog diff-base.
#
# Design notes:
#  - Syncs from `.team/federation/releases/<CURRENT_VERSION>/` (a released snapshot), never from
#    the working tree, so the host ledger tracks released versions — not un-released drift.
#  - Installs only the team files: AGENTS.md, CLAUDE.md, and the flat agents/, commands/,
#    skills/<name>/SKILL.md, templates/. It NEVER touches user-owned global files
#    (opencode.jsonc, .gitignore, package*.json, node_modules/) or the repo's opencode.json.
#  - Idempotent: safe to re-run after every baseline release.
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

GLOBAL="${GLOBAL:-$HOME/.config/opencode}"
HOST="global-$(whoami)-$(hostname)"

fail=0
note() { printf '  %s\n' "$*"; }
err()  { printf '  FAIL: %s\n' "$*"; fail=1; }

# --- resolve the current released version ----------------------------------
CUR=$(sed -n 's/.*CURRENT_VERSION: v\([0-9.]*\).*/\1/p' .team/federation/changelog.md | head -n1)
[ -n "$CUR" ] || { err "could not parse CURRENT_VERSION from .team/federation/changelog.md"; }
REL=".team/federation/releases/v$CUR"
[ -d "$REL" ] || { err "release snapshot missing: $REL"; }
[ "$fail" -eq 0 ] || { echo "install-global: FAIL"; exit 1; }

echo "== install-global: syncing release v$CUR into $GLOBAL (host $HOST) =="

# --- install the team files (never the config set) --------------------------
mkdir -p "$GLOBAL/agents" "$GLOBAL/commands" "$GLOBAL/skills" "$GLOBAL/templates"

installed=0
copy_to() { # src_file dst_dir
  if cp -p "$1" "$2/$(basename "$1")" 2>/dev/null; then
    note "  + $(basename "$1")"; installed=$((installed+1))
  fi
}

# AGENTS.md + CLAUDE.md at the global root
copy_to "$REL/AGENTS.md"   "$GLOBAL"
copy_to "$REL/CLAUDE.md"   "$GLOBAL"

# agents
for f in "$REL"/.opencode/agents/*.md; do [ -e "$f" ] && copy_to "$f" "$GLOBAL/agents"; done
# commands
for f in "$REL"/.opencode/commands/*.md; do [ -e "$f" ] && copy_to "$f" "$GLOBAL/commands"; done
# skills (preserve the <name>/SKILL.md structure)
for d in "$REL"/.opencode/skills/*/; do
  name=$(basename "$d")
  mkdir -p "$GLOBAL/skills/$name"
  [ -e "$d/SKILL.md" ] && copy_to "$d/SKILL.md" "$GLOBAL/skills/$name"
done
# templates
for f in "$REL"/.opencode/templates/*.md; do [ -e "$f" ] && copy_to "$f" "$GLOBAL/templates"; done

echo "  installed $installed team file(s)"

# --- register / refresh the global host ledger ------------------------------
REG=".team/federation/registry.md"
GID="$HOST"
GID_ESC=$(printf '%s' "$GID" | sed 's/[|]/\\|/g')
if grep -q "^| global | $GID_ESC |" "$REG"; then
  sed -i -E "s#^(\| global \| $GID_ESC \| )[^|]*\| v[0-9.]*\|.*#\1 $GLOBAL | v$CUR | —#" "$REG"
  note "  registry: updated host '$GID' -> v$CUR"
else
  printf '| global | %s | %s | v%s | — |\n' "$GID" "$GLOBAL" "$CUR" >> "$REG"
  note "  registry: registered host '$GID' @ v$CUR"
fi

# catalog diff-base (gitignored)
CAT=".team/federation/catalog/$GID/v$CUR"
rm -rf "$CAT"
mkdir -p "$CAT"
cp -p "$REL/AGENTS.md" "$REL/CLAUDE.md" "$CAT/" 2>/dev/null
cp -r "$REL/.opencode" "$CAT/" 2>/dev/null
note "  catalog: wrote snapshot v$CUR ($CAT)"

echo
echo "install-global: done. Restart opencode for the global config to load."
exit "$fail"
