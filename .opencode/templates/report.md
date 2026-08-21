# T<id> — <title> · Test report

Owner: tester. Copy to `.team/tasks/<id>/report.md`.

- Suite command: <exact command run>
- Result: PASS / FAIL — <passed>/<total> (+ <skipped>, <error>)
- TDD verdict: PROVEN / UNPROVEN — <evidence; the RED run before implementation>
- Flaky: <tests that flaked; re-run counts>

## Findings (verified only)

| # | Severity | Where | Repro | Impact |
| --- | --- | --- | --- | --- |
| 1 | high/med/low | file:line | <steps> | <what breaks> |

Optional: inline findings as TOON when this report will be consumed by an LLM
prompt (fenced ```toon block). Convert with `.opencode/scripts/toon_table.py --encode`.

## Risks (unverified suspicions)

- <one-liners>

## Test changes I made (if any)

- <every test edit + why; else "none">

---

**Handoff — tester**
- Status: READY_FOR_REVIEW / BACK_TO_CODER
- Changed: <deltas only>
- Next: **reviewer** gates on this report + `impl.md` + `spec.md`
- Notes: none