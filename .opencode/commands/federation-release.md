---
description: Disseminate the current baseline release out to all registered project scrums, with per-project conflict handling.
agent: pm
---

Delegate to the `federation` agent to release the current baseline version (use the `federation` skill):

1. Re-read `.team/federation/registry.md`, `changelog.md`, and the `catalog/` snapshots.
2. For each registered consumer: diff `catalog/<consumer>/<version>/` → current release, apply the
   changed team files that the consumer hasn't locally modified, and update the catalog + registry.
   **AGENTS.md is written via `.team/scripts/merge-agents.sh`** (baseline-owned content merged above the
   marker, project tail preserved below); a failed merge is a conflict, never an overwrite.
   For a `type: global` host, skip the user-owned config set (`opencode.json[c]`, `.gitignore`,
   `package*.json`, `node_modules/`) — those are permanent excludes.
3. For any file the consumer modified locally: DO NOT overwrite. Write the conflict into
   `.team/federation/conflicts/<consumer>-<file>.md` (consumer's version + baseline's new version) and list them for me.
4. Cross-consumer writes require the `external_directory` approval — surface each one.

Report: per project, files updated / files in conflict / new version recorded.