"""Tests for the copilot adapter."""

from __future__ import annotations

import sys
from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
sys.path.insert(0, sys_path)

from common import read_file

from conftest import load_adapter_module


def test_copilot_creates_instructions_when_missing(tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("copilot").run
    target = tmp_path
    run(tmp_path, target, sample_agents_md)
    instructions = target / ".github" / "copilot-instructions.md"
    assert instructions.exists()
    assert "Taskcorps Team Contract" in read_file(instructions)


def test_copilot_prepends_to_existing(tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("copilot").run
    github = tmp_path / ".github"
    github.mkdir()
    existing = github / "copilot-instructions.md"
    existing.write_text("# Existing content\n")
    run(tmp_path, tmp_path, sample_agents_md)
    content = read_file(existing)
    assert content.startswith("# Taskcorps Team Contract")
    assert "# Existing content" in content


def test_copilot_idempotent(tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("copilot").run
    run(tmp_path, tmp_path, sample_agents_md)
    run(tmp_path, tmp_path, sample_agents_md)
    instructions = tmp_path / ".github" / "copilot-instructions.md"
    content = read_file(instructions)
    assert content.count("Taskcorps Team Contract") == 1
