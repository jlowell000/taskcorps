---
name: retro
description: Used after a scrum run to analyze what happened — pipeline flow, handoffs, gates, agent behavior — and write concrete human-approved improvement proposals into .team/proposals/. Invoked via /retro.
---

# Retro (run review → team improvement)

Turn the finished run's lessons into *proposals that change the team itself*.

## Inputs to read

- The run's checkpoint(s) and final `status.md` / `backlog.md` archive entries
- Task artifacts (`.team/tasks/<id>/`) and any `review.md` verdicts
- Notes the human or agents flagged during the run

## What to look for

- **Protocol failures**: handoffs that were missing, bloated, or ambiguous
- **Gate failures**: reviewers catching things tester/coder should have; tests claimed green but weren't
- **Context issues**: misread `.team/` on resume, overlong documents, stale context
- **Skill gaps**: steps agents had to improvise because the skill/agent prompt didn't cover them
- **Tool issues**: opencode config problems, permission blocking, adapter friction
- **Efficiency**: unnecessary stages, duplicate work, parallelizable steps run serially

## Proposal format (one file per proposal)

`/retro` writes each to `.team/proposals/<date>-<n>-<slug>.md`:

```markdown
# Proposal: <title>
- Problem: <observed fact, data where possible>
- Change: <concrete diff-level change to an agent, skill, command, AGENTS.md, or opencode.json>
- Target: <role/skill/command it affects>
- Expected impact: <what future runs will do better>
- Risk: <what could regress>
- Verdict: <proposed — PENDING, awaiting human>
```

## Rules

- **Human-gated**: proposals are proposals. They are only real team changes after the human
  reviews and applies (or says "apply it"). Never apply a retro proposal silently mid-session.
- One change per proposal; if a retro yields 3 changes, write 3 files — they are independently
  reviewable.
- Ground every "why" in something observed in the run you just read; "wouldn't it be nice"
  proposals get a `REJECT` in the retro summary the pm gives the human.

## Output to pm

Return a short retro summary: N proposals (titles + one-line each), which you recommend
adopting first, and which would stretch-quality gaps the most. Leave full detail in the files.