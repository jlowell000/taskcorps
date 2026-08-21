#!/usr/bin/env python3
"""
codex.py — adapter for OpenAI Codex.

Generates .codex/agents/<role>.toml files with Codex agent format:
  name, description, developer_instructions
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

try:
    import tomllib  # Python 3.11+
except ImportError:
    import tomli as tomllib  # backport

try:
    import tomli_w
except ImportError:
    tomli_w = None

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import read_file, write_file


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

        # Extract description from existing frontmatter
        fm_match = re.match(r"\A---\s*\n(.*?)\n---\s*\n?", text, re.DOTALL)
        if fm_match:
            try:
                import yaml
                fm = yaml.safe_load(fm_match.group(1)) or {}
                description = fm.get("description", "")
            except Exception:
                description = ""
        else:
            description = ""

        if not description:
            description = role

        # The body text becomes developer_instructions
        body = text[fm_match.end() :] if fm_match else text
        body = body.strip()

        toml_content = f"""\
name = "{role}"
description = "{description}"

[developer_instructions]
"""
        # Embed body as a multi-line string
        toml_content += f'content = """\n{body}\n"""\n'

        write_file(target / f"{role}.toml", toml_content)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/codex.py <source_agents_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
