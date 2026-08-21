#!/usr/bin/env python3
"""
copilot/commands.py — command transformer for GitHub Copilot.

Copilot does not use slash commands; it consumes copilot-instructions.md.
This is a no-op.
"""

from __future__ import annotations

from pathlib import Path


def transform(source_dir: Path, target_dir: Path) -> None:
    """No-op: Copilot does not use slash commands."""
    pass
