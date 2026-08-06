# Federation Decisions

Log of every inbound candidate's verdict. Format:

```
| Date | Source project | Candidate (file) | Verdict | Rationale |
| --- | --- | --- | --- | --- |
```

Verdicts: `ADOPT` (merged as-is) · `ADAPT` (merged with changes) · `REJECT` (+ reason).

```text
| 2026-08-06 | local retro | 2026-08-06-1-run-scoped-task-ids.md | ADOPT | Run-scoped ids + run identity; fixes cross-run collisions and non-deterministic resume |
| 2026-08-06 | local retro | 2026-08-06-2-federation-state-versioned.md | ADOPT | Federation durable state now tracked; CURRENT_VERSION marker added |
| 2026-08-06 | local retro | 2026-08-06-3-git-tdd-evidence-protocol.md | ADOPT | RED commit protocol + fallback evidence; makes red-first provable |
| 2026-08-06 | local retro | 2026-08-06-4-bootstrap-seeds-test-harness.md | ADOPT | T0 harness item when discovery finds none |
| 2026-08-06 | local retro | 2026-08-06-5-baseline-pointer-registration.md | ADOPT | baseline.md pointer + two-sided registration |
| 2026-08-06 | local retro | 2026-08-06-6-reviewer-names-target-role.md | ADOPT | Route: field per blocker; pm routes mechanically |
| 2026-08-06 | local retro | 2026-08-06-7-run-scope-cap.md | ADOPT | N=5 dispatch cap; QUEUED status for overflow |
| 2026-08-06 | local retro | 2026-08-06-8-baseline-validation-script.md | ADOPT | scripts/validate-team.sh self-check; PASS at v0.2.0 |
| 2026-08-05 | — | — | — | Baseline initialized; no candidates yet |
```

Rules: every merged decision must appear here AND bump a version in `changelog.md`.