#!/usr/bin/env python3
"""
deepseek/run.py — adapter for Deepseek Harness.

Installs taskcorps agent files as plain Markdown reference docs under .agents/.
The harness's own root AGENTS.md is never touched.
"""

from __future__ import annotations

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from common import copy_file, copy_tree, read_file, write_file


def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate Deepseek reference docs.

    Args:
        source: path to canonical .opencode/ directory
        target: path to output .agents/ directory (deepseek global or project-local)
        agents_md: path to AGENTS.md
    """
    # Install taskcorps AGENTS.md as a reference doc (never overwrite root AGENTS.md)
    taskcorps_agents = target / ".agents" / "notes" / "taskcorps-AGENTS.md"
    copy_file(agents_md, taskcorps_agents)

    # Install CLAUDE.md if it exists
    claude_md = source.parent / "CLAUDE.md"
    if claude_md.exists():
        copy_file(claude_md, target / ".agents" / "notes" / "taskcorps-CLAUDE.md")

    # agents -> .agents/notes/agents/<role>.md
    agents_src = source / "agents"
    if agents_src.exists():
        copy_tree(agents_src, target / ".agents" / "notes" / "agents")

    # commands -> .agents/notes/commands/<name>.md
    commands_src = source / "commands"
    if commands_src.exists():
        copy_tree(commands_src, target / ".agents" / "notes" / "commands")

    # templates -> .agents/notes/templates/<name>.md
    templates_src = source / "templates"
    if templates_src.exists():
        copy_tree(templates_src, target / ".agents" / "notes" / "templates")

    # skills -> .agents/skills/<name>/SKILL.md (alongside existing dsh-* skills)
    skills_src = source / "skills"
    if skills_src.exists():
        skills_dst = target / ".agents" / "skills"
        for skill_dir in skills_src.iterdir():
            if skill_dir.is_dir():
                skill_name = skill_dir.name
                dst_skill = skills_dst / skill_name
                dst_skill.mkdir(parents=True, exist_ok=True)
                skill_md = skill_dir / "SKILL.md"
                if skill_md.exists():
                    copy_file(skill_md, dst_skill / "SKILL.md")


if __name__ == "__main__":
    if len(sys.argv) != 4:
        print("Usage: adapters/deepseek/run.py <source_opencode_dir> <target_agents_dir> <AGENTS.md>", file=sys.stderr)
        sys.exit(1)
    run(Path(sys.argv[1]), Path(sys.argv[2]), Path(sys.argv[3]))
