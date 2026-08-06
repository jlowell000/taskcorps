---
description: Scan registered project scrums for improvement proposals and drift (inbound federation step).
agent: pm
---

Delegate to the `federation` agent (use the `federation` skill) to perform the inbound scan:

- Re-read `.team/federation/registry.md` and validate `registry.md` against reality.
- For each registered project: read its `.team/proposals/`, diff its installed team files against the
  `catalog/<project>/<version>/` snapshot, and stage new material into `inbox/<project>/<date>/` — strictly read-only.
- Never modify the project here; never alter the baseline.

Report a compact summary: per project, how many proposals/diffs arrived and their one-line
gist, plus anything that looks project-specific vs generalizable. No baseline or project
mutations happen in this step; approval happens in federation-absorb.