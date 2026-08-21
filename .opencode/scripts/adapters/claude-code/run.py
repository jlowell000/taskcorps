#!/usr/bin/env python3
"""
claude-code/run.py — adapter for Claude Code.

Generates .claude/agents/<role>.md files with Claude Code frontmatter:
  name, description, tools, model, permissionMode
Also generates CLAUDE.md as an @AGENTS.md import.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import yaml
from common import extract_description, parse_frontmatter, read_file, write_file

ROLE_TOOLS: dict[str, str] = {
    "pm": "Read, Write, Bash, Glob, Grep",
    "designer": "Read, Write, Glob, Grep",
    "coder": "Read, Write, Edit, Bash, Glob, Grep",
    "tester": "Read, Bash, Glob, Grep",
    "reviewer": "Read, Glob, Grep, Bash",
}

ROLE_MODEL: dict[str, str] = {
    "pm": "inherit",
    "designer": "inherit",
    "coder": "inherit",
    "tester": "inherit",
    "reviewer": "inherit",
}

ROLE_PERMISSION_MODE: dict[str, str] = {
    "pm": "default",
    "designer": "default",
    "coder": "default",
    "tester": "default",
    "reviewer": "default",
}


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate Claude Code agent files.

    Args:
        source: path to canonical .opencode/agents/ directory
        target: path to output .claude/agents/ directory
        agents_md: path to AGENTS.md (used to build CLAUDE.md)
    """
    target.mkdir(parents=True, exist_ok=True)

    for role_file in source.iterdir():
        if not role_file.is_file() or role_file.suffix != ".md":
            continue
        role = role_file.stem
        text = read_file(role_file)
        description = extract_description(text) or role
        _, body = parse_frontmatter(text)

        claude_fm = {
            "name": role,
            "description": description,
            "tools": ROLE_TOOLS.get(role, "Read, Write"),
            "model": ROLE_MODEL.get(role, "inherit"),
            "permissionMode": ROLE_PERMISSION_MODE.get(role, "default"),
        }

        fm_block = "---\n" + yaml.dump(claude_fm, default_flow_style=False, sort_keys=False) + "---\n"
        write_file(target / f"{role}.md", fm_block + "\n" + body if body else fm_block)

    # Generate CLAUDE.md as @AGENTS.md import
    claude_md = target.parent / "CLAUDE.md"
    write_file(claude_md, "@AGENTS.md\n")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/claude-code/run.py <source_agents_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
