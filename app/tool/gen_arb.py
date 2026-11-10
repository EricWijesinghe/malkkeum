"""Builds packages/core/lib/l10n/app_<lang>.arb from the strings_*.py tables.

One table per app area keeps all five languages side by side, so a missing
translation is a visible gap in a row rather than a silently absent key.

Run:  python -I app/tool/gen_arb.py   (then `flutter gen-l10n` runs on build)
"""

import importlib.util
import json
import pathlib
import re
import sys

LANGS = ["ko", "en", "ja", "zh", "vi"]
HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "packages" / "core" / "lib" / "l10n"
PLACEHOLDER = re.compile(r"\{(\w+)\}")


def load_tables():
    merged = {}
    for path in sorted(HERE.glob("strings_*.py")):
        spec = importlib.util.spec_from_file_location(path.stem, path)
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        for key, row in mod.S.items():
            if key in merged:
                sys.exit(f"duplicate key {key} in {path.name}")
            merged[key] = row
    return merged


def main():
    table = load_tables()
    errors = []
    for key, row in table.items():
        if len(row) != len(LANGS) or any(not v for v in row):
            errors.append(f"{key}: needs {len(LANGS)} non-empty values")
        expected = set(PLACEHOLDER.findall(row[0]))
        for lang, value in zip(LANGS, row):
            if set(PLACEHOLDER.findall(value)) != expected:
                errors.append(f"{key}[{lang}]: placeholders differ from ko")
    if errors:
        sys.exit("\n".join(errors))

    OUT.mkdir(parents=True, exist_ok=True)
    for i, lang in enumerate(LANGS):
        arb = {"@@locale": lang}
        for key, row in table.items():
            arb[key] = row[i]
            names = PLACEHOLDER.findall(row[0])
            if lang == "ko" and names:
                arb[f"@{key}"] = {"placeholders": {n: {"type": "String"} for n in dict.fromkeys(names)}}
        (OUT / f"app_{lang}.arb").write_text(json.dumps(arb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {len(LANGS)} ARB files, {len(table)} keys each")


if __name__ == "__main__":
    main()
