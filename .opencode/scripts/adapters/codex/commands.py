#!/usr/bin/env python3
"""
codex/commands.py — command transformer for OpenAI Codex.

Wraps commands in TOML command blocks.
"""

from __future__ import annotations

from pathlib import Path

from common import parse_frontmatter, read_file, write_file


def transform(source_dir: Path, target_dir: Path) -> None:
    """Transform commands into Codex TOML command blocks."""
    target_dir.mkdir(parents=True, exist_ok=True)

    for cmd_file in source_dir.iterdir():
        if not cmd_file.is_file() or cmd_file.suffix != ".md":
            continue
        text = read_file(cmd_file)
        fm, body = parse_frontmatter(text)
        description = fm.get("description", cmd_file.stem)
        cmd_name = cmd_file.stem

        toml_content = f"""\
[command.{cmd_name}]
description = "{description}"
{body.strip()}
"""
        write_file(target_dir / f"{cmd_name}.toml", toml_content)
