# LLM prompting patterns for TOON

## Sending TOON as input
- Use a fenced code block labeled `toon` (or `yaml` if `toon` isn’t supported).
- Don’t over-explain syntax; show a small example (2–5 rows) when teaching.

Example:
```markdown
Data is in TOON format (2-space indent, arrays show length and fields).
```toon
users[3]{id,name,role}:
  1,Alice,admin
  2,Bob,user
  3,Charlie,user
```
Task: Summarize roles.
```

## Getting the model to generate TOON
Be explicit:
- Provide the header template (e.g., `users[N]{id,name,role}:`)
- Require `[N]` to match the row count
- Require “output only the code block” if you will parse

Example instruction:
“Return only users with role 'user' as TOON. Use the same header. Set [N] correctly. Output only the code block.”

## Validation rule
If you plan to parse the model’s output, you MUST validate (strict decode). If validation fails:
- ask for re-output with the header template and rules
- or request JSON output instead
