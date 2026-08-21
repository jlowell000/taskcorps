#!/usr/bin/env python3
"""
common.py — shared utilities for taskcorps adapter scripts.

Handles frontmatter parsing, YAML injection, file copies, and role extraction
from AGENTS.md.
"""

from __future__ import annotations

import copy
import re
import shutil
import sys
from pathlib import Path

try:
    import yaml
except ImportError:
    print("ERROR: PyYAML is required. Install with: pip install pyyaml", file=sys.stderr)
    sys.exit(1)


# ---------------------------------------------------------------------------
# Frontmatter helpers
# ---------------------------------------------------------------------------

FRONTMATTER_RE = re.compile(r"\A---\s*\n(.*?)\n---\s*\n?", re.DOTALL)


def parse_frontmatter(text: str) -> tuple[dict, str]:
    """Split a markdown file into (frontmatter_dict, body_text).

    Returns ({}, text) when no frontmatter is present.
    """
    m = FRONTMATTER_RE.match(text)
    if not m:
        return {}, text
    try:
        fm = yaml.safe_load(m.group(1)) or {}
    except yaml.YAMLError:
        fm = {}
    body = text[m.end() :]
    return fm, body


def inject_frontmatter(body: str, fm: dict) -> str:
    """Return body wrapped with updated frontmatter."""
    fm_block = "---\n" + yaml.dump(fm, default_flow_style=False, sort_keys=False) + "---\n"
    return fm_block + "\n" + body if body else fm_block


def ensure_frontmatter(text: str, extra: dict | None = None) -> str:
    """Parse existing frontmatter, merge in *extra*, re-serialize."""
    fm, body = parse_frontmatter(text)
    if extra:
        fm.update(extra)
    return inject_frontmatter(body, fm)


# ---------------------------------------------------------------------------
# File I/O helpers
# ---------------------------------------------------------------------------

def read_file(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def write_file(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(content, encoding="utf-8")


def copy_file(src: Path, dst: Path) -> None:
    dst.parent.mkdir(parents=True, exist_ok=True)
    shutil.copy2(src, dst)


def copy_tree(src: Path, dst: Path) -> None:
    """Flat copy all files from src/ into dst/ (no recursion into subdirs of src)."""
    dst.mkdir(parents=True, exist_ok=True)
    for f in src.iterdir():
        if f.is_file():
            shutil.copy2(f, dst / f.name)


# ---------------------------------------------------------------------------
# Canonical role extraction from AGENTS.md
# ---------------------------------------------------------------------------

ROLE_SECTION_RE = re.compile(
    r"^### (?P<role>\S+)\s*\((?P<label>.*?)\)\s*$\n"
    r"(?P<body>.*?)(?=^### |\Z)",
    re.MULTILINE | re.DOTALL,
)

FIELD_RE = re.compile(
    r"^-\s+(?:Responsibility|Owns|Behavior|Tools)[:\s]\s*(.+)$",
    re.MULTILINE,
)


def parse_roles_from_agents(agents_md: Path) -> dict[str, dict[str, str]]:
    """Extract canonical role definitions from the AGENTS.md 'Team Roles' section.

    Returns {role_name: {responsibility, owns, behavior, tools}}.
    """
    text = read_file(agents_md)
    roles: dict[str, dict[str, str]] = {}
    for m in ROLE_SECTION_RE.finditer(text):
        name = m.group("role")
        body = m.group("body")
        fields: dict[str, str] = {}
        for fm in FIELD_RE.finditer(body):
            key = fm.group(0).split(":")[0].lstrip("- ").strip().lower()
            value = fm.group(1).strip()
            fields[key] = value
        if fields:
            roles[name] = fields
    return roles


# ---------------------------------------------------------------------------
# Agent file helpers
# ---------------------------------------------------------------------------

def read_agent_file(path: Path) -> tuple[str, dict, str]:
    """Read an agent markdown file and return (role_name, frontmatter, body)."""
    text = read_file(path)
    fm, body = parse_frontmatter(text)
    # role name is the stem of the file (pm, coder, etc.)
    role = path.stem
    return role, fm, body
