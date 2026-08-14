---
description: Check and reconcile drift between the local baseline's working branch and its detected default branch (origin/<default>), folding upstream changes in per file while preserving local context.
agent: pm
---

Delegate to the `federation` agent (use the `federation` skill) to manage baseline↔default-branch drift:

1. Run `.team/scripts/drift-check.sh` and classify the working branch vs `origin/<detected-default>` (CLEAN / AHEAD / BEHIND /
   DIVERGED) and whether the tree is dirty. Report a compact status table.
2. If BEHIND or DIVERGED, run `.team/scripts/sync-origin.sh` to fold upstream `origin/<detected-default>` in —
   **per file**, prompting before each write. AGENTS.md is merged via `.team/scripts/merge-agents.sh`
   so the local tail (below the `BASELINE-OWNED CONTENT` marker) is preserved; other baseline
   files merge normally.
3. **Conflicts gate the bump (sync exit 1).** If `sync-origin.sh` exits 1, the sync did NOT
   complete — stop before any version bump or release snapshot. Real conflict pairs are written
   to `.team/federation/conflicts/<file>.{ours,upstream}` (AGENTS.md lives under `conflicts/`
   too). Report each pair to the human and wait for their call. Resolution paths:
   - Human resolves in the working tree and completes the merge themselves (`git commit` the
     resolved conflicts) — never `git merge --abort` while resolving, or
   - `git merge --abort` then re-run the sync after folding the upstream change in by hand.
   Only when the tree is conflict-free and `drift-check.sh` no longer reports BEHIND/DIVERGED
   do you proceed to the bump.
4. Once the sync is clean, if baseline-owned content changed, bump the version in `changelog.md` and
   write the `releases/<version>/` snapshot (a drift change without a bump is drift, not a release).
   A bump on a half-merged / conflicted tree is a false release — never allowed.
5. Re-run `.team/scripts/validate-team.sh`; report the result and any conflicts to me.

`sync-origin.sh` never reports a failed `git merge` as success: a merge that refuses (e.g. local
uncommitted changes it would overwrite) or leaves unresolved conflicts also exits 1. Scratch
artifacts under `.team/federation/conflicts/scratch/` are disposable; only the `.ours`/`.upstream`
pairs directly under `conflicts/` are human-reconciliation state.

Never force-push or rebase the default branch; only ever merge `origin/<detected-default>` into the working branch. Humans handle the merge of the working branch to the default branch.

Report: ahead/behind, files merged, files in conflict (or "blocked on conflicts"), any version bump.