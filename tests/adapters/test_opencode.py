"""Tests for the opencode adapter."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import parse_frontmatter, read_file

from conftest import load_adapter_module


def test_opencode_injects_frontmatter(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("opencode").run
    target = tmp_path / "target"
    target.mkdir()
    run(tmp_agents_dir, target, sample_agents_md)
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        text = read_file(target / f"{role}.md")
        fm, body = parse_frontmatter(text)
        assert "mode" in fm
        assert "temperature" in fm
        assert body.strip() == f"# {role.title()}\nBody text."


def test_opencode_preserves_non_role_files(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("opencode").run
    (tmp_agents_dir / "helper.md").write_text("helper content")
    target = tmp_path / "target"
    target.mkdir()
    run(tmp_agents_dir, target, sample_agents_md)
    assert (target / "helper.md").exists()
    assert read_file(target / "helper.md") == "helper content"
