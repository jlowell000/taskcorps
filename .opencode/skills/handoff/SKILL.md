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

## Tight-context contract (all agents)

Subagents run on tight contexts. Follow these rules so a small context never silently fails:

- **Inputs by path, not value.** Dispatches and handoffs reference files by path; read only what
  you need, in small slices (grep/Read), never whole files into context.
- **Deltas only.** Return compressed deltas (what changed, files, verdicts, next-owner question)
  ≤ ~1–2 KB. No full-file echoes, no repeated history.
- **Never return tool-call JSON as a result.** A final message is a summary (or empty only if
  the artifact carries everything — then say so explicitly).
- **Budget guard.** If a task needs more context than you have, stop and report
  `BLOCKED: needs more context` with the specific file — do not guess or retry with a bigger
  prompt.
- **Read-back after every write.** After any Write/Edit, Read the file back and confirm it
  exists with the expected content before declaring the stage done. A missing artifact is a
  failure, not a handoff.
- **Empty results are a defect.** Your final message must be a non-empty summary (or explicit
  `BLOCKED`). Whitespace-only results are indistinguishable from "did nothing".

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