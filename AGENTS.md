# Taskcorps Team Contract

This repo operates as a **virtual dev team**: a set of cooperating agents that plan, design,
implement, test, and review work, plus a federation loop that constantly improves the team
itself and propagates improvements to every project running this team.

Every agent on the team reads this file. It is the single source of truth for roles, the
handoff protocol, TDD discipline, and the definition of done.

---

## 1. Roles

| Role | File | Responsibility |
| --- | --- | --- |
| `pm` (primary) | `.opencode/agents/pm.md` | Orchestrator, backlog owner, context steward. Kicks off runs, dispatches work, gates stages, reports to the human. |
| `designer` | `.opencode/agents/designer.md` | Architects solutions, keeps the holistic system view (`.team/context/`), writes implementation specs + test plans. |
| `coder` | `.opencode/agents/coder.md` | Implements each task strictly TDD: RED → GREEN → REFACTOR. |
| `tester` | `.opencode/agents/tester.md` | Verifies the test harness, proves red-first discipline, runs the full suite, hunts edge cases and bugs. |
| `reviewer` | `.opencode/agents/reviewer.md` | Hyper-critical read-only quality gate. Verdict: `APPROVED` or `CHANGES_REQUESTED`. Never edits user/team work. |
| `federation` | `.opencode/agents/federation.md` | Runs the baseline loop: absorbs improvements proposed by registered project scrums and rolls baseline versions back out. |

## 2. Team workspace (`.team/`)

All inter-agent state lives in this directory. It is never reconstructed from
memory, and every agent must re-read from `.team/` when the session resumes.
Run state is gitignored; federation durable state is tracked (see below).

```
.team/
  backlog.md            # pm-owned: tasks, acceptance criteria, deps, sizing, status
  status.md             # live "who owns what / stage" board
  context/              # designer-owned: system map, stack.md, adrs/*.md
  tasks/<id>/           # one folder per task
    brief.md            # pm: scope + acceptance criteria
    spec.md             # designer: design + test plan
    impl.md             # coder: TDD record + what changed
    report.md           # tester: results + findings
    review.md           # reviewer verdict
  checkpoints/          # pm compression: state-of-run snapshots (README.md = latest pointer)
  archive/              # completed task folders (one-liners stay in backlog)
  proposals/            # retro output -> changes for the team itself (human-approved only)
  federation/           # baseline sync state: registry, inbox, decisions, changelog, catalog, conflicts
```
Git tracking (`.gitignore`): **all of `.team/` is ignored and never committed.** Run state
(`backlog.md`, `status.md`, `context/`, `tasks/`, `checkpoints/`, `archive/`, `proposals/`) and
federation state (`registry.md`, `decisions.md`, `changelog.md`, `releases/`, `conflicts/`,
`inbox/`, `catalog/`) are all local/ephemeral — they survive only on this machine, not clones.
The baseline's canonical files live in `.opencode/`; release snapshots are regenerated, not
versioned in git. This repo also runs `scripts/validate-team.sh` to self-check baseline
consistency; run it before releases.

Canonical skeletons for every document above live in `.opencode/templates/` (baseline-owned,
versioned, copied at `scrum-init`).

Each handoff file (below) ends with the short **handoff block**: status token, what was done
(deltas), and the exact question/decision that gates the next role.

## 3. Handoff protocol (the team's language)

Handoffs are the only interface between agents. Every agent obeys these rules:

1. **Read before acting.** In this order: `status.md` → `backlog.md` → the task's
   `brief.md` → the current artifact at your stage (`spec.md` / `impl.md` / `report.md` /
   `review.md`) → and the handoff left by the previous stage. If the input handoff or its
   artifact is missing or incomplete, **stop and flag it**; never guess.
2. **Write before returning.** Every agent updates its own artifact and leaves a short,
   signed-off handoff block containing:
   - Status token: `IN_PROGRESS` / `READY_FOR_<NEXT>` / `BLOCKED` / `DONE`
   - What changed, deltas only (never repeat full history)
   - Explicit next-owner note + the exact decision that gates the next role
   - Anything that contradicts the input handoff, with reasons
3. **Ownership.** Each agent owns exactly one artifact. Never edit another role's file; raise
   cross-cutting concerns by flagging them in your own handoff and informing `pm`.
4. **Size budget.** Handoffs stay ≤ a few paragraphs (~1–2 KB). `pm` rewrites/compresses stale
   documents; do not pad. Verbosity is a reviewable defect.
