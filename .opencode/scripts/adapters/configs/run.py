#!/usr/bin/env python3
"""
configs/run.py — generate tool-specific configuration files during install.

Each tool gets a minimal config that references AGENTS.md. User-owned configs
are never overwritten.

Called with: run.py <source_dir> <target_dir> <agents_md>
The tool is detected from the target directory contents.
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import write_file


def detect_tool(target: Path) -> str:
    """Detect tool type from target directory contents."""
    if (target / "opencode.json").exists() or (target / ".opencode").is_dir():
        return "opencode"
    if (target / ".claude").is_dir():
        return "claude-code"
    if (target / ".cursor").is_dir():
        return "cursor"
    if (target / "config.toml").exists() or (target / ".codex").is_dir():
        return "codex"
    if (target / ".agents").is_dir():
        return "deepseek"
    return "opencode"


def generate_opencode(target: Path) -> None:
    """Generate opencode.json if it does not exist."""
    if (target / "opencode.json").exists():
        return
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
    if (target / ".claude" / "settings.json").exists():
        return
    config = {"instructions": ["AGENTS.md"]}
    write_file(target / ".claude" / "settings.json", json.dumps(config, indent=2) + "\n")


def generate_cursor(target: Path) -> None:
    """Generate .cursor/settings.json if it does not exist (minimal)."""
    if (target / ".cursor" / "settings.json").exists():
        return
    config = {}
    write_file(target / ".cursor" / "settings.json", json.dumps(config, indent=2) + "\n")


def generate_codex(target: Path) -> None:
    """Generate config.toml for Codex if it does not exist."""
    if (target / "config.toml").exists():
        return
    toml_content = """\
[project]
doc_fallback_filenames = ["AGENTS.md"]
"""
    write_file(target / "config.toml", toml_content)


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate configs for the detected tool if not already present."""
    tool = detect_tool(target)
    if tool == "opencode":
        generate_opencode(target)
    elif tool == "claude-code":
        generate_claude_code(target)
    elif tool == "cursor":
        generate_cursor(target)
    elif tool == "codex":
        generate_codex(target)
    elif tool == "deepseek":
        # Never touch user-owned .dsh/settings.yaml
        pass


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/configs/run.py <source_dir> <target_dir> <agents_md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
