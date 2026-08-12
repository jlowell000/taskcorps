# T<id> — <title> · Implementation (TDD record)

Owner: coder. Copy to `.team/tasks/<id>/impl.md`.

## Per acceptance criterion

| Criterion | Test added | RED evidence (failing output) | GREEN (final pass) | Changed files |
| --- | --- | --- | --- | --- |
| AC1 | `test_...` | <command + failure reason> | <command + pass> | <paths> |

Optional: inline the per-AC evidence as TOON when this impl will be consumed by an
LLM prompt (fenced ```toon block). RED evidence fields may contain free-form text;
use tab delimiter if any cell contains commas.

## Refactor step

- <what was cleaned up, still green>

## Deviations from spec

- <every deviation + why; "none" if clean>

---

**Handoff — coder**
- Status: READY_FOR_TESTER
- Changed: <deltas only>
- Next: **tester** must verify RED-first discipline + run the full suite → `report.md`
- Notes: none