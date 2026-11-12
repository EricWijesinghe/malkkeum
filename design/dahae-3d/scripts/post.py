"""Post-processing (Pillow): size exports, app icons, contact sheets, manifest, sanity checks."""
import json
import pathlib

from PIL import Image, ImageDraw, ImageFont

from export_map import EXPORT, LARGE

SIZES = {"1x": 96, "2x": 192, "3x": 288}
HERO = (512, 1024)
BG_LIGHT, BG_INK, SHEET_LIGHT, SHEET_DARK = "#EFF9FB", "#17232C", "#FFFFFF", "#17232C"
LANCZOS = Image.Resampling.LANCZOS
APP_PX = {"": 64, "2.0x": 128, "3.0x": 192}  # 64 dp base; "" = the 1x file Flutter needs beside the variants
APP_LARGE_PX = {"": 160, "2.0x": 320, "3.0x": 480}  # 160 dp
APP_BUDGET = 3 * 1024 * 1024


def _checked(path):
    """Open a render and assert it is a sane icon: not empty, reasonably filling the frame."""
    im = Image.open(path).convert("RGBA")
    bbox = im.getchannel("A").point(lambda a: 255 if a > 40 else 0).getbbox()
    assert bbox, f"{path.name}: render is empty"
    fill = max(bbox[2] - bbox[0], bbox[3] - bbox[1]) / im.width
    assert 0.55 <= fill <= 1.0, f"{path.name}: icon fills {fill:.0%} of the frame"
    return im


def _save(im, path):
    path.parent.mkdir(parents=True, exist_ok=True)
    im.save(path, optimize=True)
    return path


def _export_icons(out, reg):
    raw, entries, sheet = out / "_raw", [], []
    for e in reg["icons"]:
        if e.get("internal"):
            continue
        variants = []
        for v in e["variants"]:
            name = f"{e['id']}_{v}" if v else e["id"]
            small, hero = raw / f"{name}__small.png", raw / f"{name}__hero.png"
            if not (small.exists() and hero.exists()):
                print(f"[post] WARNING {name}: not rendered yet, skipped")
                continue
            s, h = _checked(small), _checked(hero)
            d = out / "icons" / e["id"]
            files = {k: _save(s.resize((px, px), LANCZOS), d / f"{name}@{k}.png") for k, px in SIZES.items()}
            files |= {str(px): _save(h.resize((px, px), LANCZOS), d / f"{name}_{px}.png") for px in HERO}
            variants.append({"variant": v or "default", "name": name,
                             "files": {k: p.relative_to(out.parent).as_posix() for k, p in files.items()}})
            sheet.append((name, s))
        if not variants:
            continue
        item = {"id": e["id"], "group": e["group"], "description": e["desc"], "variants": variants}
        if e.get("anim"):
            frames = sorted((out / "anim" / e["id"]).glob("*.png"))
            assert len(frames) == reg["frames"], f"{e['id']}: {len(frames)} animation frames"
            for f in frames:
                Image.open(f).verify()
            item["animation"] = {"type": e["anim"], "frames": len(frames), "fps": 24, "size": reg["anim_px"],
                                 "loop": e["anim"] == "turntable",
                                 "files": [f.relative_to(out.parent).as_posix() for f in frames]}
        glb = out / "gltf" / f"{e['id']}.glb"
        if e.get("gltf") and glb.exists():
            item["gltf"] = glb.relative_to(out.parent).as_posix()
        names = {v["name"] for v in variants}
        item["app_ids"] = sorted(i for i, n in EXPORT.items() if n in names)
        entries.append(item)
    return entries, sheet


