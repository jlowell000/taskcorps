#!/usr/bin/env python3
"""
cursor.py — adapter for Cursor IDE.

Generates .cursor/agents/<role>.md files with Cursor frontmatter:
  name, description, model, readonly
"""

from __future__ import annotations

import re
import sys
import yaml
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import read_file, write_file

ROLE_MODEL: dict[str, str] = {
    "pm": "inherit",
    "designer": "inherit",
    "coder": "inherit",
    "tester": "inherit",
    "reviewer": "inherit",
}


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate Cursor agent files.

    Args:
        source: path to canonical .opencode/agents/ directory
        target: path to output .cursor/agents/ directory
        agents_md: path to AGENTS.md (for role context)
    """
    target.mkdir(parents=True, exist_ok=True)

    for role_file in source.iterdir():
        if not role_file.is_file() or role_file.suffix != ".md":
            continue
        role = role_file.stem
        text = read_file(role_file)

        # Extract description from existing frontmatter
        fm_match = re.match(r"\A---\s*\n(.*?)\n---\s*\n?", text, re.DOTALL)
        if fm_match:
            try:
                fm = yaml.safe_load(fm_match.group(1)) or {}
                description = fm.get("description", "")
            except Exception:
                description = ""
        else:
            description = ""

        if not description:
            description = role

        cursor_fm = {
            "name": role,
            "description": description,
            "model": ROLE_MODEL.get(role, "inherit"),
            "readonly": role == "reviewer",
        }

        fm_block = "---\n" + yaml.dump(cursor_fm, default_flow_style=False, sort_keys=False) + "---\n"
        body = text[fm_match.end() :] if fm_match else text
        write_file(target / f"{role}.md", fm_block + "\n" + body if body else fm_block)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/cursor.py <source_agents_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
