"""Validates one translation file against i18n_source.json.

Usage: python -I app/tool/check_lang.py <code>   (e.g. si, ne, ru)
Checks: every key present and non-empty, no unknown keys, identical {placeholders},
same number of line breaks as Korean (multi-line notes are split on '\\n').
"""

import importlib.util
import json
import pathlib
import re
import sys

HERE = pathlib.Path(__file__).resolve().parent
PH = re.compile(r"\{(\w+)\}")


def main(code: str) -> int:
    src = json.loads((HERE / "i18n_source.json").read_text(encoding="utf-8"))
    spec = importlib.util.spec_from_file_location(f"lang_{code}", HERE / f"lang_{code}.py")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    t = mod.T
    problems = []
    for k, v in src.items():
        got = t.get(k)
        if not got:
            problems.append(f"missing: {k}")
            continue
        if set(PH.findall(got)) != set(PH.findall(v["ko"])):
            problems.append(f"placeholders: {k}")
        if got.count("\n") != v["ko"].count("\n") and k.startswith("svcNotes_"):
            problems.append(f"line count: {k}")
    problems += [f"unknown: {k}" for k in t if k not in src]
    print("\n".join(problems) or f"lang_{code}: OK ({len(t)} keys)")
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1]))
