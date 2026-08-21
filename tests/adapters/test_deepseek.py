"""Tests for the deepseek adapter."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import read_file

from conftest import load_adapter_module


def test_deepseek_installs_agents_as_reference_docs(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("deepseek").run
    target = tmp_path  # target is the project root, adapter creates .agents/ inside it
    run(tmp_agents_dir.parent, target, sample_agents_md)
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        assert (target / ".agents" / "notes" / "agents" / f"{role}.md").exists()


def test_deepseek_installs_taskcorps_agents_md(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("deepseek").run
    target = tmp_path  # target is the project root
    run(tmp_agents_dir.parent, target, sample_agents_md)
    ref = target / ".agents" / "notes" / "taskcorps-AGENTS.md"
    assert ref.exists()
    assert "Taskcorps" in read_file(ref)


def test_deepseek_never_touches_root_agents_md(tmp_agents_dir: Path, tmp_path: Path, sample_agents_md: Path):
    run = load_adapter_module("deepseek").run
    target = tmp_path  # target is the project root
    # Create a root AGENTS.md to ensure it's not overwritten
    root_agents = target / ".agents" / "AGENTS.md"
    root_agents.parent.mkdir(parents=True, exist_ok=True)
    root_agents.write_text("ROOT CONTENT")
    run(tmp_agents_dir.parent, target, sample_agents_md)
    assert root_agents.read_text() == "ROOT CONTENT"
