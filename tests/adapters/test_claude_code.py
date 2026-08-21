"""Tests for the claude-code adapter."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import parse_frontmatter, read_file

from conftest import load_adapter_module


def test_claude_code_generates_agents(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("claude-code").run
    target = tmp_path / ".claude" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        assert (target / f"{role}.md").exists()


def test_claude_code_frontmatter_fields(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("claude-code").run
    target = tmp_path / ".claude" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    text = read_file(target / "coder.md")
    fm, _ = parse_frontmatter(text)
    assert fm["name"] == "coder"
    assert "description" in fm
    assert "tools" in fm
    assert "model" in fm
    assert "permissionMode" in fm


def test_claude_code_generates_claude_md(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("claude-code").run
    target = tmp_path / ".claude" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    claude_md = tmp_path / ".claude" / "CLAUDE.md"
    assert claude_md.exists()
    assert claude_md.read_text() == "@AGENTS.md\n"
