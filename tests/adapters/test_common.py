"""Tests for common.py utilities."""

from __future__ import annotations

import sys
from pathlib import Path

import yaml
import pytest

sys_path = str(Path(__file__).resolve().parent.parent / ".opencode" / "scripts" / "adapters")
sys.path.insert(0, sys_path)

from common import (
    copy_file,
    copy_tree,
    ensure_frontmatter,
    extract_description,
    inject_frontmatter,
    parse_frontmatter,
    read_file,
    write_file,
)


class TestParseFrontmatter:
    def test_with_frontmatter(self):
        text = "---\nkey: value\n---\nBody here.\n"
        fm, body = parse_frontmatter(text)
        assert fm == {"key": "value"}
        assert body == "Body here.\n"

    def test_without_frontmatter(self):
        text = "Just body text.\n"
        fm, body = parse_frontmatter(text)
        assert fm == {}
        assert body == "Just body text.\n"

    def test_empty_frontmatter(self):
        text = "---\n---\nBody.\n"
        fm, body = parse_frontmatter(text)
        assert fm == {}

    def test_invalid_yaml(self):
        text = "---\n[invalid: [\n---\nBody.\n"
        fm, body = parse_frontmatter(text)
        assert fm == {}


class TestInjectFrontmatter:
    def test_basic(self):
        result = inject_frontmatter("Body.\n", {"key": "value"})
        assert result.startswith("---\n")
        assert "key: value\n" in result
        assert result.endswith("Body.\n")

    def test_empty_body(self):
        result = inject_frontmatter("", {"key": "value"})
        assert "key: value\n" in result


class TestEnsureFrontmatter:
    def test_existing_frontmatter_merge(self):
        text = "---\nkey: value\n---\nBody.\n"
        result = ensure_frontmatter(text, {"new_key": "new_value"})
        assert "key: value\n" in result
        assert "new_key: new_value\n" in result

    def test_no_frontmatter_adds(self):
        text = "Body.\n"
        result = ensure_frontmatter(text, {"key": "value"})
        assert result.startswith("---\n")
        assert "key: value\n" in result


class TestExtractDescription:
    def test_with_description(self):
        text = "---\ndescription: my agent\n---\n# Body\n"
        assert extract_description(text) == "my agent"

    def test_without_description(self):
        text = "---\nname: test\n---\n# Body\n"
        assert extract_description(text) == ""

    def test_no_frontmatter(self):
        text = "# Body\n"
        assert extract_description(text) == ""


class TestFileIO:
    def test_read_write_file(self, tmp_path: Path):
        p = tmp_path / "test.md"
        write_file(p, "hello")
        assert read_file(p) == "hello"

    def test_copy_file(self, tmp_path: Path):
        src = tmp_path / "src.md"
        dst = tmp_path / "dst.md"
        write_file(src, "content")
        copy_file(src, dst)
        assert dst.exists()
        assert read_file(dst) == "content"

    def test_copy_tree(self, tmp_path: Path):
        src = tmp_path / "src"
        dst = tmp_path / "dst"
        src.mkdir()
        (src / "a.md").write_text("a")
        (src / "b.md").write_text("b")
        copy_tree(src, dst)
        assert (dst / "a.md").exists()
        assert (dst / "b.md").exists()
