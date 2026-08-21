---
name: bootstrap
description: Used by the pm agent on /scrum-init to wire a target project into the scrum team: copy the team, run project discovery, seed .team/ state, and establish a green test baseline.
---

# Bootstrap (`/scrum-init`)

Initialize a project (default: current working directory) as a scrum team participant.

## Steps

1. **Identify the target** — the path given to `/scrum-init`, or the current project.
    Establish the worktree root and confirm git (init if missing and the user agrees).
2. **Copy the team** — from the baseline (this repo) into the target:
     - `AGENTS.md`, `CLAUDE.md`, `opencode.json`
     - `.opencode/agents/*`, `.opencode/skills/*`, `.opencode/commands/*`
     - `.team/scripts/` — team utility scripts (untracked; copied alongside .team/)
    Preserve file names; content comes from the baseline working tree.
3. **Discover the project** — capture facts into `.team/context/`:
    - `stack.md`: language(s), runtime, package manager, entry points
    - `test-harness.md`: exact test command, how to run one test, existing coverage
    - `git.md`: branch strategy, current state, CI commands if present
    - `pr-capabilities.md`: remote URL, default branch, PR creation status
4. **Seed the workspace** — create the `.team/` skeleton (`backlog.md`, `status.md`,
    `context/`, `checkpoints/`, `archive/`, `proposals/`, `scripts/`) from the
    `.opencode/templates/` skeletons and append `.team/` to `.gitignore`.
    **Agent files are optionally git-ignored.** In a **non-baseline** repo, default to NOT
    committing the agent files (`AGENTS.md`, `CLAUDE.md`, `opencode.json`, `.opencode/`) — the
    project's remote may not want the team tooling. Run `.team/scripts/ignore-team.sh --ignore` (the
    default) to append those rules; offer `--track` if the user wants them committed. In the
    **baseline** repo itself the agent files ARE tracked (they are the source of truth) — do not
    ignore them there. Ask the user once if unsure; never silently change their `.gitignore`.
5. **Baseline run** — delegate to `tester` to get the *existing* suite green before any
    feature work. Record that result in `.team/context/test-harness.md`. If the suite is red
    on init, that's a finding for the first backlog, not a blocker for init. **If discovery
    finds no test harness at all**, seed a backlog item `T0 — establish minimal test harness`
    (init the language's standard runner — pytest/vitest/etc. — with one smoke test) and record
    the canonical command in `test-harness.md`; `T0` becomes a dependency of every feature task
    so the first `/scrum` run builds the harness before any feature work.
6. **Report** — summarize to the human: what was installed, discovered facts, any open
    deviations, and the suggested first `/scrum` objective.

## Rules

- Never overwrite a target file that was already there unless the user approved the copy
   (diff first, list: "changes N files, overwrite?")
- Discovery must produce facts, not guesses: read real files/commands; record a command only
   if you verified it runs.
- Same-team portability: after bootstrap, `/scrum`, `/status`, `/retro`, `/install-global`, and `/release`
   must all work because the whole install is self-consistent.