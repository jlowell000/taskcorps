# TOON Format Skill for Claude Code

A [Claude Code](https://claude.ai/code) skill that teaches Claude how to work with **TOON (Token-Oriented Object Notation)** - a compact, token-efficient alternative to JSON optimized for LLM prompts.

## What is TOON?

TOON is a human-readable, schema-aware encoding of JSON that reduces token usage by 30-70% while maintaining lossless JSON representation. It's especially effective for **uniform arrays of objects** (tabular data).

### Example

**JSON (verbose):**
```json
{
  "users": [
    {"id": 1, "name": "Alice", "role": "admin"},
    {"id": 2, "name": "Bob", "role": "user"},
    {"id": 3, "name": "Charlie", "role": "user"}
  ]
}
```

**TOON (compact):**
```toon
users[3]{id,name,role}:
  1,Alice,admin
  2,Bob,user
  3,Charlie,user
```

## What This Skill Provides

When invoked, this skill teaches Claude Code:
- How to recognize TOON format in the wild
- When to recommend TOON over JSON for LLM prompts
- How to convert between JSON and TOON using official tooling
- Best practices for prompting LLMs with TOON data
- Validation and structural guardrails (`[N]` counts, `{field}` headers)

## Repository Structure

```
.
├── SKILL.md                 # Skill descriptor and core patterns
├── CLAUDE.md                # Guidance for Claude Code working in this repo
├── scripts/
│   ├── toon_convert.py      # Python wrapper for TOON CLI
│   └── README.md            # Wrapper usage guide
└── reference/               # Detailed reference documentation
    ├── when-to-use.md       # Decision guide: TOON vs JSON
    ├── cli.md               # Official CLI reference
    ├── library.md           # TypeScript/JS library API
    └── llm-prompting.md     # LLM prompting patterns
```

## Quick Start

### Converting JSON ↔ TOON

**Using the official CLI (recommended):**
```bash
# Encode JSON → TOON
npx @toon-format/cli input.json -o output.toon

# Decode TOON → JSON
npx @toon-format/cli input.toon -o output.json

# With token stats and tab delimiter (most efficient)
npx @toon-format/cli input.json --delimiter "\t" --stats -o output.toon
```

**Using the Python wrapper:**
```bash
# Encode with auto-detection
python scripts/toon_convert.py --encode input.json -o output.toon

# Decode with fence extraction from Markdown
cat doc.md | python scripts/toon_convert.py --decode --extract-fences > data.json
```

## How Claude Code Uses This Skill

This skill is automatically invoked when Claude Code encounters:
- Large JSON data being prepared for LLM prompts
- `.toon` file extensions
- User mentions of "TOON format" or token optimization
- Requests to reduce token usage in structured data

The skill provides context from `SKILL.md` and reference documentation to guide Claude through TOON operations.

## Official TOON Resources

- **CLI Package**: [@toon-format/cli](https://www.npmjs.com/package/@toon-format/cli) (npm)
- **TypeScript Library**: [@toon-format/toon](https://www.npmjs.com/package/@toon-format/toon) (npm)
- **Documentation**: See `reference/` directory in this repository

## When to Use TOON

✅ **Use TOON when:**
- Passing large structured context to LLMs (especially arrays of objects)
- You want token efficiency + structural validation
- Data is tabular or has uniform structure

❌ **Prefer JSON when:**
- You need strict interoperability with standard JSON parsers
- Data is deeply irregular/ragged
- No human or LLM is in the loop

## License

This skill repository is provided as-is for use with Claude Code. Refer to official TOON format repositories for their respective licenses.

## Changelog
See [CHANGELOG.md](CHANGELOG.md).