def _placed(logo, px, box, bg=None):
    """Logo scaled into a centred box (fraction of the canvas) on a transparent or solid canvas."""
    k = box * px / max(logo.size)
    lg = logo.resize((round(logo.width * k), round(logo.height * k)), LANCZOS)
    canvas = Image.new("RGBA", (px, px), bg or (0, 0, 0, 0))
    canvas.alpha_composite(lg, ((px - lg.width) // 2, (px - lg.height) // 2))
    return canvas


def _export_appicons(out):
    raw, d = out / "_raw", out / "appicon"
    src = {k: raw / f"logo_{k}__flat.png" for k in ("flat", "mono")}
    if not all(p.exists() for p in src.values()):
        print("[post] WARNING logo_flat/logo_mono not rendered yet, app icons skipped")
        return {}
    flat, mono = (Image.open(p).convert("RGBA") for p in src.values())
    flat, mono = flat.crop(flat.getbbox()), mono.crop(mono.getbbox())
    # Adaptive icon: 108 dp canvas = 432 px; anything outside the centred 66 dp (264 px) circle may be masked.
    safe = 0.44
    files = {
        "android_adaptive_foreground": _save(_placed(flat, 432, safe), d / "android/ic_launcher_foreground.png"),
        "android_adaptive_background": _save(Image.new("RGB", (432, 432), BG_LIGHT), d / "android/ic_launcher_background.png"),
        "android_adaptive_background_dark": _save(Image.new("RGB", (432, 432), BG_INK), d / "android/ic_launcher_background_ink.png"),
        "android_monochrome": _save(_placed(mono, 432, safe), d / "android/ic_launcher_monochrome.png"),
        "android_legacy_512": _save(_placed(flat, 512, 0.58, BG_LIGHT).convert("RGB"), d / "android/ic_launcher_512.png"),
        "ios_1024_opaque": _save(_placed(flat, 1024, 0.6, BG_LIGHT).convert("RGB"), d / "ios/AppIcon-1024.png"),
        "windows_msix_300": _save(_placed(flat, 300, 0.62, BG_LIGHT).convert("RGB"), d / "windows/Square300x300Logo.png"),
        "web_512": _save(_placed(flat, 512, 0.56, BG_LIGHT).convert("RGB"), d / "web/icon-512.png"),
        "web_192": _save(_placed(flat, 192, 0.56, BG_LIGHT).convert("RGB"), d / "web/icon-192.png"),
        "logo_flat_1024": _save(_placed(flat, 1024, 0.9), d / "logo_flat_1024.png"),
        "logo_mono_1024": _save(_placed(mono, 1024, 0.9), d / "logo_mono_1024.png"),
    }
    assert Image.open(files["ios_1024_opaque"]).mode == "RGB", "iOS icon must be opaque"
    return {k: p.relative_to(out.parent).as_posix() for k, p in files.items()}


def _contact_sheet(sheet, path, bg, fg, cols=6):
    cw, ch, pad = 128 + 64 + 32 + 44, 128 + 34, 12
    rows = -(-len(sheet) // cols)
    im = Image.new("RGBA", (cols * cw + pad, rows * ch + pad), bg)
    dr, font = ImageDraw.Draw(im), ImageFont.load_default(size=12)
    for i, (name, src) in enumerate(sheet):
        x, y = pad + (i % cols) * cw, pad + (i // cols) * ch
        for px in (128, 64, 32):
            im.alpha_composite(src.resize((px, px), LANCZOS), (x, y + 128 - px))
            x += px + 10
        dr.text((pad + (i % cols) * cw, y + 132), name, fill=fg, font=font)
    _save(im.convert("RGB"), path)


def _export_app(out, dest):
    """WebP set for the Flutter asset folder: <dest>/{2.0x,3.0x}/<id>.webp (+ large/ at 160 dp). No ground shadow."""
    for old in dest.rglob("*.webp"):
        old.unlink()
    index, missing, total = {}, [], 0
    for id_, name in sorted(EXPORT.items()):
        src = out / "_raw" / f"{name}__small.png"
        if not src.exists():
            missing.append(id_)
            continue
        im = Image.open(src).convert("RGBA")
        jobs = [(dest / k / f"{id_}.webp", px) for k, px in APP_PX.items()]
        if id_ in LARGE:
            jobs += [(dest / "large" / k / f"{id_}.webp", px) for k, px in APP_LARGE_PX.items()]
        for path, px in jobs:
            path.parent.mkdir(parents=True, exist_ok=True)
            im.resize((px, px), LANCZOS).save(path, "WEBP", quality=90, method=6)
            assert Image.open(path).mode == "RGBA", f"{path.name}: alpha lost"
            total += path.stat().st_size
        index[id_] = {"source": name, "alias": name != id_, "large": id_ in LARGE}
    assert total <= APP_BUDGET, f"app export is {total / 1e6:.2f} MB, over the 3 MB budget"
    (dest / "index.json").write_text(json.dumps(index, indent=1))
    if missing:
        print(f"[post] WARNING app ids without a render: {' '.join(missing)}")
    print(f"[post] app export: {len(index)}/{len(EXPORT)} ids, {total / 1e6:.2f} MB -> {dest}")
    return {"dir": "export/icons3d", "ids": len(index), "bytes": total, "missing": missing,
            "base_dp": 64, "px": {k or "1x": v for k, v in APP_PX.items()}, "large_dp": 160,
            "large_px": {k or "1x": v for k, v in APP_LARGE_PX.items()}, "large_ids": list(LARGE)}


def run(out, manifest_path, export_dir):
    reg = json.loads((out / "_raw" / "registry.json").read_text())
    entries, sheet = _export_icons(out, reg)
    _contact_sheet(sheet, out / "contact-light.png", SHEET_LIGHT, "#17232C")
    _contact_sheet(sheet, out / "contact-dark.png", SHEET_DARK, "#F6FBFC")
    manifest = {
        "name": "Dahae 3D icon set", "generator": f"Blender {reg['blender']} (Eevee) + Pillow",
        "palette": {"teal": "#1E9EBA", "darkTeal": "#187A8F", "checkYellow": "#FFD95A", "ink": "#17232C"},
        "sizes": {"base_dp": 96, **SIZES, "hero": list(HERO),
                  "note": "@1x/@2x/@3x have no ground shadow; 512/1024 hero renders include a soft contact shadow"},
        "icon_count": len(entries), "icons": entries, "app_icon": _export_appicons(out),
        "contact_sheets": ["out/contact-light.png", "out/contact-dark.png"],
        "app_export": _export_app(out, export_dir),
    }
    manifest_path.write_text(json.dumps(manifest, indent=1, ensure_ascii=False))
    print(f"[post] {len(entries)} icons, {len(sheet)} renders -> {manifest_path}")
