---
description: Run a retrospective of the last scrum run and write human-approved proposals for improving the team itself.
agent: pm
---

Use the `retro` skill to review the last run:

1. Read the run's checkpoints, `.team/status.md`, task folders, and review verdicts.
2. Analyze pipeline, handoffs, gates, context, skills, tooling for failures worth fixing.
3. Write each change as a separate proposal into `.team/proposals/<date>-<n>-<slug>.md` with the exact
    format from the skill (problem, change, target, expected impact, risk, verdict: pending).

Then report back a summary list of the proposals and which you recommend for adoption.
General team changes (agents, skills, commands, AGENTS.md) can be released via `/release`
after human approval. Project-specific changes are applied directly to the project's `.team/`
files. Do NOT apply any proposal to the team config unless I explicitly approve it.