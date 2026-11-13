"""One-shot: moves the 12 extra app languages out of app/tool/strings_*.py into this archive.

Run once, on the tree before the archive (git 1f3d3b1), from the repo root:
    python -I archive/i18n-extra-languages/tools/extract_extra_languages.py

What it does:
  1. Loads every strings_*.py (S rows ko, en, ja, zh, vi + X extras) and every lang_<code>.py,
     exactly as app/tool/gen_arb.py did.
  2. Writes archive/i18n-extra-languages/app/tool/lang_<code>.py for all 12 codes: T = {key: text}
     covering every key (ja/zh/vi from the S columns; the other nine = lang_<code>.py + the X blocks).
  3. Rewrites each strings_*.py to ko + en only: every row list keeps its first two items and the
     X / extra-language statements are dropped. Then re-loads the files and asserts that every
     row is exactly the old row's first two items, so nothing is lost or changed.
The original app/tool/lang_<code>.py files are then deleted by `git rm` (their merged content is in step 2).
"""

import ast
import importlib.util
import pathlib
import re
import sys

REPO = pathlib.Path(__file__).resolve().parents[3]
TOOL = REPO / "app" / "tool"
OUT = REPO / "archive" / "i18n-extra-languages" / "app" / "tool"
COLUMN_LANGS = ["ja", "zh", "vi"]  # S columns 3..5
HOOK = "# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)"


def load(path):
    spec = importlib.util.spec_from_file_location(path.stem, path)
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def load_all():
    table, extras = {}, {}
    for path in sorted(TOOL.glob("strings_*.py")):
        mod = load(path)
        for key, row in mod.S.items():
            assert key not in table, f"duplicate {key}"
            table[key] = list(row)
        for code, texts in getattr(mod, "X", {}).items():
            extras.setdefault(code, {}).update(texts)
    return table, extras


def write_lang(code, texts, table):
    missing = [k for k in table if not texts.get(k)]
    assert not missing, f"{code}: missing {missing[:5]}"
    unknown = [k for k in texts if k not in table]
    assert not unknown, f"{code}: unknown {unknown[:5]}"
    lines = [
        "# -*- coding: utf-8 -*-",
        f'"""{code} UI strings, archived from app/tool (see ../../README.md). T = {{key: text}}, every key of the app."""',
        "T = {",
        *(f"    {k!r}: {texts[k]!r}," for k in table),
        "}",
        "",
    ]
    (OUT / f"lang_{code}.py").write_text("\n".join(lines), encoding="utf-8", newline="\n")


def _names(node):
    return {n.id for n in ast.walk(node) if isinstance(n, ast.Name)}


def _extra_statement(stmt):
    """True for statements that only build extra-language texts (X, X1, *_X, _BRANDS)."""
    names = _names(stmt)
    return bool(names & {"X", "X1", "_BRANDS"} or any(n.endswith("_X") for n in names))


def rewrite(path, width):
    raw = path.read_bytes()
    tree = ast.parse(raw)
    line_starts = [0]
    for line in raw.splitlines(keepends=True):
        line_starts.append(line_starts[-1] + len(line))

    def off(lineno, col):  # ast columns are UTF-8 byte offsets
        return line_starts[lineno - 1] + col

    cuts = []  # (start, end) byte ranges to delete
    for stmt in tree.body:
        if _extra_statement(stmt):
            cuts.append((line_starts[stmt.lineno - 1], line_starts[stmt.end_lineno]))
            continue
        for node in ast.walk(stmt):
            if (isinstance(node, ast.List) and len(node.elts) == width
                    and all(isinstance(e, ast.Constant) and isinstance(e.value, str) for e in node.elts)):
                cuts.append((off(node.elts[1].end_lineno, node.elts[1].end_col_offset),
                             off(node.elts[-1].end_lineno, node.elts[-1].end_col_offset)))
    out = bytearray(raw)
    for start, end in sorted(cuts, reverse=True):
        del out[start:end]
    text = out.decode("utf-8")
    text = re.sub(r"\n{3,}", "\n\n", text).rstrip("\n") + "\n"
    path.write_text(_headers(text), encoding="utf-8", newline="\n")


def _headers(text):
    text = re.sub(r"Columns: ko(?: \(source\))?, en, ja, zh(?: \(Simplified\))?, vi\.", "Columns: ko (source), en.", text)
    text = re.sub(r" ?(?:X adds|X holds|X carries|X gives|Extra languages in X|Extra languages \(fil)[^.\n]*\.(?: Same keys[^.\n]*\.)?", "", text)
    lines = []
    for ln in text.split("\n"):
        if re.match(r"# (Extra-language texts|Extra languages \(|Merge the two extra-language|Machine-drafted extra translations|"
                    r"First column re-translates|X gives|X holds|X adds|X carries)", ln):
            continue
        lines.append(ln.rstrip())
        if "Columns: ko (source), en." in ln:
            lines.append(HOOK)
    return "\n".join(lines)


def main():
    table, extras = load_all()
    OUT.mkdir(parents=True, exist_ok=True)
    for i, code in enumerate(COLUMN_LANGS, start=2):
        write_lang(code, {k: row[i] for k, row in table.items()}, table)
    for path in sorted(TOOL.glob("lang_*.py")):
        code = path.stem[5:]
        write_lang(code, {**load(path).T, **extras.get(code, {})}, table)
    for path in sorted(TOOL.glob("strings_*.py")):
        rewrite(path, 14 if path.name == "strings_dahae_flow.py" else 5)
    after, left = load_all()
    assert left == {}, f"extra texts left: {sorted(left)}"
    assert list(after) == list(table), "key set or order changed"
    bad = [k for k in table if after[k] != table[k][:2]]
    assert not bad, f"rows changed: {bad[:5]}"
    print(f"archived 12 languages x {len(table)} keys; strings_*.py now ko+en")


if __name__ == "__main__":
    sys.exit(main())
