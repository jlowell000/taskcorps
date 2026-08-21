# Taskcorps — a self-improving virtual AI dev team

A team of cooperating AI agents that plan, design, implement, test, and review software work.
Retros improve the team directly; approved changes become PRs against the baseline and
propagate via global install.

This repo is the **baseline**: the canonical team definition that other projects install and
upgrade from. It dogfoods its own team.

## The team

| Agent | Role | Owns |
| --- | --- | --- |
| `pm` | Orchestrator, backlog owner, context steward (the only primary agent) | `.team/backlog.md`, `status.md`, `checkpoints/` |
| `designer` | Architect, keeps the holistic view | `.team/tasks/<id>/spec.md`, `.team/context/`, ADRs |
| `coder` | Strict TDD implementation (RED → GREEN → REFACTOR) | `impl.md` |
| `tester` | Proves red-first, runs the full suite, hunts bugs | `report.md` |
| `reviewer` | Hyper-critical read-only quality gate | `review.md` — `APPROVED` only |

## Commands

| Command | What it does |
| --- | --- |
| `/scrum-init [path]` | Install the team into a project, run discovery, seed `.team/`, establish a green baseline |
| `/scrum "<objective>"` | Full-auto run: decompose → design → code → test → review → report |
| `/status` | Show the current team board |
| `/retro` | Review the last run; write human-approved proposals to improve the team |
| `/install-global` | Install the latest team files to global tool configs (opencode, deepseek) |
| `/release` | Create a PR from approved retro proposals against the baseline remote |

## How a run works

```
/scrum "objective"
  pm decomposes → designer writes spec + test plan
  → coder implements test-first (RED proven per criterion)
  → tester verifies TDD + runs the full suite
  → reviewer gates (APPROVED / CHANGES_REQUESTED); pm loops back on blockers
  → pm checkpoints every gate, archives done work, reports to you
```

Rules that make the team work:

- **Handoff protocol** is the only interface between agents: read `.team/` before acting,
  write a compact handoff block before returning, stay <= ~2 KB, never edit another role's file
  (see the `handoff` skill).
- **Context is owned by pm**: durable state lives in `.team/` (gitignored), checkpoint at every
  gate, compress + archive continuously (`context-management` skill).
- **TDD is enforced**: a task is not `DONE` until RED is proven, the suite is green, and the
  reviewer approves (`testing`, `review` skills).
- **Retros drive improvement**: after each run, `/retro` writes proposals to `.team/proposals/`.
  General team changes become PRs against this repo via `/release`; project-specific changes
  are applied locally.

## Global install model

This repo is the **baseline** — the canonical team definition that other projects install and
upgrade from. The team is installed as modular files into each tool's config directory:

- **Opencode**: files land in `<config>/.opencode/{agents,commands,skills,templates}/` plus
  `AGENTS.md` at the root. Run `/install-global` to sync.
- **Deepseek**: files land in `<config>/.agents/{skills,notes/agents,notes/commands,notes/templates}/`.
  The harness's own `AGENTS.md` is never overwritten; taskcorps `AGENTS.md` is installed as
  `.agents/notes/taskcorps-AGENTS.md`.

User-owned config files (`opencode.json`, `settings.yaml`, `.env`, etc.) are never touched.

## Workspace layout

```
AGENTS.md            # team contract loaded into every agent (roles, protocol, TDD, DoD)
CLAUDE.md            # @AGENTS.md shim for Claude Code compatibility
opencode.json        # default_agent: pm, auto-compaction, external_directory: ask
.opencode/agents/    # the five agents
.opencode/skills/     # handoff, decompose, design, testing, review, retro, release, bootstrap, context-management
.opencode/commands/   # the commands above
.team/               # gitignored runtime state: backlog, status, context, tasks, checkpoints, archive, proposals, scripts
.opencode/templates/ # canonical skeletons for team documents
```

## Portability

The team is authored to run across AI coding tools:
- Skills use only the portable `name` + `description` frontmatter (Agent Skills open standard)
- Agent bodies avoid tool-specific wording; tool glue stays in frontmatter / `opencode.json`
- `AGENTS.md` is the canonical contract, imported into Claude Code via `CLAUDE.md`
- Added adapters simply re-render these sources; never fork the content

## Initialize a project

This repo is the **baseline** — the canonical team definition that other projects install and
upgrade from. To wire a project into the team:

1. **Make the baseline reachable.** Clone it (or have it on disk) so the team files are
    available, e.g. `git clone git@github.com:jlowell000/taskcorps.git`.
2. **Run `/scrum-init`.** In the target project, run `/scrum-init <path>` (defaults to the
    current directory). The `pm` agent:
    - **copies the team** — `AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.opencode/` (agents,
      skills, commands) — asking before overwriting anything in the project;
    - **discovers** the project into `.team/context/`: `stack.md` (language, runtime, package
      manager), `test-harness.md` (verified test command), `git.md`, `pr-capabilities.md`;
    - **seeds** the `.team/` skeleton (`backlog.md`, `status.md`, `context/`, `checkpoints/`,
      `archive/`, `proposals/`, `scripts/`) and appends `.team/` to the project's `.gitignore`;
    - **establishes a green baseline**: gets the existing suite green first; if there is no test
      harness, seeds backlog item `T0 — establish minimal test harness` as a dependency of all
      feature work.
3. **Run the team.** `/scrum "<first objective>"`, then `/status`, `/retro`, and `/install-global`
   to keep the team files up to date across your tools.

## Get started

- **Self-host the team**: `/scrum-init .` in this repo (dogfooding).
- **Run a feature**: `/scrum "pick a real first feature"`.
- **Improve the team**: `/retro` after each run, then `/release` to open a PR against the baseline.
- **Bring the team to a project**: see [Initialize a project](#initialize-a-project).

## License

MIT — Copyright (c) 2026 jlowell000. See [LICENSE](LICENSE).
