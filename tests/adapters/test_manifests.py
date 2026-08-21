"""Tests for manifest loading and adapter discovery."""

from __future__ import annotations

from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import discover_adapters, load_manifest, validate_manifest


def test_load_valid_manifest(tmp_path: Path):
    manifest = tmp_path / "manifest.yaml"
    manifest.write_text(
        "name: test\n"
        "description: test adapter\n"
        "priority: 10\n"
        "generates:\n"
        "  - type: agent_frontmatter\n"
    )
    result = load_manifest(tmp_path)
    assert result["name"] == "test"
    assert result["priority"] == 10


def test_load_missing_manifest(tmp_path: Path):
    with pytest.raises(ValueError, match="Missing manifest.yaml"):
        load_manifest(tmp_path)


def test_validate_manifest_missing_fields(tmp_path: Path):
    manifest = tmp_path / "manifest.yaml"
    manifest.write_text("name: test\n")
    result = validate_manifest({"name": "test"})
    assert "Missing required fields" in result[0]


def test_discover_adapters(tmp_path: Path):
    (tmp_path / "adapter-a").mkdir()
    (tmp_path / "adapter-a" / "manifest.yaml").write_text(
        "name: a\ndescription: A\npriority: 5\ngenerates:\n  - type: agent_frontmatter\n"
    )
    (tmp_path / "adapter-b").mkdir()
    (tmp_path / "adapter-b" / "manifest.yaml").write_text(
        "name: b\ndescription: B\npriority: 10\ngenerates:\n  - type: config\n"
    )
    adapters = discover_adapters(tmp_path)
    assert len(adapters) == 2
    assert adapters[0]["name"] == "b"  # higher priority first
    assert adapters[1]["name"] == "a"
