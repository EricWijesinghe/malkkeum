"""Builds the website's self-hosted font: a subset of Pretendard renamed "Dahae Sans".

Pretendard's OFL reserves the name "Pretendard" for unmodified fonts, so the subset gets its own family
name (see website/assets/fonts/NOTICE). The subset holds Latin, punctuation, Hangul jamo and every Hangul
syllable the static website uses; any other syllable (owner-entered names, reviews) falls back per glyph
to the system Korean font.
shortcut: syllables are taken from the static files only; run again after changing website copy.

    python -I scripts/build_fonts.py            # rebuild (needs: pip install fonttools brotli)
    python -I scripts/build_fonts.py --check    # stdlib only: every Hangul syllable on the site is in the subset
"""
import pathlib
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
SRC = ROOT / "app/packages/ui/assets/fonts"
OUT = ROOT / "website/assets/fonts"
CHARSET = OUT / "charset.txt"
FAMILY = "Dahae Sans"
WEIGHTS = {400: "Regular", 700: "Bold", 800: "ExtraBold"}
# Basic Latin, Latin-1, general punctuation, ₩, arrows, CJK symbols, Hangul compatibility jamo.
BASE = [(0x20, 0x7E), (0xA0, 0xFF), (0x2000, 0x206F), (0x20A9, 0x20A9), (0x2190, 0x21FF), (0x3000, 0x303F), (0x3131, 0x318E)]


def site_syllables():
    files = [p for p in (ROOT / "website").rglob("*") if p.suffix in (".html", ".js", ".json") and "vendor" not in p.parts]
    text = "".join(p.read_text(encoding="utf-8") for p in files)
    return sorted({c for c in text if 0xAC00 <= ord(c) <= 0xD7A3})


def check():
    have = set(CHARSET.read_text(encoding="utf-8")) if CHARSET.exists() else set()
    missing = [c for c in site_syllables() if c not in have]
    if missing:
        sys.exit(f"font subset is missing {len(missing)} syllables ({''.join(missing[:40])}): run python -I scripts/build_fonts.py")
    print(f"ok: {len(have)} syllables in the font subset cover the website")


def build():
    from fontTools import subset  # imported here so --check needs only the standard library

    syllables = site_syllables()
    unicodes = [c for lo, hi in BASE for c in range(lo, hi + 1)] + [ord(c) for c in syllables]
    OUT.mkdir(parents=True, exist_ok=True)
    for weight, style in WEIGHTS.items():
        opts = subset.Options()
        opts.flavor = "woff2"
        font = subset.load_font(str(SRC / f"Pretendard-{style}.otf"), opts)
        sub = subset.Subsetter(opts)
        sub.populate(unicodes=unicodes)
        sub.subset(font)
        rename(font, style)
        dest = OUT / f"DahaeSans-{style}.woff2"
        subset.save_font(font, str(dest), opts)
        print(f"wrote {dest.relative_to(ROOT)} ({dest.stat().st_size // 1024} KB)")
    CHARSET.write_text("".join(syllables) + "\n", encoding="utf-8", newline="\n")
    (OUT / "OFL.txt").write_bytes((SRC / "OFL.txt").read_bytes())


def rename(font, style):
    """Replaces the reserved family name in every name record (OFL: modified versions are renamed)."""
    full = f"{FAMILY} {style}"
    names = {1: FAMILY, 2: style, 3: f"{full};subset", 4: full, 6: full.replace(" ", ""), 16: FAMILY, 17: style}
    table = font["name"]
    for rec in list(table.names):
        if rec.nameID in names:
            table.setName(names[rec.nameID], rec.nameID, rec.platformID, rec.platEncID, rec.langID)
        elif rec.nameID in (18, 21, 22):  # Mac compatible full name, WWS family / subfamily
            table.removeNames(nameID=rec.nameID)
    if "CFF " in font:
        cff = font["CFF "].cff
        cff.fontNames = [full.replace(" ", "")]
        top = cff.topDictIndex[0]
        top.FamilyName, top.FullName = FAMILY, full
    assert not any("Pretendard" in str(r) for r in table.names if r.nameID in names), "reserved name left in the name table"


if __name__ == "__main__":
    check() if "--check" in sys.argv else build()
