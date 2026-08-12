# CLI reference (quick)

The official CLI package is `@toon-format/cli`.

## Run without installing
```bash
# Encode JSON → TOON
npx @toon-format/cli input.json -o output.toon

# Decode TOON → JSON
npx @toon-format/cli input.toon -o output.json
```

## Common options
```bash
# Token stats (encode only)
npx @toon-format/cli input.json --stats -o output.toon

# Delimiters (comma default; tab often best)
npx @toon-format/cli input.json --delimiter "\t" -o output.toon
npx @toon-format/cli input.json --delimiter "|"  -o output.toon

# Lenient decode (skip strict validation checks)
npx @toon-format/cli input.toon --no-strict -o output.json

# Key folding + path expansion (lossless round-trip)
npx @toon-format/cli input.json --keyFolding safe -o folded.toon
npx @toon-format/cli folded.toon --decode --expandPaths safe -o output.json
```

Notes:
- The CLI auto-detects encode/decode from file extension; when using stdin, pass `--encode` or `--decode`.
