---
description: Run the virtual dev team in full-auto on an objective, end to end.
agent: pm
---

Run a complete scrum session for: $ARGUMENTS

Follow this exact pipeline and drive it to completion:

1. READ first: `AGENTS.md`, `.team/status.md`, `.team/backlog.md`, latest checkpoint in `.team/checkpoints/` (if resuming).
2. PROMPT the human for the **working branch** name (no default); record it in the run id /
   checkpoint. Agents work on this branch; the default branch name is detected via
   `.opencode/scripts/default-branch.sh`, never hardcoded. **Humans** merge the working branch to the
   default branch — pm never merges or pushes to it.
3. CREATE the run id: `YYYYMMDD-<objective-slug>`; write it to `.team/checkpoints/README.md` as the `latest` pointer.
4. DECOMPOSE the objective into backlog items (use the `decompose` skill) with **run-scoped ids** (`<run>-T<n>`). Create `.team/tasks/<run>-T<n>/` folders with `brief.md`.
5. DISPATCH each task in dependency order through the team, gating every stage:
   - designer → `spec.md` (including test plan) — stop/BLOCKED if brief is unclear
   - coder → TDD `impl.md` (RED evidence mandatory)
   - tester → `report.md` (prove red-first, full suite green)
   - reviewer → `review.md` (`APPROVED` / `CHANGES_REQUESTED`; loop back on blockers, max 3 iterations, then escalate to me)
   Scope cap: dispatch at most 5 tasks per run; mark the rest `QUEUED` in `backlog.md`. If the objective decomposes to more than 5 tasks, ask me once before dispatching.
6. CHECKPOINT + ARCHIVE at every stage transition (use the `context-management` skill).
7. REPORT back to me plainly: what was delivered, what was deferred (queued for next run), what needs my decision.

You are the only one who talks to me; I want a crisp summary at the end, not a play-by-play.