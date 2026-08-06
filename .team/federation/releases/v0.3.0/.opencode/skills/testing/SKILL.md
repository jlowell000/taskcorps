---
name: testing
description: Used by coder and tester agents to follow and verify TDD, discover and run the project's test harness, and write honest, verifiable reports in report.md.
---

# Testing

Two roles use this: the coder (to follow TDD) and the tester (to verify it).

## TDD workflow (coder)

For each acceptance criterion, in order:

1. **RED** — write the failing test. Run it and capture the failing output **now**.
   The failure must show the feature is missing (`FAILED`, `not implemented`, unbound name,
   `404`, etc.). A test failing for an unrelated reason (broken harness, typo) does not count.
   If the repo is git-managed, **commit the failing test before implementing** so the RED phase
   is provable from history (`git log`/diff). Without git, the verbatim failing output captured
   here is the authoritative RED evidence.
2. **GREEN** — implement the minimal change; run the test; it passes.
3. **REFACTOR** — improve while keeping the suite green.

Record, per criterion, in `impl.md`: criterion → test name → red-output → green-output →
what changed. This evidence is what the tester and reviewer will check.

## Harness discovery (init + tester)

- Prefer `.team/context/test-harness.md` written at `scrum-init`.
- If absent, detect: look for `package.json` scripts, `tox.ini`/`pytest.ini`/`pyproject.toml`,
  `Makefile`, `CMakeLists`, `cargo.toml`, `*.spec` etc. Derive the exact command.
- Record the canonical command in the report so it's reproducible.

## Full suite (tester)

- Run the **full** suite + lint/typecheck if present, on final code. Record exact commands.
- Report counts: total / passed / failed / skipped / error, plus anything flaky (run twice).

## Edge-case hunting (tester)

Probe beyond the written tests: boundaries, error/empty input, repeat runs, concurrency,
resource cleanup, and regressions in adjacent modules the change could touch.
Only verified findings go in "Findings"; unverified suspicions go in "Risks".

## Report structure (`report.md`)

```markdown
# T<id> — Test report
- Suite: <command + link to output>
- Result: PASS | FAIL (<counts>)
- TDD verdict: PROVEN | UNPROVEN (<evidence or gap>)
- Findings: #severe/<file/line> — repro — impact (none if clean)
- Risks: <unverified suspicions>
- Handoff block: READY_FOR_REVIEW | BACK_TO_CODER
```

## Rules

- Never relax, delete, or skip tests to get green; flag the problem instead.
- Never claim a full-suite pass unless you ran the full suite on final code.
- Tests may be edited only by coder (during TDD) or tester (with every change documented in
  `report.md`).