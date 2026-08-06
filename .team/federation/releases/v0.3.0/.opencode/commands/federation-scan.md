---
description: Scan registered project scrums for improvement proposals and drift (inbound federation step).
agent: pm
---

Delegate to the `federation` agent (use the `federation` skill) to perform the inbound scan:

- Re-read `.team/federation/registry.md` and validate `registry.md` against reality.
- For each registered consumer (project or `type: global` host): for a project, read its
  `.team/proposals/` and diff its installed team files against the `catalog/<project>/<version>/`
  snapshot; for a `global` host (no `.team/`), diff its installed files against its catalog
  snapshot to detect user edits/version skew. Stage new material into `inbox/<consumer>/<date>/`
  — strictly read-only.
- Never modify the consumer here; never alter the baseline.

Report a compact summary: per project, how many proposals/diffs arrived and their one-line
gist, plus anything that looks project-specific vs generalizable. No baseline or project
mutations happen in this step; approval happens in federation-absorb.