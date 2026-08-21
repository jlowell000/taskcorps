#!/usr/bin/env python3
"""
common.py — shared utilities for taskcorps adapter scripts.

Handles frontmatter parsing, YAML injection, file copies, role extraction,
manifest loading, adapter discovery, and command transformation dispatch.
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


def extract_description(text: str) -> str:
    """Extract the description field from frontmatter, or empty string."""
    fm, _ = parse_frontmatter(text)
    return fm.get("description", "")


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


def copy_flat(src: Path, dst: Path) -> None:
    """Flat copy all files from src/ into dst/ (no recursion into subdirs of src)."""
    dst.mkdir(parents=True, exist_ok=True)
    for f in src.iterdir():
        if f.is_file():
            shutil.copy2(f, dst / f.name)


def copy_tree_recursive(src: Path, dst: Path) -> None:
    """Recursively copy src/ tree into dst/, preserving subdirectory structure."""
    shutil.copytree(src, dst, dirs_exist_ok=True)


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


# ---------------------------------------------------------------------------
# Manifest loading and adapter discovery
# ---------------------------------------------------------------------------

MANIFEST_REQUIRED_FIELDS = {"name", "description", "priority", "generates"}


def load_manifest(adapter_dir: Path) -> dict:
    """Load and validate an adapter manifest.yaml.

    Returns the manifest dict. Raises ValueError on validation failure.
    """
    manifest_path = adapter_dir / "manifest.yaml"
    if not manifest_path.exists():
        raise ValueError(f"Missing manifest.yaml in {adapter_dir}")
    try:
        manifest = yaml.safe_load(read_file(manifest_path)) or {}
    except yaml.YAMLError as e:
        raise ValueError(f"Invalid YAML in {manifest_path}: {e}")

    missing = MANIFEST_REQUIRED_FIELDS - set(manifest.keys())
    if missing:
        raise ValueError(f"Manifest {manifest_path} missing required fields: {missing}")
    return manifest


def discover_adapters(adapters_dir: Path) -> list[dict]:
    """Scan adapters_dir for directories containing manifest.yaml.

    Returns a list of manifest dicts sorted by priority (highest first).
    Prints a warning to stderr for each invalid manifest encountered.
    """
    adapters: list[dict] = []
    if not adapters_dir.is_dir():
        return adapters
    for d in sorted(adapters_dir.iterdir()):
        if not d.is_dir():
            continue
        try:
            manifest = load_manifest(d)
            manifest["_dir"] = d
            adapters.append(manifest)
        except ValueError as e:
            print(f"WARNING: skipping adapter {d.name}: {e}", file=sys.stderr)
            continue
    adapters.sort(key=lambda m: m.get("priority", 0), reverse=True)
    return adapters


def validate_manifest(manifest: dict) -> list[str]:
    """Return a list of validation errors for a manifest dict."""
    errors: list[str] = []
    missing = MANIFEST_REQUIRED_FIELDS - set(manifest.keys())
    if missing:
        errors.append(f"Missing required fields: {missing}")
    generates = manifest.get("generates", [])
    if not isinstance(generates, list):
        errors.append("'generates' must be a list")
    else:
        valid_types = {"agent_frontmatter", "config", "commands", "reference_docs"}
        for i, g in enumerate(generates):
            if not isinstance(g, dict):
                errors.append(f"generates[{i}] must be a dict")
                continue
            if "type" not in g:
                errors.append(f"generates[{i}] missing 'type'")
            elif g["type"] not in valid_types:
                errors.append(f"generates[{i}] unknown type: {g['type']}")
    return errors


# ---------------------------------------------------------------------------
# Command transformation dispatch
# ---------------------------------------------------------------------------

# Tool-specific argument expansion patterns
ARG_PATTERNS: dict[str, str] = {
    "opencode": r"\$ARGUMENTS",
    "claude-code": r"\$ARGUMENTS",
    "cursor": r"\$ARGUMENTS",
    "codex": r"\$ARGUMENTS",
    "deepseek": r"\$ARGUMENTS",
    "copilot": r"\$ARGUMENTS",
}

# Tool-specific path rewrites
PATH_REWRITES: dict[str, dict[str, str]] = {
    "claude-code": {
        r"\.opencode/": ".claude/",
        r"\.opencode\\": ".claude\\",
    },
    "cursor": {
        r"\.opencode/": ".cursor/",
        r"\.opencode\\": ".cursor\\",
    },
    "codex": {
        r"\.opencode/": ".codex/",
        r"\.opencode\\": ".codex\\",
    },
    "deepseek": {
        r"\.opencode/": ".agents/",
        r"\.opencode\\": ".agents\\",
    },
    "copilot": {
        r"\.opencode/": ".github/",
        r"\.opencode\\": ".github\\",
    },
}


def transform_commands(source_dir: Path, target_dir: Path, tool: str) -> None:
    """Transform canonical commands for a target tool.

    Args:
        source_dir: canonical commands directory (`.opencode/commands/`)
        target_dir: output commands directory for the target tool
        tool: target tool name (e.g., 'opencode', 'claude-code', 'cursor')
    """
    target_dir.mkdir(parents=True, exist_ok=True)

    for cmd_file in source_dir.iterdir():
        if not cmd_file.is_file() or cmd_file.suffix != ".md":
            continue
        text = read_file(cmd_file)

        # Parse frontmatter to extract description
        fm, body = parse_frontmatter(text)
        description = fm.get("description", "")

        # Apply argument expansion
        arg_pattern = ARG_PATTERNS.get(tool, r"\$ARGUMENTS")
        if tool == "cursor":
            body = body.replace("$ARGUMENTS", "$1")
        elif tool == "codex":
            # Codex uses TOML params; replace $ARGUMENTS with a param reference
            body = body.replace("$ARGUMENTS", "$ARGUMENTS")
        else:
            body = body.replace("$ARGUMENTS", arg_pattern)

        # Apply path rewrites
        rewrites = PATH_REWRITES.get(tool, {})
        for pattern, replacement in rewrites.items():
            body = re.sub(pattern, replacement, body)

        # Tool-specific invocation prefix
        if tool == "cursor":
            # Prefix command name with @
            lines = body.splitlines()
            if lines and lines[0].startswith("Run "):
                cmd_name = cmd_file.stem
                lines[0] = f"@{cmd_name} " + lines[0].removeprefix("Run ").strip()
                body = "\n".join(lines)
        elif tool == "codex":
            # Wrap in TOML command block (simplified)
            cmd_name = cmd_file.stem
            body = f'[command.{cmd_name}]\ndescription = "{description}"\n{body}'

        # Write transformed command
        write_file(target_dir / cmd_file.name, inject_frontmatter(body, fm))


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
