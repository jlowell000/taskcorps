#!/usr/bin/env bash
# validate-team.sh — self-check the baseline's internal consistency.
# Run before any federation release. Exits non-zero on any failure.
# Checks:
#   1. Every skill referenced by an agent/command exists under .opencode/skills/
#   2. Every command's `agent:` frontmatter names a defined agent
#   3. Templates referenced by AGENTS.md exist under .opencode/templates/
#   4. No unfilled $(tbd) placeholders left in seeded .team/context/
#   5. Handoff blocks in templates use the canonical format
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

fail=0
note() { printf '  %s\n' "$*"; }
ok()   { printf '  ok: %s\n' "$*"; }
err()  { printf '  FAIL: %s\n' "$*"; fail=1; }

echo "== 1. Skills referenced by agents/commands exist =="
# Collect backtick-quoted skill names used before the word "skill"
# (e.g. "the `handoff` skill", "use the `testing` skill").
referenced=$(grep -rhoE '`[a-z][a-z-]+` skill' \
  .opencode/agents .opencode/commands 2>/dev/null \
  | sed -E 's/`([a-z][a-z-]+)` skill/\1/' | sort -u)
for s in $referenced; do
  if [ -f ".opencode/skills/$s/SKILL.md" ]; then
    ok "skill '$s'"
  else
    err "skill '$s' referenced but missing (.opencode/skills/$s/SKILL.md)"
  fi
done

echo "== 2. Command agent frontmatter names a defined agent =="
for cmd in .opencode/commands/*.md; do
  agent=$(awk -F': ' '/^agent:/{print $2; exit}' "$cmd")
  [ -z "$agent" ] && { err "$cmd: no agent: frontmatter"; continue; }
  if [ -f ".opencode/agents/$agent.md" ]; then
    ok "$(basename "$cmd") -> $agent"
  else
    err "$(basename "$cmd"): agent '$agent' not defined"
  fi
done

echo "== 3. Templates referenced by AGENTS.md exist =="
for t in brief spec impl report review adr; do
  if [ -f ".opencode/templates/$t.md" ]; then
    ok "template '$t'"
  else
    err "template '$t' missing"
  fi
done

echo "== 4. No unfilled \$(tbd) placeholders in seeded .team/context/ =="
if grep -rqE '\$\(tbd\)' .team/context/ 2>/dev/null; then
  err "unfilled \$(tbd) placeholder(s) in .team/context/"
  grep -rnE '\$\(tbd\)' .team/context/ 2>/dev/null | sed 's/^/    /'
else
  ok "no \$(tbd) placeholders"
fi

echo "== 5. Handoff blocks in stage templates use canonical format =="
# Stage artifacts require a handoff block. adr.md is a context record (no stage gate),
# so it is deliberately excluded.
for t in brief spec impl report review; do
  if grep -q '^---$' ".opencode/templates/$t.md" && grep -q '^\*\*Handoff' ".opencode/templates/$t.md"; then
    ok "template '$t' has a handoff block"
  else
    err "template '$t': missing canonical handoff block (--- + **Handoff)"
  fi
done

echo
if [ "$fail" -eq 0 ]; then
  echo "validate-team: PASS"
  exit 0
else
  echo "validate-team: FAIL ($fail issue(s))"
  exit 1
fi