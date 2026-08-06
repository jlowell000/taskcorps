---
name: federation
description: Used by the federation agent to run the baseline loop — scan registered project scrums, absorb their improvement proposals into the baseline (human-approved), version releases, and disseminate them back, with per-project conflict handling.
---

# Federation (the baseline loop)

This repo is the baseline. Registered projects are other scrums installed via `scrum-init`.

## State (`.team/federation/`)

| Path | Contents |
| --- | --- |
| `registry.md` | one row per project: id, path, installed version, last sync date |
| `inbox/<project>/<date>/` | proposals, diffs, exports pulled **read-only** from a project |
| `decisions.md` | adopt/adapt/reject for every item reviewed, with rationale |
| `changelog.md` | version-numbered releases; every baseline change bumps a version |
| `releases/<version>/` | snapshot of the team files at that release |
| `catalog/<project>/<version>/` | snapshot of what that project last received (the diff base) |
| `conflicts/` | project-local changes that a release refuses to overwrite |

## Current version (source of truth)

The **current baseline version** is the top line of `changelog.md` (`CURRENT_VERSION: vX.Y.Z`).
`federation-release` asserts every registered project's `catalog/<project>/<version>/` is ≤
`CURRENT_VERSION` before applying; a release that forgets the bump is drift, not a release.

## Registration (project ↔ baseline link)

Every project initialized by `scrum-init` carries `.team/federation/baseline.md` recording its
**primary baseline** (path or git URL) and the installed version. Registration is two-sided:
1. Project writes `baseline.md` (baseline path + installed version) during bootstrap.
2. Baseline records the project in `registry.md` (id, path, installed version) and takes the
   first `catalog/<project>/<version>/` snapshot as the diff base.
A project may have one primary baseline; multi-baseline sync is out of scope.

## Inbound (scan → absorb)

- **Scan**: read each registered project's `.team/proposals/` and diff its installed
  `.opencode/` + `AGENTS.md` against `catalog/<project>/<version>/`. Stage new material in
  `inbox/` read-only. Never modify the project here.
- **Analyze**: for each candidate, ask: does this make *every* team better, or is it
  project-specific? Generalize accordingly → `ADOPT` / `ADAPT` / `REJECT (+ why)`.
- **Absorb**: present the decisions to the human. **Merge the baseline only after approval**
  (per item). Merged changes create release `next` in `changelog.md` and a `releases/<version>/`
  snapshot.
- Baseline changes made directly here (e.g. this repo's own retro) go through the same bump.

## Outbound (release)

For each project in `registry.md`:
1. Compute the delta between `catalog/<project>/<version>/` and the current release.
2. Apply the files that the project has NOT locally modified. Update the catalog to the new
   version.
3. Locally modified files are **not overwritten**: write the conflict (+ the baseline's new
   version of the file) into `conflicts/` and flag for the human to reconcile.
4. Record the applied version + date in `registry.md`.

## Safety rules

- Never read a project's private state beyond `.team/proposals`, federation/exports, and the
  installed team files.
- Never write into a project without an approved `external_directory` write (this is `ask` in
  the baseline `opencode.json`).
- Every baseline mutation must pair with a `changelog` entry; otherwise it's not a release, it's drift.
- Verdicts over evidence way outdistance vibes: say precisely which file/line/text changed.