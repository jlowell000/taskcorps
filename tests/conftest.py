"""Shared fixtures for adapter tests."""

from __future__ import annotations

import importlib.util
import sys
from pathlib import Path

import pytest

# Ensure adapters/ is importable
ADAPTERS_DIR = Path(__file__).resolve().parent.parent / ".opencode" / "scripts" / "adapters"
sys.path.insert(0, str(ADAPTERS_DIR))


def load_adapter_module(adapter_name: str, module_name: str = "run"):
    """Load an adapter module via importlib (directories have hyphens).
    
    Args:
        adapter_name: e.g., 'claude-code', 'git-providers'
        module_name: e.g., 'run', 'commands'
    
    Returns the imported module.
    """
    module_path = ADAPTERS_DIR / adapter_name / f"{module_name}.py"
    spec = importlib.util.spec_from_file_location(
        f"adapter_{adapter_name.replace('-', '_')}_{module_name}",
        module_path
    )
    module = importlib.util.module_from_spec(spec)
    sys.modules[spec.name] = module
    spec.loader.exec_module(module)
    return module


@pytest.fixture
def tmp_agents_dir(tmp_path: Path) -> Path:
    """Create a temp dir with sample canonical agent files."""
    agents = tmp_path / "agents"
    agents.mkdir()
    for role in ("pm", "designer", "coder", "tester", "reviewer"):
        (agents / f"{role}.md").write_text(
            f"---\ndescription: {role} agent\n---\n# {role.title()}\nBody text.\n"
        )
    return agents


@pytest.fixture
def tmp_commands_dir(tmp_path: Path) -> Path:
    """Create a temp dir with sample canonical command files."""
    commands = tmp_path / "commands"
    commands.mkdir()
    (commands / "retro.md").write_text(
        "---\ndescription: Run a retrospective\n---\nRun retro for: $ARGUMENTS\n"
    )
    (commands / "scrum.md").write_text(
        "---\ndescription: Run scrum\n---\nRun scrum for: $ARGUMENTS\n"
    )
    return commands


@pytest.fixture
def sample_agents_md(tmp_path: Path) -> Path:
    """Create a minimal AGENTS.md for testing."""
    agents_md = tmp_path / "AGENTS.md"
    agents_md.write_text(
        "# Taskcorps Team Contract\n\n## Team roles\n\n### pm (primary)\n- Responsibility: orchestrator\n"
    )
    return agents_md
