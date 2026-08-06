# Federation Registry

One row per consumer initialized with `scrum-init` (a project) or `install-global.sh` (a
machine-global opencode scope). Two types:
- `project` — a repo initialized via `scrum-init`; carries its own `.team/` + team copy.
- `global` — a machine-wide opencode scope at `~/.config/opencode/` synced from a released
  snapshot; has no `.team/` (only drift/scan via its catalog snapshot).

Updated by `federation-scan` (sync/version check) and `federation-release` (applied version).
Registration is two-sided: the consumer writes its `baseline.md`/ledger entry (primary baseline
+ installed version), and this baseline records the consumer here and takes the first
`catalog/<consumer>/<version>/` snapshot as the diff base.

| Type | Consumer id | Path | Installed version | Last scan |
| --- | --- | --- | --- | --- |
| (this repo is the baseline, not listed) | | | | |
| global | global-john-cachyos-x8664-fw1 | ~/.config/opencode/ | v0.3.0 | — |

## Add a project

- After running `/scrum-init <path>` against this baseline, register here: record `Type: project`,
  id = slug of the project path, the installed version, and take the first
  `catalog/<project>/<version>/` snapshot. The project's `.team/federation/baseline.md` must
  point back at this baseline.

## Add a global host

- After running `scripts/install-global.sh`, register here: record `Type: global`, id =
  `global-<user>-<hostname>`, path `~/.config/opencode/`, the installed version, and take the
  first `catalog/global-<user>-<hostname>/<version>/` snapshot of what was installed. A global
  host's releases exclude user-owned config files (`opencode.json[c]`, `.gitignore`,
  `package*.json`, `node_modules/`).