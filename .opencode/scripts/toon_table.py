#!/usr/bin/env python3
"""
toon_table.py

Convert between Markdown tables and TOON format.

- Markdown table → TOON: reads a markdown table from a file or stdin, writes TOON
- TOON → Markdown table: reads TOON from a file or stdin, writes a markdown table

Detects the direction automatically from file extension (.toon = decode, else encode)
or from explicit --encode/--decode flags.

Delimiter: comma by default; auto-upgrades to tab when any cell value contains a comma.

Note: TOON field headers use comma as separator per the TOON spec. If a markdown
table column header contains a comma, the TOON representation is ambiguous. This
script is intended for team tables where headers are simple identifiers (no commas).
"""

from __future__ import annotations

import argparse
import re
import sys
from typing import List, Optional, Tuple


# ---------------------------------------------------------------------------
# Markdown table parsing
# ---------------------------------------------------------------------------

_MD_TABLE_RE = re.compile(
    r"^[ \t]*\|.*\|[ \t]*$",
    re.MULTILINE,
)

_SEP_RE = re.compile(r"^[\s\|:\-]+$")


def parse_md_table(text: str) -> Optional[Tuple[List[str], List[List[str]]]]:
    """
    Parse the first markdown table found in *text*.
    Returns (headers, rows) or None if no table is found.
    """
    lines = text.splitlines()
    table_lines: List[str] = []
    in_table = False

    for line in lines:
        stripped = line.strip()
        if not in_table:
            if _MD_TABLE_RE.match(stripped):
                in_table = True
                table_lines.append(stripped)
        else:
            if _MD_TABLE_RE.match(stripped):
                table_lines.append(stripped)
                if _SEP_RE.match(stripped.replace("|", "").strip()):
                    continue
                else:
                    break
            else:
                break

    if len(table_lines) < 3:
        return None

    def split_row(line: str) -> List[str]:
        parts = line.strip().strip("|").split("|")
        return [p.strip() for p in parts]

    headers = split_row(table_lines[0])
    rows: List[List[str]] = []
    for line in table_lines[2:]:
        parts = split_row(line)
        rows.append(parts)

    # Normalize row widths
    width = len(headers)
    headers = headers[:width] + [""] * max(0, width - len(headers))
    rows = [r[:width] + [""] * max(0, width - len(r)) for r in rows]

    return headers, rows


def md_table_to_toon(
    headers: List[str],
    rows: List[List[str]],
    delimiter: str = ",",
    indent: int = 2,
) -> str:
    """
    Convert parsed table data to TOON format.

    Uses *delimiter* between values. Auto-detects tab delimiter if any cell
    contains the chosen delimiter character.
    """
    # Check if delimiter appears in any cell
    all_values = [headers] + rows
    if any(delimiter in v for row in all_values for v in row):
        if delimiter == ",":
            delimiter = "\t"
        else:
            # Fall back to comma if tab also conflicts
            delimiter = ","

    header_line = (
        f"{headers[0]}[{len(rows)}]{{{','.join(headers)}}}:"
        if headers
        else "items[0]:"
    )

    row_strs = []
    for row in rows:
        row_strs.append(delimiter.join(row))

    return header_line + "\n" + "\n".join(row_strs)


# ---------------------------------------------------------------------------
# TOON parsing
# ---------------------------------------------------------------------------

_HEADER_RE = re.compile(
    r"^(?P<name>[^\[]+)\[(?P<count>\d+)\]\{(?P<fields>[^}]*)\}:\s*$"
)


def parse_toon(text: str) -> Optional[Tuple[List[str], List[List[str]]]]:
    """
    Parse TOON tabular format: name[N]{fields}: followed by N rows.
    Returns (headers, rows) or None if parsing fails.
    """
    lines = text.strip().splitlines()
    if not lines:
        return None

    m = _HEADER_RE.match(lines[0].strip())
    if not m:
        return None

    expected_count = int(m.group("count"))
    fields = [f.strip() for f in m.group("fields").split(",") if f.strip()]

    if len(lines) - 1 != expected_count:
        return None

    rows: List[List[str]] = []
    for line in lines[1:]:
        parts = line.split("\t") if "\t" in line else line.split(",")
        rows.append([p.strip() for p in parts])

    # Normalize widths
    width = len(fields)
    rows = [r[:width] + [""] * max(0, width - len(r)) for r in rows]

    return fields, rows


def toon_to_md_table(
    headers: List[str],
    rows: List[List[str]],
    indent: int = 0,
) -> str:
    """Convert parsed TOON data back to a markdown table."""
    pad = " " * indent
    sep = pad + "|" + "|".join(["---"] * len(headers)) + "|"

    lines = [pad + "|" + "|".join(headers) + "|", sep]
    for row in rows:
        lines.append(pad + "|" + "|".join(row) + "|")

    return "\n".join(lines)


# ---------------------------------------------------------------------------
# I/O
# ---------------------------------------------------------------------------


def detect_delimiter(rows: List[List[str]]) -> str:
    """Choose comma or tab based on cell values (row data only, not headers)."""
    if any("," in v for row in rows for v in row):
        return "\t"
    return ","


def main() -> int:
    p = argparse.ArgumentParser(
        description="Convert between Markdown tables and TOON format."
    )
    p.add_argument(
        "input",
        nargs="?",
        default="-",
        help="Input file path, or '-' / omit for stdin",
    )
    p.add_argument(
        "-o",
        "--output",
        help="Output file path (omit for stdout)",
    )
    mode = p.add_mutually_exclusive_group()
    mode.add_argument(
        "--encode",
        action="store_true",
        help="Force markdown table → TOON",
    )
    mode.add_argument(
        "--decode",
        action="store_true",
        help="Force TOON → markdown table",
    )
    p.add_argument(
        "--delimiter",
        choices=[",", "\\t", "tab"],
        help="TOON row delimiter: ',' (default) or tab",
    )
    p.add_argument(
        "--indent",
        type=int,
        default=0,
        help="Indentation for output markdown table (default: 0)",
    )

    args = p.parse_args()

    # Read input
    if args.input in ("-", None):
        raw = sys.stdin.read()
    else:
        with open(args.input, "r", encoding="utf-8") as f:
            raw = f.read()

    # Determine mode
    explicit = "encode" if args.encode else ("decode" if args.decode else None)
    if explicit:
        mode = explicit
    else:
        if args.input and args.input.lower().endswith(".toon"):
            mode = "decode"
        else:
            mode = "encode"

    # Resolve delimiter
    delim_char = ","
    if args.delimiter in ("\\t", "tab"):
        delim_char = "\t"

    if mode == "encode":
        result = parse_md_table(raw)
        if result is None:
            sys.stderr.write("Error: no markdown table found in input.\n")
            return 1
        headers, rows = result
        if args.delimiter is None:
            delim_char = detect_delimiter(rows)
        output = md_table_to_toon(headers, rows, delimiter=delim_char)
    else:
        result = parse_toon(raw)
        if result is None:
            sys.stderr.write("Error: could not parse TOON input.\n")
            return 1
        headers, rows = result
        output = toon_to_md_table(headers, rows, indent=args.indent)

    # Write output
    if args.output:
        with open(args.output, "w", encoding="utf-8") as f:
            f.write(output)
            f.write("\n")
    else:
        sys.stdout.write(output)
        sys.stdout.write("\n")

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
