# When to use TOON (and when not to)

## Prefer TOON when
### You are prompting an LLM with large structured data
TOON is designed for reduced token cost and improved reliability, especially when you would otherwise paste verbose JSON.

### The data has *uniform structure*
TOON shines for arrays of objects that share the same keys (e.g., “users”, “events”, “orders line items”). The `{fields}` header declares schema once and rows carry values.

### You want structure guardrails
`[N]` makes truncation detectable. `{fields}` makes column alignment obvious.

## Prefer JSON/other formats when
### You need strict interoperability
If the consumer is a non-TOON parser, stick with JSON/JSONL/CSV.

### Data is deeply irregular
If each object has different keys, TOON may not be more compact or readable.

### You need exact original whitespace/format
TOON encodes data semantics, not original JSON formatting.

## Rule of thumb
- **Input to LLM:** TOON if it’s tabular or nested JSON you’re pasting into a prompt.
- **Output from LLM:** TOON only if you will validate/parse; otherwise ask for JSON.
