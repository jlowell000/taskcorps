#!/usr/bin/env python3
"""
codex/run.py — adapter for OpenAI Codex.

Generates .codex/agents/<role>.toml files with Codex agent format:
  name, description, developer_instructions
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import extract_description, parse_frontmatter, read_file, write_file


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate Codex agent TOML files.

    Args:
        source: path to canonical .opencode/agents/ directory
        target: path to output .codex/agents/ directory
        agents_md: path to AGENTS.md (for role context)
    """
    target.mkdir(parents=True, exist_ok=True)

    for role_file in source.iterdir():
        if not role_file.is_file() or role_file.suffix != ".md":
            continue
        role = role_file.stem
        text = read_file(role_file)
        description = extract_description(text) or role
        _, body = parse_frontmatter(text)
        body = body.strip()

        toml_content = f"""\
name = "{role}"
description = "{description}"

[developer_instructions]
"""
        toml_content += f'content = """\n{body}\n"""\n'

        write_file(target / f"{role}.toml", toml_content)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/codex/run.py <source_agents_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
