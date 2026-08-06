---
name: handoff
description: The team's inter-agent communication protocol. Use when reading or writing any document under .team/ — handoff blocks, status/backlog updates, task artifacts, or federation state — to produce consistent, compact, gated handoffs.
---

# Handoff Protocol

Every document in `.team/` is a handoff. The protocol is the only interface between agents.

## Core rules

- **Read before acting:** `status.md` → `backlog.md` → the task's `brief.md` → your stage's
  artifact → the previous stage's handoff. Never act on memory only.
- **Write before returning:** update your own artifact, then append a compact handoff block.
- **Own one artifact.** Roles own: designer → `spec.md` + `.team/context/`; coder → `impl.md`;
  tester → `report.md`; reviewer → `review.md`; pm → `backlog.md` + `status.md` + checkpoints.
- **Size budget:** keep every handoff to ~1–2 KB. Lead with deltas, not history. Padding is a defect.

## Handoff block format (append at the end of your artifact)

```markdown
---
**Handoff — <role>**
- Status: IN_PROGRESS | READY_FOR_<NEXT> | BLOCKED | DONE
- Changed: <deltas only, max ~5 bullets>
- Next: <role> must decide: <the exact question/decision that gates them>
- Notes: <contradictions, cross-cutting flags, or "none">
---
```

Allowable status tokens:

| Token | Meaning |
| --- | --- |
| `IN_PROGRESS` | Work started, not finished; other agents must not start the next stage |
| `READY_FOR_<role>` | Stage complete; the named role is cleared to begin |
| `BLOCKED` | Cannot proceed; the reason + what's needed is in the handoff |
| `DONE` | Reviewer-approved, suite green, task ready to archive |

## Gate vocabulary

Each stage's handoff must name the exact decision the next stage depends on:

- designer → coder: "spec + test plan ready; decisions the coder must not revisit: …"
- coder → tester: "change set + RED evidence complete; unknown/unproven: …"
- tester → reviewer: "suite green, TDD verified; unverified claims: …"
- reviewer → pm: `APPROVED` (archive) or `CHANGES_REQUESTED` (list of blockers)

## Failure handling

If the incoming handoff is missing, incomplete, or contradicts the brief, **do not guess**.
Return `BLOCKED` with the exact gap and inform `pm`. A guess sneaks a defect into the
pipeline and the reviewer will (rightly) reject the task.