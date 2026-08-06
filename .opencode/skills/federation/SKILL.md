---
name: federation
description: Used by the federation agent to run the baseline loop — scan registered project scrums, absorb their improvement proposals into the baseline (human-approved), version releases, and disseminate them back, with per-project conflict handling.
---

# Federation (the baseline loop)

This repo is the baseline. Registered projects are other scrums installed via `scrum-init`.

## State (`.team/federation/`)

| Path | Contents |
| --- | --- |
| `registry.md` | one row per consumer: `type` (`project`/`global`), id, path, installed version, last sync date |
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

## AGENTS.md appends (child-team custom content)

Consumers keep project-specific additions to their `AGENTS.md` **strictly below** the
`BASELINE-OWNED CONTENT` marker that ends the baseline-owned section. All AGENTS.md writes to a
consumer go through `scripts/merge-agents.sh <baseline> <prev-catalog-snapshot> <consumer> <out>`:
- The release replaces only baseline-owned content **above** the marker; the consumer's tail
  below it is preserved verbatim.
- A consumer with no marker that is byte-identical to its catalog snapshot is a pristine
  baseline copy → adopt the new release wholesale. Anything else without a marker cannot be
  split reliably → it is a **conflict**, written to `conflicts/`, never silently overwritten.
- `scripts/install-global.sh` uses the same merge for a `type: global` host's AGENTS.md and
  snapshots the **merged** file (not the raw release) into the catalog so drift diffs stay true.

## Drift (local `main` ↔ `origin/main`)

The local baseline repo rides on `main` and carries local-context changes; upstream
`origin/main` is fetched, never forced over local work. Drift is reconciled per file:
- `scripts/drift-check.sh` classifies `main` vs `origin/main` (CLEAN/AHEAD/BEHIND/DIVERGED),
  checks for uncommitted baseline-owned changes, and exits non-zero when behind/dirty so a
  release can be gated.
- `scripts/sync-origin.sh` folds `origin/main` in: AGENTS.md via `merge-agents.sh`, other files
  via a normal `git merge`, **prompting per file** (`--yes` to skip prompts). True file
  conflicts land in `conflicts/`.
- A drift sync that changes baseline-owned content must **also bump the version + changelog** —
  otherwise it is drift, not a release.

## Registration (consumer ↔ baseline link)

Every project initialized by `scrum-init` carries `.team/federation/baseline.md` recording its
**primary baseline** (path or git URL) and the installed version. A machine-global scope
(installed by `scripts/install-global.sh`) is registered the same way under `Type: global`.
Registration is two-sided:
1. Consumer writes `baseline.md` (project) or the ledger entry (global host) recording the
   baseline + installed version during bootstrap / install.
2. Baseline records the consumer in `registry.md` (type, id, path, installed version) and takes
   the first `catalog/<consumer>/<version>/` snapshot as the diff base.
A project may have one primary baseline; multi-baseline sync is out of scope.

## Global hosts (`type: global`)

A `global` consumer is a machine-wide opencode scope (`~/.config/opencode/`) holding the team at
the **released version it last received** — never un-released working-tree HEAD.
- **Scan**: there is no `.team/proposals/` on a global host. Diff its installed files against
  `catalog/global-<id>/<version>/` to detect drift: user edits to team files and version skew.
  Stage findings into `inbox/global-<id>/<date>/` (read-only).
- **Release**: compute `delta(catalog/global-<id>/<v>, CURRENT_RELEASE)` and apply into the
  global scope. **Permanent excludes** — never written or diffed, they are user-owned:
  `opencode.json`, `opencode.jsonc`, `.gitignore`, `package.json`, `package-lock.json`,
  `bun.lock`, `node_modules/`. Files the user edited locally → `conflicts/`, never overwritten.
- Installing/re-syncing the current release is done by `scripts/install-global.sh`, which also
  refreshes the host's registry row + catalog snapshot.

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

For each consumer in `registry.md` (project or global host — see the global-host rules above):
1. Compute the delta between `catalog/<project>/<version>/` and the current release.
2. Apply the files that the project has NOT locally modified. **AGENTS.md is always written via
   `scripts/merge-agents.sh`** (baseline-owned content merged atop the project's preserved tail).
   Update the catalog to the new version.
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