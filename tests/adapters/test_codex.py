"""Tests for the codex adapter."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import read_file

from conftest import load_adapter_module


def test_codex_generates_toml(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("codex").run
    target = tmp_path / ".codex" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        toml_file = target / f"{role}.toml"
        assert toml_file.exists(), f"Missing {toml_file}"
        content = read_file(toml_file)
        assert f'name = "{role}"' in content
        assert "[developer_instructions]" in content


def test_codex_toml_is_valid(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    import tomllib
    run = load_adapter_module("codex").run
    target = tmp_path / ".codex" / "agents"
    target.mkdir(parents=True)
    run(tmp_agents_dir, target, sample_agents_md)
    for role in ("pm", "coder"):
        with open(target / f"{role}.toml", "rb") as f:
            data = tomllib.load(f)
        assert data["name"] == role
        assert "description" in data
        assert "developer_instructions" in data
        assert "content" in data["developer_instructions"]
