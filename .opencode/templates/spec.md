# T<id> — <title> · Spec

Owner: designer. Copy to `.team/tasks/<id>/spec.md`.

## Goal & scope

- Ships: <from brief>
- Out of scope: <explicit>

## Approach

- Files to touch: <paths>
- Interfaces / data flow: <concrete>
- Commands / migrations / config: <concrete>

## Test plan

| Criterion (brief) | Test name | Expected behavior |
| --- | --- | --- |
| AC1 | `test_...` | <observable result> |

Optional: inline the test plan as TOON when this spec will be consumed by an LLM
prompt (fenced ```toon block, same header format as the table above).

Edge cases to cover: <boundaries, errors, empty input, concurrency, persistence>

## Risks & open questions

- <items the coder must NOT decide; gate via handoff if blocking>

## Decisions the coder must not revisit

- <design choices fixed here>

---

**Handoff — designer**
- Status: READY_FOR_CODER
- Changed: spec + test plan written; context docs updated (list)
- Next: **coder** must write the RED tests per plan, implement, record in `impl.md`
- Notes: none