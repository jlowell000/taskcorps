---
description: Initialize a project into the scrum team: install the team files, run discovery, seed .team/ state, and establish a green test baseline.
agent: pm
subtask: true
---

Run the `bootstrap` skill to initialize the target project into the scrum team.

Target project: $ARGUMENTS (if empty, the current project). Fully neutral portability rules apply
(project:: agents/skills/commands copied from the baseline, portable frontmatter only).

Before starting, tell me: files it will add/overwrite (diff first), the discovery facts you will
record, and anything that looks risky (no existing tests, red suite, non-git tree). If no test
harness exists, plan to seed a `T0 — establish minimal test harness` backlog item as a
dependency for all feature work. Do not destructively overwrite anything without asking me first.