#!/usr/bin/env python3
"""
copilot.py — adapter for GitHub Copilot.

Merges taskcorps AGENTS.md content into .github/copilot-instructions.md.
If the file exists, prepend taskcorps content; otherwise create it.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import read_file, write_file


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate Copilot instructions file.

    Args:
        source: path to canonical .opencode/ directory (unused, kept for interface consistency)
        target: path to the project root (where .github/ lives)
        agents_md: path to AGENTS.md
    """
    github_dir = target / ".github"
    github_dir.mkdir(parents=True, exist_ok=True)

    copilot_file = github_dir / "copilot-instructions.md"
    taskcorps_content = read_file(agents_md)

    if copilot_file.exists():
        existing = read_file(copilot_file)
        # Only prepend if taskcorps content is not already present
        if "Taskcorps Team Contract" not in existing:
            merged = taskcorps_content + "\n\n---\n\n# Project-specific Copilot instructions\n\n" + existing
            write_file(copilot_file, merged)
    else:
        write_file(copilot_file, taskcorps_content)


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/copilot.py <source_opencode_dir> <target_root> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
