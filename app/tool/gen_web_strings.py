"""Copies service names and descriptions from the app ARB files into the website.

Run after gen_arb.py:  python -I app/tool/gen_web_strings.py
"""
import json
import pathlib

HERE = pathlib.Path(__file__).resolve().parent
ARB = HERE.parent / "packages" / "core" / "lib" / "l10n"
OUT = HERE.parent.parent / "website" / "assets" / "services.json"
COPY_OUT = HERE.parent.parent / "website" / "assets" / "web_copy.json"
PREFIXES = {"svcShort_": "name", "svcDesc_": "desc"}


def main():
    out = {}
    copy = {}
    for path in sorted(ARB.glob("app_*.arb")):
        lang = path.stem[4:]
        arb = json.loads(path.read_text(encoding="utf-8"))
        per = {}
        for key, value in arb.items():
            for prefix, field in PREFIXES.items():
                if key.startswith(prefix):
                    per.setdefault(key[len(prefix):], {})[field] = value
        out[lang] = per
        # webBookNow -> bookNow: the website's data-web-t labels (strings_web.py).
        copy[lang] = {k[3].lower() + k[4:]: v for k, v in arb.items() if k.startswith("web") and k[3:4].isupper()}
    OUT.write_text(json.dumps(out, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    COPY_OUT.write_text(json.dumps(copy, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    print(f"wrote {OUT.name}, {COPY_OUT.name}: {len(out)} languages")


if __name__ == "__main__":
    main()
