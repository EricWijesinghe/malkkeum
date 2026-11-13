"""Dahae Sans = Pretendard (Kil Hyung-jin, SIL OFL 1.1) subset for the ui package (all 5 apps bundle it).
The OFL reserves the name "Pretendard", so the modified fonts are renamed: family "Dahae Sans" / "Dahae Sans Full".

  python -I app/tool/font_subset.py build <dir-with-original-Pretendard-*.otf>   # needs fonttools
  python -I app/tool/font_subset.py check                                    # needs fonttools

build: the 5 weights keep KS X 1001 Hangul (2,350) + Latin/punctuation + every char used by the ko/en ARBs and
Dart sources; Regular is also written to assets/fonts/full/ with the remaining syllables (all 11,172 are covered together), registered as the
family `Dahae Sans Full` and used as the first fallback, so rare user-typed syllables still render.
check: asserts every char in the ARBs (ko, en) and Dart string literals is in the shipped fonts.
"""
import re, sys, json, pathlib
from fontTools.ttLib import TTFont
from fontTools import subset

ROOT = pathlib.Path(__file__).resolve().parent.parent
FONTS = ROOT / "packages/ui/assets/fonts"
WEIGHTS = ["Regular", "Medium", "SemiBold", "Bold", "ExtraBold"]
FEATURES = ["kern", "liga", "ccmp", "locl", "mark", "mkmk", "tnum", "case"]
# Latin, Latin-1, general punctuation, currency, arrows/math, shapes, CJK symbols, jamo, kana, fullwidth forms.
STATIC = "U+0020-007E,U+00A0-00FF,U+2000-206F,U+20A9,U+20AC,U+2100-214F,U+2190-22FF,U+2460-24FF,U+25A0-26FF,U+3000-30FF,U+3130-318F,U+FF00-FFEF"
HANGUL_RE = re.compile("[가-힣]")


def ksx1001_hangul() -> str:
    out = []
    for hi in range(0xB0, 0xC9):
        for lo in range(0xA1, 0xFF):
            try:
                out.append(bytes([hi, lo]).decode("euc-kr"))
            except UnicodeDecodeError:
                pass
    return "".join(out)


def project_chars() -> set[str]:
    chars: set[str] = set()
    l10n = ROOT / "packages/core/lib/l10n"
    for name in ("app_ko.arb", "app_en.arb"):
        for k, v in json.loads((l10n / name).read_text("utf-8")).items():
            if isinstance(v, str):
                chars.update(v)
    for p in ROOT.rglob("*.dart"):
        if "l10n" in p.parts or ".dart_tool" in p.parts or "build" in p.parts:
            continue
        chars.update(re.sub(r"\s", "", p.read_text("utf-8")))
    return {c for c in chars if ord(c) > 0x7F and not c.isspace()}


def rename(font: TTFont, family: str, style: str) -> None:
    """Replace every name that carries the reserved name; copyright (0), description (9) and license (13, 14) stay."""
    ribbi = style in ("Regular", "Bold")
    ps = f"{family.replace(' ', '')}-{style}"
    names = {
        1: family if ribbi else f"{family} {style}",
        2: style if ribbi else "Regular",
        3: f"{ps};subset-of-Pretendard-1.309",
        4: f"{family} {style}",
        6: ps,
        16: family,
        17: style,
    }
    table = font["name"]
    for rec in list(table.names):
        carries = "Pretendard" in str(rec) and rec.nameID not in (0, 9, 13, 14)
        if rec.nameID in names or rec.nameID == 7 or carries:
            table.removeNames(nameID=rec.nameID)
    for nid, val in names.items():
        table.setName(val, nid, 3, 1, 0x409)
    cff = font["CFF "].cff
    cff.fontNames = [ps]
    top = cff.topDictIndex[0]
    top.FullName, top.FamilyName = f"{family} {style}", family


def run(src: pathlib.Path, dst: pathlib.Path, text: str, family: str, style: str, base: bool = True) -> None:
    opts = subset.Options()
    opts.layout_features = FEATURES
    opts.name_IDs = ["*"]
    opts.notdef_outline = True
    font = TTFont(src)
    s = subset.Subsetter(opts)
    s.populate(unicodes=(subset.parse_unicodes(STATIC) if base else []) + [ord(c) for c in text])
    s.subset(font)
    rename(font, family, style)
    dst.parent.mkdir(parents=True, exist_ok=True)
    font.save(dst)


def build(srcdir: pathlib.Path) -> None:
    text = ksx1001_hangul() + "".join(sorted(project_chars()))
    for w in WEIGHTS:
        run(srcdir / f"Pretendard-{w}.otf", FONTS / f"DahaeSans-{w}.otf", text, "Dahae Sans", w)
    # Fallback face only needs what the 5 main faces lack (it is consulted per missing glyph).
    rest = "".join(chr(c) for c in range(0xAC00, 0xD7A4) if chr(c) not in text)
    run(srcdir / "Pretendard-Regular.otf", FONTS / "full/DahaeSansFull-Regular.otf", rest, "Dahae Sans Full", "Regular", base=False)


def covered_by_pretendard(c: str) -> bool:
    o = ord(c)
    return 0xAC00 <= o <= 0xD7A3 or 0x3130 <= o <= 0x318F or 0xA0 <= o <= 0x24F or 0x2000 <= o <= 0x206F or o in (0x20A9, 0x20AC)


def check() -> int:
    # Scripts Pretendard lacks (CJK ideographs, Thai, emoji ...) always come from system fallback fonts.
    need = {c for c in project_chars() if covered_by_pretendard(c)}
    bad = 0
    for p in sorted(FONTS.glob("DahaeSans-*.otf")):
        cmap = TTFont(p).getBestCmap()
        missing = sorted(c for c in need if ord(c) not in cmap)
        if missing:
            bad += 1
            print(f"{p.name}: missing {len(missing)}: {''.join(missing)[:80]}")
    full = TTFont(FONTS / "full/DahaeSansFull-Regular.otf").getBestCmap()
    main = TTFont(FONTS / "DahaeSans-Regular.otf").getBestCmap()
    gaps = [c for c in range(0xAC00, 0xD7A4) if c not in full and c not in main]
    if gaps:
        bad += 1
        print(f"DahaeSansFull-Regular missing {len(gaps)} syllables")
    print("OK" if not bad else "FAIL", f"({len(need)} project chars checked)")
    return 1 if bad else 0


if __name__ == "__main__":
    if sys.argv[1:2] == ["build"]:
        build(pathlib.Path(sys.argv[2]))
    elif sys.argv[1:2] == ["check"]:
        sys.exit(check())
    else:
        sys.exit(__doc__)
