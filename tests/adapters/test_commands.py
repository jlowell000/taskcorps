"""Tests for command transformation per tool."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from conftest import load_adapter_module


class TestCursorCommands:
    def test_replaces_arguments(self, tmp_commands_dir: Path, tmp_path: Path):
        transform = load_adapter_module("cursor", "commands").transform
        target = tmp_path / "cursor_commands"
        target.mkdir()
        transform(tmp_commands_dir, target)
        content = (target / "retro.md").read_text()
        assert "$1" in content
        assert "$ARGUMENTS" not in content

    def test_adds_at_prefix(self, tmp_commands_dir: Path, tmp_path: Path):
        transform = load_adapter_module("cursor", "commands").transform
        target = tmp_path / "cursor_commands"
        target.mkdir()
        transform(tmp_commands_dir, target)
        content = (target / "scrum.md").read_text()
        assert "@scrum" in content


class TestCodexCommands:
    def test_wraps_in_toml(self, tmp_commands_dir: Path, tmp_path: Path):
        transform = load_adapter_module("codex", "commands").transform
        target = tmp_path / "codex_commands"
        target.mkdir()
        transform(tmp_commands_dir, target)
        toml_file = target / "retro.toml"
        assert toml_file.exists()
        content = toml_file.read_text()
        assert '[command.retro]' in content
        assert 'description = "Run a retrospective"' in content


class TestDeepseekCommands:
    def test_copies_unchanged(self, tmp_commands_dir: Path, tmp_path: Path):
        transform = load_adapter_module("deepseek", "commands").transform
        target = tmp_path / "deepseek_commands"
        target.mkdir()
        transform(tmp_commands_dir, target)
        assert (target / "retro.md").exists()
        assert (target / "scrum.md").exists()


class TestCopilotCommands:
    def test_noop(self, tmp_commands_dir: Path, tmp_path: Path):
        transform = load_adapter_module("copilot", "commands").transform
        target = tmp_path / "copilot_commands"
        target.mkdir()
        transform(tmp_commands_dir, target)
        assert not any(target.iterdir())
