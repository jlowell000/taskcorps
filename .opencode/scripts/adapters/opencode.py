#!/usr/bin/env python3
"""
opencode.py — adapter for OpenCode.

Injects OpenCode-specific frontmatter into canonical agent files:
  mode, color, temperature, permission
"""

from __future__ import annotations

import sys
from pathlib import Path

# Add parent directory to path so we can import common
sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import (
    copy_file,
    copy_tree,
    ensure_frontmatter,
    parse_roles_from_agents,
    read_file,
    write_file,
)

ROLE_FRONTMATTER: dict[str, dict] = {
    "pm": {
        "mode": "primary",
        "color": "primary",
        "temperature": 0.2,
        "permission": {
            "task": {
                "*": "deny",
                "designer": "allow",
                "coder": "allow",
                "tester": "allow",
                "reviewer": "allow",
                "explore": "allow",
                "general": "allow",
            }
        },
    },
    "designer": {"mode": "subagent", "temperature": 0.3},
    "coder": {"mode": "subagent", "temperature": 0.2},
    "tester": {"mode": "subagent", "temperature": 0.1},
    "reviewer": {"mode": "subagent", "temperature": 0.1, "permission": {"edit": "deny"}},
}


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate OpenCode-specific agent files.

    Args:
        source: path to canonical .opencode/agents/ directory
        target: path to output .opencode/agents/ directory
        agents_md: path to AGENTS.md (for role context, not strictly needed here)
    """
    target.mkdir(parents=True, exist_ok=True)

    for role, extra_fm in ROLE_FRONTMATTER.items():
        src_file = source / f"{role}.md"
        if not src_file.exists():
            continue
        text = read_file(src_file)
        updated = ensure_frontmatter(text, extra_fm)
        write_file(target / f"{role}.md", updated)

    # Copy other agent files unchanged (if any non-role files exist)
    for f in source.iterdir():
        if f.is_file() and f.name not in {r + ".md" for r in ROLE_FRONTMATTER}:
            copy_file(f, target / f.name)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/opencode.py <source_agents_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
