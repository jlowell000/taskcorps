#!/usr/bin/env python3
"""
configs.py — generate tool-specific configuration files during install.

Each tool gets a minimal config that references AGENTS.md. User-owned configs
are never overwritten.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import write_file


def generate_opencode(target: Path) -> None:
    """Generate opencode.json if it does not exist."""
    config = {
        "$schema": "https://opencode.ai/config.json",
        "default_agent": "pm",
        "compaction": {"auto": True, "tail_turns": 15},
        "instructions": ["AGENTS.md"],
        "permission": {"external_directory": {"*": "ask"}},
    }
    write_file(target / "opencode.json", json.dumps(config, indent=2) + "\n")


def generate_claude_code(target: Path) -> None:
    """Generate .claude/settings.json if it does not exist."""
    config = {"instructions": ["AGENTS.md"]}
    write_file(target / ".claude" / "settings.json", json.dumps(config, indent=2) + "\n")


def generate_cursor(target: Path) -> None:
    """Generate .cursor/settings.json if it does not exist (minimal)."""
    config = {}
    write_file(target / ".cursor" / "settings.json", json.dumps(config, indent=2) + "\n")


def generate_codex(target: Path) -> None:
    """Generate config.toml for Codex if it does not exist."""
    toml_content = """\
[project]
doc_fallback_filenames = ["AGENTS.md"]
"""
    write_file(target / "config.toml", toml_content)


def generate_configs(target: Path, tool: str) -> None:
    """Generate config for the specified tool if not already present.

    Args:
        target: project root directory
        tool: one of 'opencode', 'claude-code', 'cursor', 'codex', 'deepseek'
    """
    if tool == "opencode":
        if not (target / "opencode.json").exists():
            generate_opencode(target)
    elif tool == "claude-code":
        if not (target / ".claude" / "settings.json").exists():
            generate_claude_code(target)
    elif tool == "cursor":
        if not (target / ".cursor" / "settings.json").exists():
            generate_cursor(target)
    elif tool == "codex":
        if not (target / "config.toml").exists():
            generate_codex(target)
    elif tool == "deepseek":
        # Never touch user-owned .dsh/settings.yaml
        pass


if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: adapters/configs.py <target_dir> <tool>", file=sys.stderr)
        sys.exit(1)
    generate_configs(Path(sys.argv[1]), sys.argv[2])
