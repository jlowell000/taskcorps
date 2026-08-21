"""Tests for git-providers adapter."""

from __future__ import annotations

import importlib.util
from pathlib import Path

import pytest

sys_path = str(Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters")
import sys
sys.path.insert(0, sys_path)

from common import write_file


def load_git_providers_run():
    """Load git-providers/run.py via importlib (directory has hyphen)."""
    run_path = Path(__file__).resolve().parent.parent.parent / ".opencode" / "scripts" / "adapters" / "git-providers" / "run.py"
    spec = importlib.util.spec_from_file_location("git_providers_run", run_path)
    module = importlib.util.module_from_spec(spec)
    sys.modules["git_providers_run"] = module
    spec.loader.exec_module(module)
    return module


def test_detect_github_provider(tmp_path: Path):
    mod = load_git_providers_run()
    cap = tmp_path / "pr-capabilities.md"
    write_file(cap, "- Provider: github\n- Enabled: yes\n")
    provider = mod.detect_provider(cap)
    assert provider is not None
    assert provider.name == "github"


def test_detect_gitlab_provider(tmp_path: Path):
    mod = load_git_providers_run()
    cap = tmp_path / "pr-capabilities.md"
    write_file(cap, "- Provider: gitlab\n- Enabled: yes\n")
    provider = mod.detect_provider(cap)
    assert provider is not None
    assert provider.name == "gitlab"


def test_detect_gitea_provider(tmp_path: Path):
    mod = load_git_providers_run()
    cap = tmp_path / "pr-capabilities.md"
    write_file(cap, "- Provider: gitea\n- Enabled: yes\n")
    provider = mod.detect_provider(cap)
    assert provider is not None
    assert provider.name == "gitea"


def test_detect_no_provider(tmp_path: Path):
    mod = load_git_providers_run()
    cap = tmp_path / "pr-capabilities.md"
    write_file(cap, "- Enabled: no\n")
    provider = mod.detect_provider(cap)
    assert provider is None
