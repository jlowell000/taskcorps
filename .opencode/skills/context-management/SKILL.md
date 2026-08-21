---
name: context-management
description: Used by the pm agent to keep the team's context small and resumable: size budgets, checkpoints at every gate, archiving, and delegation of heavy reads to subagents.
---

# Context Management (pm-owned)

The durable home of all team state is `.team/`. Chat memory is not durable state.

## Concrete duties

1. **Size budgets**
   - Every handoff document ≤ ~1–2 KB. When one grows (say after 2–3 rounds of edits),
     compress it: history moves to a `## History` one-liner, decisions stay.
   - Keep `backlog.md` and `status.md` tight: one line per completed task in `backlog.md`.
   - When inlining tabular data into checkpoints, summaries, or dispatches, convert
      markdown tables to **TOON format** (via `.opencode/scripts/toon_table.py --encode` or the
     `toon-format` skill) to reduce token cost by 30–70%. Canonical on-disk format
     stays markdown; TOON is the transport form.
2. **Checkpoints at every gate**
   Every run has a run id (`YYYYMMDD-<objective-slug>`), created by pm at `/scrum` start and
   recorded in `.team/checkpoints/README.md` as the `latest` pointer. After every stage
   transition (design done, impl done, test done, review done) write
   `.team/checkpoints/<run>/<run>-T<n>-<stage>.md`:

   ```markdown
   # Checkpoint — run <id>, task T<id>, stage <stage>
   - Status: <board state at this instant>
   - Done: <deltas>
   - Open: <exactly what the next resume must re-do or re-decide>
   - Next: <>; role + decision>
   ```

   A checkpoint must be sufficient to resume the run in a brand-new session with no chat memory.
   Keep `.team/checkpoints/README.md` updated: current run id, the most recent checkpoint
   path, and the next gated role. Any fresh session reads that README first and resumes
   deterministically.
   **Pair every checkpoint with a `status.md` board update** at the same gate: set the task's
   stage/owner (designer→coder→tester→reviewer) so the live board is never stale mid-run. Do
   not wait until archive to update the board.
3. **Archiving**
   - On `DONE`, move `.team/tasks/<id>/` into `.team/archive/<year>-<month>/` and keep one
     line in `backlog.md`.
   - Archive after the `review.md` verdict is `APPROVED`, never before.
4. **Delegated reading**
   - Do not pull whole code files or long docs into your own context. Delegate reads to
     subagents or `explore` and ingest only the compressed answer they return.
5. **Run hygiene**
   - Tell the human when a session has been running long enough that compaction is likely.
   - Assert `.team/` is consistent before starting the next stage: read `status.md` first.
   - **Precondition: clean/ignored team state.** Before dispatching the first task of a run,
     verify the team git-ignore policy is in effect and committed: `.gitignore` excludes
     `.team/` and agent tooling, those files are not tracked (`git ls-files`), and any missing
     ignore change is committed on the working branch. Treat as a gated precondition like the
     green baseline, so `.team/` never leaks into feature branches/PRs.
   - **Park incomplete runs.** Whenever a run ends with any task `BLOCKED`, `IN_IMPL`, or
     `IN_REVIEW`, append a `## Open / parked` section to `status.md` (or refresh the existing
     one) with one line per parked task:
     `- <task id> — <stage>: <where its uncommitted edits live>`
     (e.g. `- 20260807-T3 — IN_IMPL: uncommitted changes in .opencode/…, AGENTS.md`).
     A fresh pm reads this section first on resume and either resumes, parks, or reverts —
     never guesses.

## Anti-patterns to avoid

- Storing important facts in chat that were never written to `.team/`.
- Rewriting someone's `.team/` artifact wholesale (compress, never destroy their deltas).
- Letting a stage start on a stale checkpoint: always fresh-read `status.md` + the relevant
  artifact before the first action of that round.