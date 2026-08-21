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
    adapters = discover_adapters(adapters_dir)
    for adapter in adapters:
        name = adapter.get("name", "")
        priority = adapter.get("priority", 0)
        generates = adapter.get("generates", [])
        types = ",".join(g.get("type", "") for g in generates if isinstance(g, dict))
        print(f"{name}|{priority}|{types}")


if __name__ == "__main__":
    main()
