---
name: decompose
description: Used by the pm agent to turn an objective into an ordered, testable backlog in .team/backlog.md with acceptance criteria, dependencies, and sizing.
---

# Decompose

Turn a human objective into backlog items the team can actually execute.

## Run identity (pm creates it first)

Every `/scrum` run gets a run id: `YYYYMMDD-<objective-slug>` (e.g. `2026-08-06-auth-refactor`).
**The `YYYYMMDD` prefix is taken from today's date (the current calendar year), never a typed
year from context.** Compute it from the system clock at `/scrum` start. pm prints the computed
run id (e.g. `2026-08-07-…`) before scaffolding task folders so a stale or typo'd year is
caught immediately. Task ids
are **run-scoped**: `<run>-T<n>` (e.g. `2026-08-06-auth-refactor-T1`). This keeps ids
unambiguous across runs and makes checkpoints/archive references collision-free.

## Procedure

1. Read `AGENTS.md`, `.team/status.md`, `.team/backlog.md`, and the objective.
2. Split the objective into the smallest shippable increments that still each satisfy a
   *user-observable* outcome. Prefer vertical slices (thin end-to-end) over horizontal layers.
3. For each item write:

```markdown
## <run>-T<id> — <title>
- Status: TODO | QUEUED | ASSIGNED | IN_DESIGN | IN_IMPL | IN_TEST | IN_REVIEW | DONE | BLOCKED
- Depends on: <run>-T<other id> or none
- Size: S | M | L
- Acceptance criteria:
  1. <observable, testable statement>
  2. …
- Notes: <context for designer>
```

4. Order by dependency + size + risk. Small, high-dependency items first so the designer can
   unblock the critical path.
5. Give tasks to the pipeline in dependency order; a task must not start before its
   dependencies are `DONE`.
6. **Scope cap**: dispatch at most `N` tasks per run (default `N=5`, pm-configurable). Any
   task beyond the cap is marked `QUEUED` (with its dependencies) and stays in `backlog.md`
   for the next run. If the objective decomposes to more than `N` tasks, ask the human once
   before dispatching: "run this batch now, or re-scope?"

## Acceptance-criteria rules

- Each criterion is **observable**: you could write a test that asserts it.
- No "should be nice" or "handle errors well" — say *which* errors and *how* they are handled.
- Every criterion must be mappable to at least one test in the designer's test plan.

## Status transitions (owned by pm)

`TODO → ASSIGNED/IN_DESIGN → IN_IMPL → IN_TEST → IN_REVIEW → DONE → archived`
`QUEUED` means "decomposed but outside this run's scope cap" — it becomes `TODO` at the start
of a later run. Only pm changes status. `BLOCKED` always carries a reason + re-plan in the
checkpoint.