---
description: Check and reconcile drift between the local baseline's working branch and its detected default branch (origin/<default>), folding upstream changes in per file while preserving local context.
agent: pm
---

Delegate to the `federation` agent (use the `federation` skill) to manage baseline↔default-branch drift:

1. Run `scripts/drift-check.sh` and classify the working branch vs `origin/<detected-default>` (CLEAN / AHEAD / BEHIND /
   DIVERGED) and whether the tree is dirty. Report a compact status table.
2. If BEHIND or DIVERGED, run `scripts/sync-origin.sh` to fold upstream `origin/<detected-default>` in —
   **per file**, prompting before each write. AGENTS.md is merged via `scripts/merge-agents.sh`
   so the local tail (below the `BASELINE-OWNED CONTENT` marker) is preserved; other baseline
   files merge normally. True file conflicts go to `.team/federation/conflicts/`.
3. After the sync, if baseline-owned content changed, bump the version in `changelog.md` and
   write the `releases/<version>/` snapshot (a drift change without a bump is drift, not a release).
4. Re-run `scripts/validate-team.sh`; report the result and any conflicts to me.

Never force-push or rebase the default branch; only ever merge `origin/<detected-default>` into the working branch. Humans handle the merge of the working branch to the default branch.

Report: ahead/behind, files merged, files in conflict, any version bump.
