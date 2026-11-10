"""Checks every docs/store/listing-*.md against the App Store and Google Play limits.

  python -I docs/store/check_listings.py        (exit 1 on any violation)

Each listing has, per app section (## ...), a table with rows in this fixed order:
  1. app name (30)  2. iOS subtitle (30)  3. Google short description (80)
  4. iOS keywords (100, comma separated, no spaces)  5. iOS promotional text (170)  6. category (no limit)
followed by exactly two fenced blocks: the full description (4000) and "what's new" (4000).
The limit column must state the same number the store enforces, and the text must fit it.
Lengths are counted in characters (Unicode code points), which is what the consoles count for Korean and Japanese.
"""

import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
LIMITS = [30, 30, 80, 100, 170]
BLOCK_LIMIT = 4000
ROW_COUNT = 6
TABLE_ROW = re.compile(r"^\|(.+)\|\s*$")


def parse(path):
    """Returns {section title: {"rows": [(limit_text, value)], "blocks": [text]}}."""
    sections = {}
    current = None
    in_block = False
    block = []
    for raw in path.read_text(encoding="utf-8").splitlines():
        line = raw.rstrip()
        if line.startswith("```"):
            if in_block:
                if current is not None:
                    sections[current]["blocks"].append("\n".join(block).strip())
                block = []
            in_block = not in_block
            continue
        if in_block:
            block.append(line)
            continue
        if line.startswith("## "):
            current = line[3:].strip()
            sections[current] = {"rows": [], "blocks": []}
            continue
        match = TABLE_ROW.match(line)
        if current is None or not match:
            continue
        cells = [c.strip() for c in match.group(1).split("|")]
        # Header and separator rows have a non-numeric limit cell; field rows have a number or nothing.
        if len(cells) != 3 or (cells[1] and not cells[1].isdigit()):
            continue
        sections[current]["rows"].append((cells[1], cells[2]))
    return sections


def check_file(path):
    problems = []
    sections = parse(path)
    if not sections:
        return [f"{path.name}: no '## ' app sections found"]
    for title, sec in sections.items():
        where = f"{path.name} [{title}]"
        rows = sec["rows"]
        if not rows:  # free-text sections such as review notes have no field table
            continue
        if len(rows) != ROW_COUNT:
            problems.append(f"{where}: expected {ROW_COUNT} table rows, found {len(rows)}")
            continue
        for i, limit in enumerate(LIMITS):
            limit_text, value = rows[i]
            if limit_text != str(limit):
                problems.append(f"{where}: row {i + 1} limit column says '{limit_text}', store limit is {limit}")
            if not value:
                problems.append(f"{where}: row {i + 1} is empty")
            elif len(value) > limit:
                problems.append(f"{where}: row {i + 1} is {len(value)} chars, limit {limit}: {value}")
        keywords = rows[3][1]
        if ", " in keywords or " ," in keywords:
            problems.append(f"{where}: keywords must be comma separated with no spaces")
        if rows[5][1] == "":
            problems.append(f"{where}: category is empty")
        if len(sec["blocks"]) != 2:
            problems.append(f"{where}: expected 2 fenced blocks (description, what's new), found {len(sec['blocks'])}")
        else:
            for name, text in zip(("description", "what's new"), sec["blocks"]):
                if not text:
                    problems.append(f"{where}: {name} is empty")
                elif len(text) > BLOCK_LIMIT:
                    problems.append(f"{where}: {name} is {len(text)} chars, limit {BLOCK_LIMIT}")
    return problems


def main():
    sys.stdout.reconfigure(encoding="utf-8")
    files = sorted(HERE.glob("listing-*.md"))
    if not files:
        print("no listing-*.md files found", file=sys.stderr)
        return 1
    problems = []
    for f in files:
        problems += check_file(f)
    for p in problems:
        print(p)
    print(f"checked {len(files)} listing files: {'OK' if not problems else f'{len(problems)} problem(s)'}")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
