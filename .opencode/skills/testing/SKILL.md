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
   **If a RED test passes** (does not fail) or fails for an *incidental* reason (e.g. the model
   rejects the input for an unrelated rule like `extra="forbid"`), verify it fails for the
   **intended** reason: assert the specific error type/message, or confirm the test cannot pass
   via an unrelated mechanism. Document any wrong-reason pass in `impl.md` — a test that passes
   at RED for an incidental reason does not prove the feature's absence.
   If the repo is git-managed, **commit the failing test before implementing** so the RED phase
   is provable from history (`git log`/diff). Without git, the verbatim failing output captured
   here is the authoritative RED evidence.
2. **GREEN** — implement the minimal change; run the test; it passes.
3. **REFACTOR** — improve while keeping the suite green.

 Record, per criterion, in `impl.md`: criterion → test name → red-output → green-output →
 what changed. This evidence is what the tester and reviewer will check.

 ## Test-only additive tasks

 When a task is explicitly designated **test-only additive** in its brief (no production code
 changes, only new tests against existing code), the RED phase is not applicable by definition —
 the implementation already exists and passes. In this case:
 - Coder writes the new tests, runs them, and verifies they pass against the existing code.
 - `impl.md` documents `RED: N/A — test-only additive task; implementation already exists`
   with the brief id as justification.
 - Tester verifies the new tests pass and that no production code was modified.
 - This path is only valid when the brief explicitly designates the task as test-only additive.
   Any task that modifies production code must follow the standard RED→GREEN→REFACTOR cycle.

## Harness discovery (init + tester)

- Prefer `.team/context/test-harness.md` written at `scrum-init`.
- If absent, detect: look for `package.json` scripts, `tox.ini`/`pytest.ini`/`pyproject.toml`,
  `Makefile`, `CMakeLists`, `cargo.toml`, `*.spec` etc. Derive the exact command.
- Record the canonical command in the report so it's reproducible.

 ## Full suite (tester)

 - Run the **full** suite + lint/typecheck if present, on final code. Record exact commands.
 - "Full suite green" means `pytest` collects **all** tests in the repository and every collected
   test passes. Collection errors (missing optional dependencies, syntax errors in tests) are
   failures — fix them, add the missing dependency to dev requirements, or mark the test with
   `pytest.mark.skip(reason="optional dep missing: ...")` so collection succeeds.
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
 - Pre-existing defects: <any defects discovered during task execution, with short description>
 - Risks: <unverified suspicions>
 - Handoff block: READY_FOR_REVIEW | BACK_TO_CODER
 ```

 ## Rules

 - Never relax, delete, or skip tests to get green; flag the problem instead.
 - Never claim a full-suite pass unless you ran the full suite on final code.
 - Tests may be edited only by coder (during TDD) or tester (with every change documented in
   `report.md`).
 - **No ephemeral task-folder paths in tests.** Tests must reference durable records
   (`.team/context/adrs/`, committed fixtures, or stable source files) — never
   `.team/tasks/<id>/` paths, which move to `.team/archive/` when a task completes and break
   the suite later.
 - **Pre-existing defects:** if you discover a pre-existing defect during task execution, record
   it in the `Pre-existing defects` section of `report.md`. pm will add it to `.team/backlog.md`
   as a tracked item. Do not silently document and forget defects.