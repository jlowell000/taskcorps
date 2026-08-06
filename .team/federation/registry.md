# Federation Registry

One row per project initialized with `scrum-init` (or registering manually). Updated by
`federation-scan` (sync/version check) and `federation-release` (applied version).
Registration is two-sided: the project writes `.team/federation/baseline.md` (its primary
baseline path/URL + installed version), and this baseline records the project here and takes
the first `catalog/<project>/<version>/` snapshot.

| Project id | Path | Installed version | Last scan |
| --- | --- | --- | --- |
| (this repo is the baseline, not listed) | | | |

## Add a project

- After running `/scrum-init <path>` against this baseline, register here: record id = slug of
  the project path, the installed version, and take the first `catalog/<project>/<version>/`
  snapshot. The project's `.team/federation/baseline.md` must point back at this baseline.