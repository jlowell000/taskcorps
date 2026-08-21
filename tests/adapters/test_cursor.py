"""Tests for the cursor adapter."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import parse_frontmatter, read_file

from conftest import load_adapter_module


def test_cursor_generates_agents(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("cursor").run
    target = tmp_path / ".cursor" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        assert (target / f"{role}.md").exists()


def test_cursor_readonly_on_reviewer(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("cursor").run
    target = tmp_path / ".cursor" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    text = read_file(target / "reviewer.md")
    fm, _ = parse_frontmatter(text)
    assert fm["readonly"] is True
    assert fm["name"] == "reviewer"


def test_cursor_not_readonly_on_pm(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("cursor").run
    target = tmp_path / ".cursor" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    text = read_file(target / "pm.md")
    fm, _ = parse_frontmatter(text)
    assert fm.get("readonly") is not True
