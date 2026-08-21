#!/usr/bin/env python3
"""
opencode/commands.py — identity command transformer for OpenCode.

Commands are already in the correct format for OpenCode.
"""

from __future__ import annotations

from pathlib import Path

from common import copy_tree, read_file, write_file


def transform(source_dir: Path, target_dir: Path) -> None:
    """Copy commands unchanged (OpenCode is the canonical format)."""
    copy_tree(source_dir, target_dir)
