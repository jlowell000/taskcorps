# T<id> — <title> · Review

Owner: reviewer. Copy to `.team/tasks/<id>/review.md`.

- Verdict: APPROVED / CHANGES_REQUESTED
- Reviewed: spec.md · impl.md · report.md · code diff · context docs (tick what you read)

## Blockers (only if CHANGES_REQUESTED)

| # | Route | What | Where | Why | Minimal fix |
| --- | --- | --- | --- | --- | --- |
| 1 | coder/tester | <problem> | file:line | <why it's wrong> | <minimal fix> |

`Route` names the role that must fix the blocker (coder: correctness/spec/RED evidence;
tester: false-positive test / unverified suite claim). pm routes mechanically from this column.

## Non-blocking notes

- <nits / future improvements>

## Checklist

- [ ] Acceptance criteria met (mapped criterion → proof)
- [ ] TDD discipline: RED proven, tests test behavior not internals
- [ ] Spec followed; deviations documented in `impl.md`
- [ ] Report honest: real suite run on final code
- [ ] No severe quality/security/robustness issues

---

**Handoff — reviewer**
- Status: APPROVED / CHANGES_REQUESTED
- Next: **pm** — archive on APPROVED; else resend to coder/tester per each blocker's `Route` column
- Notes: none