---
description: Analyze inbound federation candidates, recommend adopt/adapt/reject for each, and merge the baseline only after human approval (outbound version bump).
agent: pm
---

Delegate to the `federation` agent to absorb the staged inbox (use the `federation` skill):

1. For every candidate in `.team/federation/inbox/`, produce a recommendation: `ADOPT`, `ADAPT`,
   or `REJECT` with precise rationale (which file/line changes, why it generalizes).
2. Present the recommendations table to me and WAIT for my per-item decision. Never merge without it.
3. Only after my approvals, apply the changes to the baseline team files
   (prompts, skills, commands, `AGENTS.md`, or `opencode.json`), bump the version in
   `changelog.md`, and write the release snapshot into `releases/<version>/`.
4. Log every decision (adopt/adapt/reject) in `decisions.md`.

If a candidate is project-specific noise, mark REJECT with a one-line reason — don't rubber-stamp.