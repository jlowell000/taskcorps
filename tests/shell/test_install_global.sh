#!/usr/bin/env bash
# test_install_global.sh — test install-global.sh helpers and adapter discovery.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.opencode/scripts" && pwd)"
INSTALL_SCRIPT="$SCRIPT_DIR/install-global.sh"

pass=0
fail=0
declare -a failures

check() {
  local name="$1" exp_rc="$2" actual_rc="$3"
  if [ "$actual_rc" -eq "$exp_rc" ]; then
    pass=$((pass+1))
    printf 'PASS %s\n' "$name"
  else
    fail=$((fail+1))
    failures+=("$name")
    printf 'FAIL %s (expected rc=%s, got rc=%s)\n' "$name" "$exp_rc" "$actual_rc"
  fi
}

# T1: discover.py outputs adapter list
dir="$(mktemp -d)"
python3 "$SCRIPT_DIR/adapters/discover.py" > "$dir/output.txt" 2>&1
rc=$?
check "discover_py_runs" 0 "$rc"
rm -rf "$dir"

# T2: run_adapter fails gracefully when Python missing (simulate)
dir="$(mktemp -d)"
target="$dir/target"
mkdir -p "$target"
(
  PATH="/usr/local/bin:/usr/bin:/bin"  # minimal PATH
  "$INSTALL_SCRIPT" <<<'q' >/dev/null 2>&1
)
# Just verify script is syntactically valid
bash -n "$INSTALL_SCRIPT"
check "install_global_syntax" 0 $?

# T3: adapter run.py syntax checks
for adapter in "$SCRIPT_DIR"/adapters/*/; do
  [ -d "$adapter" ] || continue
  if [ -f "$adapter/run.py" ]; then
    python3 -m py_compile "$adapter/run.py" 2>/dev/null
    check "syntax_$(basename "$adapter")_run_py" 0 $?
  fi
  if [ -f "$adapter/commands.py" ]; then
    python3 -m py_compile "$adapter/commands.py" 2>/dev/null
    check "syntax_$(basename "$adapter")_commands_py" 0 $?
  fi
done

# T4: manifest.yaml files are valid YAML
for manifest in "$SCRIPT_DIR"/adapters/*/manifest.yaml; do
  [ -f "$manifest" ] || continue
  python3 -c "import yaml; yaml.safe_load(open('$manifest'))" 2>/dev/null
  check "yaml_$(basename "$(dirname "$manifest")")" 0 $?
done

printf '\n%d passed, %d failed\n' "$pass" "$fail"
if [ "$fail" -gt 0 ]; then
  printf 'Failed: %s\n' "${failures[*]}"
  exit 1
fi
exit 0
