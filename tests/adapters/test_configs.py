"""Tests for the configs adapter."""

from __future__ import annotations

import json
import sys
from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
sys.path.insert(0, sys_path)

from conftest import load_adapter_module


def test_configs_generates_opencode_json(tmp_path: Path):
    run = load_adapter_module("configs").run
    run(tmp_path, tmp_path, Path("/dev/null"))  # type: ignore[arg-type]
    config = json.loads((tmp_path / "opencode.json").read_text())
    assert config["default_agent"] == "pm"
    assert "instructions" in config


def test_configs_does_not_overwrite_existing(tmp_path: Path):
    run = load_adapter_module("configs").run
    (tmp_path / "opencode.json").write_text('{"custom": true}')
    run(tmp_path, tmp_path, Path("/dev/null"))  # type: ignore[arg-type]
    assert (tmp_path / "opencode.json").read_text() == '{"custom": true}'


def test_configs_generates_claude_settings(tmp_path: Path):
    run = load_adapter_module("configs").run
    (tmp_path / ".claude").mkdir()
    run(tmp_path, tmp_path, Path("/dev/null"))  # type: ignore[arg-type]
    config = json.loads((tmp_path / ".claude" / "settings.json").read_text())
    assert "instructions" in config


def test_configs_generates_codex_toml(tmp_path: Path):
    run = load_adapter_module("configs").run
    (tmp_path / ".codex").mkdir()
    run(tmp_path, tmp_path, Path("/dev/null"))  # type: ignore[arg-type]
    content = (tmp_path / "config.toml").read_text()
    assert "doc_fallback_filenames" in content
    assert "AGENTS.md" in content
