# Portability Architecture

Taskcorps is designed to run across AI coding tools without forking content. This document
describes the adapter-based architecture that achieves this.

## Canonical Sources

All team content lives in tool-agnostic form in the baseline repo:

- `AGENTS.md` — the team contract (roles, protocol, TDD, DoD)
- `.opencode/agents/*.md` — canonical role definitions (pm, designer, coder, tester, reviewer)
- `.opencode/skills/*/SKILL.md` — skills with portable `name` + `description` frontmatter
- `.opencode/commands/*.md` — slash commands with portable frontmatter
- `.opencode/templates/` — skeletons for team documents

## Adapter Layer

Adapters re-render canonical sources into each tool's native format. They live in
`.opencode/scripts/adapters/` and are written in Python for cross-platform support.

### Available Adapters

| Adapter | Target | What it does |
| --- | --- | --- |
| `opencode.py` | OpenCode | Injects `mode`, `color`, `temperature`, `permission` frontmatter into agent files |
| `claude-code.py` | Claude Code | Generates `.claude/agents/<role>.md` with Claude Code frontmatter; creates `CLAUDE.md` as `@AGENTS.md` import |
| `cursor.py` | Cursor IDE | Generates `.cursor/agents/<role>.md` with Cursor frontmatter (`readonly` for reviewer) |
| `codex.py` | OpenAI Codex | Generates `.codex/agents/<role>.toml` with Codex TOML agent format |
| `deepseek.py` | Deepseek | Installs team files as reference docs under `.agents/notes/`; never touches harness root `AGENTS.md` |
| `copilot.py` | Copilot | Merges `AGENTS.md` into `.github/copilot-instructions.md` |

### Adapter Interface

Each adapter is a Python script with the following signature:

```python
def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate tool-specific files.

    Args:
        source: path to canonical source directory
        target: path to output directory
        agents_md: path to AGENTS.md (for role context)
    """
```

### Common Utilities

`common.py` provides shared utilities:
- Frontmatter parsing and injection
- File I/O helpers
- Canonical role extraction from `AGENTS.md`

## Git Provider Abstraction

The `/release` skill supports multiple Git providers via a provider abstraction layer
(`.opencode/scripts/adapters/git-providers.py`):

| Provider | CLI | Class |
| --- | --- | --- |
| GitHub | `gh` | `GitHubProvider` |
| GitLab | `glab` | `GitLabProvider` |
| Gitea | `gitea` (or manual) | `GiteaProvider` |

Provider detection is based on the `Provider:` field in `.team/context/pr-capabilities.md`.

## Adding a New Tool

To add support for a new tool:

1. Create `.opencode/scripts/adapters/<tool>.py` implementing the `run()` interface
2. Register the adapter in `.opencode/scripts/install-global.sh`
3. Add a `generate_<tool>()` function in `configs.py` if the tool needs a config file
4. Update `PORTABILITY.md` and `README.md`
5. Add tests for the adapter

## Adding a New Git Provider

To add support for a new Git provider:

1. Add a new class in `git-providers.py` implementing the `GitProvider` interface
2. Update the `detect_provider()` function to recognize the new provider
3. Update `.team/templates/pr-capabilities.md` to include the new provider option
