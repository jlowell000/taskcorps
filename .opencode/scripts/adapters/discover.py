#!/usr/bin/env python3
"""
discover.py — list adapters for shell scripts.

Outputs one line per adapter in the format:
  name|priority|generates_types

Example:
  opencode|10|agent_frontmatter,config,commands
  configs|5|config
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent))

from common import discover_adapters


def main() -> None:
    adapters_dir = Path(__file__).resolve().parent
    target_type = ""
    args = sys.argv[1:]
    if args and args[0] == "--target-type" and len(args) >= 2:
        target_type = args[1]
    adapters = discover_adapters(adapters_dir)
    for adapter in adapters:
        name = adapter.get("name", "")
        priority = adapter.get("priority", 0)
        generates = adapter.get("generates", [])
        types = ",".join(g.get("type", "") for g in generates if isinstance(g, dict))

        # Filter by target type if requested
        if target_type:
            # Map target types to adapter names that apply
            applicable = {
                "opencode": {"opencode", "claude-code", "cursor", "codex", "copilot", "configs"},
                "deepseek": {"deepseek", "configs"},
            }
            allowed = applicable.get(target_type, set())
            if name not in allowed:
                continue

        print(f"{name}|{priority}|{types}")


if __name__ == "__main__":
    main()
