---
name: design
description: Used by the designer agent to produce implementation-ready specs and test plans, and to maintain the holistic .team/context/ system map and ADRs.
---

# Design

Produce a specification the coder can implement without improvising.

## Inputs you must read

`AGENTS.md`, the task's `brief.md`, `.team/status.md`, relevant `.team/context/` docs, and
enough of the real codebase to ground the design.

 ## `spec.md` structure

 ```markdown
 # T<id> — <title>
 ## Goal & scope
 - What ships (from brief), what is explicitly out of scope
 ## Approach
 - Files to touch, interfaces, data flow, commands. Concrete enough to start coding.
 ## Schema dependencies
 - Config models this task depends on: required fields, types, and defaults. If defaults are
   assumed, state that explicitly. Verify the current schema before writing the test plan so
   drift does not break tests.
 ## Test plan
 - Per acceptance criterion: test name + expected observable behavior
 - Edge cases: boundaries, errors, empty inputs, concurrency, persistence
 - **Floating-point safety:** when testing numeric boundaries, verify equality under IEEE 754
   (use `math.isclose()` or equal literals). Avoid patterns like `0.1 + 0.2 == 0.3`, which
   fail even with a correct implementation.
 ## Risks & open questions
 - Things the coder must NOT decide themselves; gate via handoff if blocking
 ## Handoff block
   (READY_FOR_CODER | BLOCKED + next-owner decision)
 ```

## The holistic view (`.team/context/`)

- `stack.md` — runtime, language, toolchain, test command facts.
- `test-harness.md` — how tests run, cover, and what "green" means.
- `adrs/<id>.md` — one per significant decision: context → decision → consequences.
- Update these whenever design work reveals facts. Cross-task impacts → flag to `pm`.

## Rules

- Spec is complete when coder can start without questions: named files, named functions,
  named tests, expected outputs.
- If you discover scope or design conflicts with another task's spec, write to your handoff
  and inform `pm` — do not silently redesign.
- Ownership: `spec.md` + `.team/context/` only. Your `handoff` gating line: `READY_FOR_CODER`.