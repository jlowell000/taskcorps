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

Each adapter is a directory containing:
- `manifest.yaml` — declares name, priority, requirements, and what it generates
- `run.py` — implements the transformation logic
- `commands.py` — transforms slash commands for the target tool (optional)

### Available Adapters

| Adapter | Target | What it does |
| --- | --- | --- |
| `opencode/` | OpenCode | Injects `mode`, `color`, `temperature`, `permission` frontmatter into agent files |
| `claude-code/` | Claude Code | Generates `.claude/agents/<role>.md` with Claude Code frontmatter; creates `CLAUDE.md` as `@AGENTS.md` import |
| `cursor/` | Cursor IDE | Generates `.cursor/agents/<role>.md` with Cursor frontmatter (`readonly` for reviewer) |
| `codex/` | OpenAI Codex | Generates `.codex/agents/<role>.toml` with Codex TOML agent format |
| `deepseek/` | Deepseek | Installs team files as reference docs under `.agents/notes/`; never touches harness root `AGENTS.md` |
| `copilot/` | Copilot | Merges `AGENTS.md` into `.github/copilot-instructions.md` |
| `configs/` | Multiple | Generates tool-specific config files (opencode.json, .claude/settings.json, etc.) |
| `git-providers/` | Multiple | PR creation abstraction for GitHub, GitLab, Gitea |

### Adapter Manifest

Each adapter directory contains a `manifest.yaml`:

```yaml
name: opencode
description: Inject OpenCode-specific frontmatter
priority: 10
requires:
  python: ">=3.11"
generates:
  - type: agent_frontmatter
    source: .opencode/agents/
    target: .opencode/agents/
    in_place: true
  - type: config
    target: opencode.json
    generator: configs.py
  - type: commands
    source: .opencode/commands/
    target: .opencode/commands/
    transformer: commands.py
```

### Adapter Interface

Each `run.py` implements:

```python
def run(source: Path, target: Path, agents_md: Path) -> None:
    """Generate tool-specific files.

    Args:
        source: path to canonical source directory
        target: path to output directory
        agents_md: path to AGENTS.md (for role context)
    """
```

Each `commands.py` implements:

```python
def transform(source_dir: Path, target_dir: Path) -> None:
    """Transform canonical commands for the target tool."""
```

### Common Utilities

`common.py` provides shared utilities:
- Frontmatter parsing and injection
- File I/O helpers
- Canonical role extraction from `AGENTS.md`
- Manifest loading and adapter discovery
- Command transformation dispatch

### Self-Registration

Adapters are discovered automatically by `install-global.sh` via `discover.py`.
The discovery script reads all `manifest.yaml` files and outputs adapter metadata.
To add a new tool, drop a directory in `.opencode/scripts/adapters/` with a
`manifest.yaml` and `run.py` — no shell script changes needed.

## Git Provider Abstraction

The `/release` skill supports multiple Git providers via a provider abstraction layer
(`.opencode/scripts/adapters/git-providers/run.py`):

| Provider | CLI | Class |
| --- | --- | --- |
| GitHub | `gh` | `GitHubProvider` |
| GitLab | `glab` | `GitLabProvider` |
| Gitea | `gitea` (or manual) | `GiteaProvider` |

Provider detection is based on the `Provider:` field in `.team/context/pr-capabilities.md`.

**TODO:** Expand to full interface (branch creation, label management, CI status).

## Adding a New Tool

To add support for a new tool:

1. Create `.opencode/scripts/adapters/<tool>/manifest.yaml`
2. Create `.opencode/scripts/adapters/<tool>/run.py` implementing the `run()` interface
3. Optionally create `.opencode/scripts/adapters/<tool>/commands.py`
4. Register the tool type in `install-global.sh`'s `run_adapters_for_target()` if needed
5. Update `PORTABILITY.md` and `README.md`
6. Add tests for the adapter

## Adding a New Git Provider

To add support for a new Git provider:

1. Add a new class in `git-providers/run.py` implementing the `GitProvider` interface
2. Update the `detect_provider()` function to recognize the new provider
3. Update `.team/templates/pr-capabilities.md` to include the new provider option
