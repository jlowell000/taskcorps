#!/usr/bin/env python3
"""
deepseek/commands.py — command transformer for Deepseek Harness.

Copies commands as reference docs under .agents/notes/commands/.
"""

from __future__ import annotations

from pathlib import Path

from common import copy_flat


def transform(source_dir: Path, target_dir: Path) -> None:
    """Copy commands as reference docs for Deepseek."""
    copy_flat(source_dir, target_dir)
