#!/usr/bin/env bash
# default-branch.sh — print the repo's default (upstream/integration) branch name.
# Order: origin/HEAD -> init.defaultBranch -> main. stdout gets exactly one name; stderr stays
# empty on success. Exit 0 on success, 1 if not determinable (not a git work tree).
set -euo pipefail

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  printf 'default-branch.sh: not inside a git work tree; cannot determine default branch\n' >&2
  exit 1
fi

# 1. origin/HEAD symbolic ref -> output like `refs/remotes/origin/main`; strip refs/remotes/origin/.
if branch="$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null)"; then
  branch="${branch#refs/remotes/origin/}"
  if [ -n "$branch" ]; then printf '%s\n' "$branch"; exit 0; fi
fi

# 2. init.defaultBranch config (empty value => treated as missing, fall through).
if branch="$(git config --get init.defaultBranch 2>/dev/null)"; then
  if [ -n "$branch" ]; then printf '%s\n' "$branch"; exit 0; fi
fi

# 3. hard fallback.
printf '%s\n' "main"
exit 0