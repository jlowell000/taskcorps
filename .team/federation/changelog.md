# Federation Changelog

Versioned releases of this baseline. Every baseline mutation gets a bump — otherwise it's
drift, not a release. Snapshots live in `releases/<version>/`; per-project applied base in
`catalog/<project>/<version>/`.

**CURRENT_VERSION: v0.3.0** (the top row is always the current release; `federation-release`
asserts `catalog/<project>/<version>/` ≤ this before applying).

```text
v0.3.0  · 2026-08-06 · Global opencode scope as a federated consumer: registry gains a
  Type column (project | global); scan/release rules for `type: global` hosts with permanent
  config excludes; scripts/install-global.sh syncs the released snapshot into ~/.config/opencode/;
  pm detects un-initialized projects and offers /scrum-init. Trigger: global-scope install.
v0.2.0  · 2026-08-06 · Retro proposals 1-8 applied (human-approved 2026-08-06): run-scoped task
  ids + run identity; federation durable state tracked in git (+CURRENT_VERSION marker);
  git TDD-evidence protocol; bootstrap seeds minimal test harness when none exists;
  project→baseline pointer + two-sided registration; reviewer routes blockers by role;
  per-run scope cap with QUEUED status; scripts/validate-team.sh self-check. Trigger: local retro.
v0.1.0  · 2026-08-05 · Baseline initialized with roles, skills, commands, federation loop.
```