5. **Strict verification.** A task is only `DONE` after `reviewer` returns `APPROVED` and
   `tester` confirms the whole suite is green.

## 4. Pipeline (the run loop)

1. `pm` decomposes the objective into `backlog.md`, then prepares one folder per task.
2. `designer` produces `spec.md` for the task — including a **test plan** and any ADR.
3. `coder` writes a failing test per acceptance criterion (RED), implements the change (GREEN),
   then refactors (REFACTOR), and records it all in `impl.md`.
4. `tester` verifies the tests actually failed for the right reasons, runs the full suite,
   hunts edge cases, and records `report.md`.
5. `reviewer` hyper-critically reviews `spec` + `impl` + `report` and writes `review.md`:
   `APPROVED` → the task is done and archived; `CHANGES_REQUESTED` → back to coder/tester; iterate.
6. `pm` writes a checkpoint in `checkpoints/` at every stage transition, updates `status.md,
   and reports to the human.

The team runs **full-auto**: `/scrum "<objective>"` drives this end to end. The human is asked
only when truly blocking (scope, gates, adopt/reject decisions). Retrospective proposals are
offered separately via `/retro` and are never applied silently.

## 5. Context management (pm-owned)

- Durable state lives in `.team/`, never in chat memory.
- Handoffs stay small; `pm` compresses before dispatch.
- A checkpoint goes to `.team/checkpoints/` at each gate so any run survives compaction and can
  be resumed after interruption.
- Completed tasks move to `.team/archive/`.
- `pm` delegates heavy reads to the team and ingests only
  compressed results, keeping its own context lean.
- Use the `context-management` skill for the concrete duties.

## 6. Definition of done

A task is `DONE` only when **all** hold:

- [ ] Spec exists and was followed (deviations recorded in `impl.md`)
- [ ] New tests existed and failed **before** the implementation (TDD proven)
- [ ] Full suite is green on the final code
- [ ] `reviewer` returned `APPROVED` with no open blockers
- [ ] Handoffs + `status.md` consistent and updated; task archived

## 7. Portability rules

This team is authored to be portable across AI coding tools (Claude Code, Codex, Cursor, IDE agents).

- Skills: only `name` + `description` frontmatter.
- Storage: everything else is plain markdown; no tool-specific APIs in prompts.
- To adopt a new tool adapter, render new config/shell files from the same sources of truth
  (`.opencode/agents`, `.opencode/skills`, `AGENTS.md`) instead of forking the content.
- `AGENTS.md` is canonical; `CLAUDE.md` (`@AGENTS.md`) imports it for Claude Code.

## 8. Federation (baseline loop)

This repo is the **baseline**: the canonical team other projects install via `scrum-init`
and upgrade from. The `federation` agent and skill implement the loop: registered scrums
(and machine-global `type: global` hosts) propose improvements; the baseline analyzes and
adopts (with human approval) generalized versions, then disseminates them back. Never change
the baseline without a `federation/changelog` entry and a release bump.

- **Project appends**: child teams keep local, project-specific additions to `AGENTS.md`
  **below** the baseline-owned marker at the end of this file. Releases replace only
  baseline-owned content above the marker (`scripts/merge-agents.sh`) and preserve the tail.
- **Working branch**: at the start of each run the human is prompted for the **working branch**
   name (no default); agents work on it. The **default branch** name is **detected**, never
   hardcoded (`scripts/default-branch.sh`).
- **Drift**: the local repo's baseline rides on the working branch and reconciles the detected
   default branch (`origin/<default>`) into it via `scripts/drift-check.sh` +
   `scripts/sync-origin.sh` (per-file prompts). A drift sync that changes baseline-owned content
   must also bump the version + changelog. **Humans merge the working branch to the default
   branch; agents never push to it.**

## 9. Agent instructions

- Keep every file small, documented, and consistent with the templates.
- Never apply retro proposals without the human reviewing them; never release the baseline un-confirmed.
- Use the team skills (`handoff`, `context-management`, `testing`, `federation`, …).

---

<!-- ======================================================================
     BASELINE-OWNED CONTENT — do not edit above this marker.
     Project/team-specific additions belong BELOW this line only.
     The federation release surgically replaces baseline-owned content
     (everything above) and preserves everything below. Local appends and
     drift reconciliation (<main> vs <origin/main>) rely on this boundary.
     ====================================================================== -->