#!/usr/bin/env python3
"""
claude-code/commands.py — command transformer for Claude Code.

Generates slash commands for .claude/commands/.
"""

from __future__ import annotations

from pathlib import Path

from common import copy_flat, read_file, write_file


def transform(source_dir: Path, target_dir: Path) -> None:
    """Copy commands as slash commands for Claude Code."""
    copy_flat(source_dir, target_dir)
