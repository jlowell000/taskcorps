#!/usr/bin/env python3
"""
cursor/commands.py — command transformer for Cursor IDE.

Converts commands to @command prefix and $ARGUMENTS -> $1.
"""

from __future__ import annotations

import re
from pathlib import Path

from common import read_file, write_file


def transform(source_dir: Path, target_dir: Path) -> None:
    """Transform commands for Cursor."""
    target_dir.mkdir(parents=True, exist_ok=True)

    for cmd_file in source_dir.iterdir():
        if not cmd_file.is_file() or cmd_file.suffix != ".md":
            continue
        text = read_file(cmd_file)
        # Replace $ARGUMENTS with $1
        text = text.replace("$ARGUMENTS", "$1")
        # Prefix command name with @ on the first "Run ..." line (after frontmatter)
        lines = text.splitlines()
        for i, line in enumerate(lines):
            if line.startswith("Run "):
                cmd_name = cmd_file.stem
                lines[i] = f"@{cmd_name} " + line.removeprefix("Run ").strip()
                break
        text = "\n".join(lines)
        write_file(target_dir / cmd_file.name, text)
