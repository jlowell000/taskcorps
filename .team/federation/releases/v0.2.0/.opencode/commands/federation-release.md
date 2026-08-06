---
description: Disseminate the current baseline release out to all registered project scrums, with per-project conflict handling.
agent: pm
---

Delegate to the `federation` agent to release the current baseline version (use the `federation` skill):

1. Re-read `.team/federation/registry.md`, `changelog.md`, and the `catalog/` snapshots.
2. For each registered project: diff `catalog/<project>/<version>/` → current release, apply the
   changed team files that the project hasn't locally modified, and update the catalog + registry.
3. For any file the project modified locally: DO NOT overwrite. Write the conflict into
   `.team/federation/conflicts/<project>-<file>.md` (project's version + baseline's new version) and list them for me.
4. Cross-project writes require the `external_directory` approval — surface each one.

Report: per project, files updated / files in conflict / new version recorded.