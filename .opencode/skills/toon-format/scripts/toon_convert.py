#!/usr/bin/env python3

"""
toon_convert.py

A convenience wrapper around the official TOON CLI for JSON↔TOON conversions.

- Prefers `toon` (global install of @toon-format/cli) if present
- Falls back to `npx @toon-format/cli` otherwise
- Can extract TOON from Markdown code fences (```toon ... ```)
"""

from __future__ import annotations

import argparse
import os
import re
import shutil
import subprocess
import sys
from typing import Optional, Tuple


FENCE_RE = re.compile(
    r"```(?P<lang>[a-zA-Z0-9_-]+)\s*\n(?P<body>.*?)(?:\n```)",
    re.DOTALL,
)


def extract_fenced_block(text: str, preferred_langs: Tuple[str, ...] = ("toon", "yaml", "text")) -> Tuple[str, Optional[str]]:
    """
    If text contains fenced code blocks, return the first block whose language matches preferred_langs.
    If none match, return original text.
    """
    matches = list(FENCE_RE.finditer(text))
    if not matches:
        return text, None

    # pick best match by preferred_langs order
    for lang in preferred_langs:
        for m in matches:
            if (m.group("lang") or "").lower() == lang:
                return m.group("body").strip("\n"), lang

    # fallback: first fence
    m = matches[0]
    return m.group("body").strip("\n"), (m.group("lang") or "").lower()


def resolve_cli() -> list[str]:
    """
    Returns base command as a list suitable for subprocess.
    """
    if shutil.which("toon"):
        return ["toon"]
    # fall back to npx
    if shutil.which("npx"):
        return ["npx", "@toon-format/cli"]
    raise FileNotFoundError(
        "Neither `toon` nor `npx` is available. Install Node/npm, then run `npm i -g @toon-format/cli` "
        "or ensure `npx` is on PATH."
    )


def infer_mode(path: Optional[str], explicit: Optional[str]) -> str:
    if explicit in ("encode", "decode"):
        return explicit
    if not path or path == "-":
        return "encode"  # stdin defaults to encode in official CLI
    ext = os.path.splitext(path)[1].lower()
    if ext == ".toon":
        return "decode"
    return "encode"


def build_args(args: argparse.Namespace, mode: str) -> list[str]:
    cli = resolve_cli()
    cmd = cli.copy()

    # Input path (optional). If omitted, CLI reads stdin.
    if args.input and args.input != "-":
        cmd.append(args.input)

    # Force mode for stdin or to override auto-detection.
    if mode == "encode":
        cmd.append("--encode")
    else:
        cmd.append("--decode")

    if args.output:
        cmd.extend(["-o", args.output])

    if args.delimiter is not None:
        cmd.extend(["--delimiter", args.delimiter])

    if args.indent is not None:
        cmd.extend(["--indent", str(args.indent)])

    if args.stats:
        cmd.append("--stats")

    if args.no_strict:
        cmd.append("--no-strict")

    if args.keyFolding:
        cmd.extend(["--keyFolding", args.keyFolding])

    if args.flattenDepth is not None:
        cmd.extend(["--flattenDepth", str(args.flattenDepth)])

    if args.expandPaths:
        cmd.extend(["--expandPaths", args.expandPaths])

    return cmd


def main() -> int:
    p = argparse.ArgumentParser(description="Convert between JSON and TOON using the official CLI.")
    p.add_argument("input", nargs="?", default="-", help="Input file path, or '-' / omit for stdin")
    mode = p.add_mutually_exclusive_group()
    mode.add_argument("--encode", action="store_true", help="Force encode (JSON → TOON)")
    mode.add_argument("--decode", action="store_true", help="Force decode (TOON → JSON)")
    p.add_argument("-o", "--output", help="Output file path (omit for stdout)")
    p.add_argument("--delimiter", help="Delimiter character: ',', '\\t', or '|'")
    p.add_argument("--indent", type=int, help="Indentation (decode output JSON only)")
    p.add_argument("--stats", action="store_true", help="Show token statistics (encode only; may use more memory)")
    p.add_argument("--no-strict", dest="no_strict", action="store_true", help="Disable strict validation (decode only)")
    p.add_argument("--keyFolding", choices=["off", "safe"], help="Key folding mode (encode)")
    p.add_argument("--flattenDepth", type=int, help="Maximum segments to fold (requires --keyFolding safe)")
    p.add_argument("--expandPaths", choices=["off", "safe"], help="Expand folded paths (decode)")
    p.add_argument("--extract-fences", action="store_true", help="If reading stdin, extract first ```toon fenced block")

    args = p.parse_args()

    explicit = "encode" if args.encode else ("decode" if args.decode else None)
    actual_mode = infer_mode(args.input, explicit)

    # Read stdin (optional) and possibly extract fences
    stdin_bytes = None
    if args.input in ("-", None) or args.input == "-":
        if not sys.stdin.isatty():
            raw = sys.stdin.read()
            if args.extract_fences:
                extracted, _lang = extract_fenced_block(raw)
                raw = extracted
            stdin_bytes = raw.encode("utf-8")

    cmd = build_args(args, actual_mode)

    try:
        proc = subprocess.run(
            cmd,
            input=stdin_bytes,
            check=False,
        )
        return proc.returncode
    except FileNotFoundError as e:
        sys.stderr.write(str(e) + "\n")
        return 127


if __name__ == "__main__":
    raise SystemExit(main())
