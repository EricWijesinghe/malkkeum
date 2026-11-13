"""Builds packages/core/lib/l10n/app_<lang>.arb from the strings_*.py tables.

One table per app area keeps Korean and English side by side, so a missing
translation is a visible gap in a row rather than a silently absent key.

Run:  python -I app/tool/gen_arb.py   (then `flutter gen-l10n` runs on build)
"""

import importlib.util
import json
import pathlib
import re
import sys

# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
LANGS = ["ko", "en"]
# Extra languages live in lang_<code>.py as T = {key: text}; they must cover every key (none ship today).
EXTRA = sorted(p.stem[5:] for p in pathlib.Path(__file__).resolve().parent.glob("lang_*.py"))
HERE = pathlib.Path(__file__).resolve().parent
OUT = HERE.parent / "packages" / "core" / "lib" / "l10n"
PLACEHOLDER = re.compile(r"\{(\w+)\}")


# A strings_<area>.py may also carry its extra-language texts as X = {code: {key: text}},
# so a feature adds one self-contained file instead of editing every lang_<code>.py.
AREA_EXTRAS = {}


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
        for code, texts in getattr(mod, "X", {}).items():
            AREA_EXTRAS.setdefault(code, {}).update(texts)
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

    extras = {}
    for code in EXTRA:
        spec = importlib.util.spec_from_file_location(f"lang_{code}", HERE / f"lang_{code}.py")
        mod = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(mod)
        mod.T = {**mod.T, **AREA_EXTRAS.get(code, {})}
        missing = [k for k in table if not mod.T.get(k)]
        unknown = [k for k in mod.T if k not in table]
        bad = [k for k in table if k in mod.T and set(PLACEHOLDER.findall(mod.T[k])) != set(PLACEHOLDER.findall(table[k][0]))]
        if missing or unknown or bad:
            sys.exit(f"lang_{code}: missing {missing[:10]}{'...' if len(missing) > 10 else ''} unknown {unknown[:5]} placeholder-mismatch {bad[:10]}")
        extras[code] = mod.T

    OUT.mkdir(parents=True, exist_ok=True)
    for code, texts in extras.items():
        arb = {"@@locale": code, **{k: texts[k] for k in table}}
        (OUT / f"app_{code}.arb").write_text(json.dumps(arb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    for i, lang in enumerate(LANGS):
        arb = {"@@locale": lang}
        for key, row in table.items():
            arb[key] = row[i]
            names = PLACEHOLDER.findall(row[0])
            if lang == "ko" and names:
                arb[f"@{key}"] = {"placeholders": {n: {"type": "String"} for n in dict.fromkeys(names)}}
        (OUT / f"app_{lang}.arb").write_text(json.dumps(arb, ensure_ascii=False, indent=1) + "\n", encoding="utf-8")
    print(f"wrote {len(LANGS) + len(extras)} ARB files, {len(table)} keys each")


if __name__ == "__main__":
    main()
