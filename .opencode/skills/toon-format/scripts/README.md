# TOON conversion helper

`scripts/toon_convert.py` is a wrapper for JSON↔TOON conversion that prefers the official tooling:

1) Use `toon` if it is installed globally (`npm i -g @toon-format/cli`)
2) Otherwise fall back to `npx @toon-format/cli` (requires Node + npm)

It also supports extracting TOON from Markdown code fences.

## Examples

Encode JSON file to TOON:
```bash
python scripts/toon_convert.py --encode input.json -o output.toon
```

Decode TOON to JSON:
```bash
python scripts/toon_convert.py --decode input.toon -o output.json
```

Pipe from stdin (auto-detect fences; default encode):
```bash
cat input.json | python scripts/toon_convert.py --encode > output.toon
```

Token stats + tab delimiter:
```bash
python scripts/toon_convert.py --encode data.json --stats --delimiter "\t" -o data.toon
```

Key folding + tab delimiter:
```bash
python scripts/toon_convert.py --encode data.json --keyFolding safe --delimiter "\t" -o folded.toon
```

Decode with path expansion:
```bash
python scripts/toon_convert.py --decode folded.toon --expandPaths safe -o data.json
```
