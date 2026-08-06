# Taskcorps — a self-improving virtual AI dev team

A team of cooperating AI agents that plan, design, implement, test, and review software work —
plus a **federation loop** that improves the team itself and propagates improvements to every
project that runs it.

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
| `federation` | Baseline loop: absorb + release improvements | `.team/federation/` |

## Commands

| Command | What it does |
| --- | --- |
| `/scrum-init [path]` | Install the team into a project, run discovery, seed `.team/`, establish a green baseline |
| `/scrum "<objective>"` | Full-auto run: decompose → design → code → test → review → report |
| `/status` | Show the current team board |
| `/retro` | Review the last run; write human-approved proposals to improve the team |
| `/federation-scan` | Pull proposals and drift from registered project scrums |
| `/federation-absorb` | Analyze candidates → your approval → merge + bump baseline version |
| `/federation-release` | Roll the current baseline version out to registered scrums |

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
  write a compact handoff block before returning, stay ≤ ~2 KB, never edit another role's file
  (see the `handoff` skill).
- **Context is owned by pm**: durable state lives in `.team/` (gitignored), checkpoint at every
  gate, compress + archive continuously (`context-management` skill).
- **TDD is enforced**: a task is not `DONE` until RED is proven, the suite is green, and the
  reviewer approves (`testing`, `review` skills).

## Federation (the improvement loop)

- **Inbound**: registered projects run their own retros; `federation-scan` pulls their
proposals/drift, `federation-absorb` reviews each (ADOPT / ADAPT / REJECT) and — **only after
human approval** — merges the winners into the baseline and bumps a version.
- **Outbound**: `federation-release` diffs each project against the snapshot it last received,
  applies the delta, and files locally-modified conflicts for you to adjudicate.

Cross-project writes surface as `external_directory` approval requests — the baseline never
mutates a project silently.

## Workspace layout

```
AGENTS.md            # team contract loaded into every agent (roles, protocol, TDD, DoD)
opencode.json        # default_agent: pm, auto-compaction, external_directory: ask
CLAUDE.md            # @AGENTS.md shim for Claude Code compatibility
.opencode/agents/    # the six agents
.opencode/skills/     # handoff, decompose, design, testing, review, retro, bootstrap, context-management, federation
.opencode/commands/   # the commands above
.team/               # gitignored runtime state: backlog, status, context, tasks, checkpoints, archive, proposals, federation
.opencode/templates/ # canonical skeletons for team documents (baseline-owned)
```

## Portability

The team is authored to run across AI coding tools:
- Skills use only the portable `name` + `description` frontmatter (Agent Skills open standard)
- Agent bodies avoid tool-specific wording; tool glue stays in frontmatter / `opencode.json`
- `AGENTS.md` is the canonical contract, imported into Claude Code via `CLAUDE.md`
- Added adapters simply re-render these sources; never fork the content

## Get started

1. `/scrum-init .` — self-initialize this repo (dogfood the team)
2. `/scrum "pick a real first feature"` — run the team
3. `/retro` — and iterate using the team's own learnings

## License

Private/undecided — decide before redistribution.