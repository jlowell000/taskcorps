---
name: release
description: Used by the pm agent on /release to turn approved retro proposals into a PR against the taskcorps remote default branch. Reads .team/proposals/ and .team/context/pr-capabilities.md. Baseline-only skill — never installed globally.
---

# Release (approved proposals → PR)

Turn approved retro proposals into a pushed branch + PR against the taskcorps remote.

## Inputs to read

1. `.team/context/pr-capabilities.md` — confirm PR creation is enabled; read the remote URL and default branch.
2. `.team/proposals/` — list all pending proposals. The human designates which are approved for this release.

## Procedure

1. **Confirm PR capabilities.** Read `.team/context/pr-capabilities.md`. If `Enabled` is `no`, print the path to `enable-pr-setup.md` (in `.team/context/`) and abort. Do not attempt PR creation without explicit enablement.

2. **Create a release branch.** Name it `retro-YYYYMMDD-<slug>` where `<slug>` is a short kebab-case summary of the release (e.g., `retro-20260821-remove-federation`). Check it out from the current default branch.

3. **Apply approved proposals.** For each proposal the human approved:
   - Read the proposal's `Change:` field — it describes a concrete diff-level change.
   - Make the change to the specified agent, skill, command, `AGENTS.md`, or config file.
   - If the proposal references a file that no longer exists (e.g., a federation file already removed), note it as `superseded` and skip.

4. **Commit and push.** Stage only the files changed by the proposals. Commit with a message listing the proposal filenames. Push the branch to origin.

5. **Open a PR.** Use `gh pr create` with:
   - `--base` set to the configured default branch from `pr-capabilities.md`
   - `--head` set to the release branch name
   - Title: `retro: <slug>` (e.g., `retro: remove federation, move to global install`)
   - Body: list each approved proposal with its filename and one-line summary
   - `--label` `retro` if that label exists on the repo (non-fatal if it doesn't)

6. **Record the PR URL.** Append it to `.team/checkpoints/<run-id>.md` or write a new checkpoint so the human can find it.

## Rules

- **No silent changes.** Every proposal change is visible in the PR diff. If a proposal is superseded by the refactor itself, note that in the PR body rather than silently skipping.
- **No version bump.** There is no `CURRENT_VERSION`, `changelog.md`, or release snapshot. The PR IS the release.
- **Do not touch the default branch.** The release branch is short-lived; merge stays human-gated.
- **Scope discipline.** Only apply the proposals the human approved. Do not bundle unrelated changes.
- **Baseline-only.** This skill is in `.opencode/skills/release/SKILL.md` in the taskcorps repo. It is never installed into project or global configs.

## Output to pm

Return the PR URL and a one-line summary of what changed. If PR creation failed, report the exact `gh` error so the human can act.
