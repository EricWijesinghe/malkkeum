"""Blender side: build each icon and render raw PNGs. Run via render_all.py, or directly:
blender -b --python-exit-code 1 -P scripts/blender_render.py -- --out out [--only "nav_*,coupon"]"""
import argparse
import fnmatch
import json
import math
import pathlib
import sys

sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
import bpy  # noqa: E402

import icons  # noqa: E402,F401
import lib  # noqa: E402
from registry import ICONS  # noqa: E402

SMALL_PX, HERO_PX, ANIM_PX, FRAMES = 576, 1024, 512, 24  # small is 2x supersampled for the 288 px @3x


def anim_poses(kind, yaw, tilt):
    if kind == "turntable":
        return [dict(yaw=yaw + 360 * i / FRAMES, tilt=tilt) for i in range(FRAMES)]
    poses = []  # "pop": spring scale-in with a decaying yaw wobble
    for i in range(FRAMES):
        t = (i + 1) / FRAMES
        poses.append(dict(yaw=yaw + 50 * math.exp(-4 * t) * math.cos(7 * t), tilt=tilt,
                          scale=1 - math.exp(-5 * t) * math.cos(9 * t)))
    return poses


def render_icon(e, out, samples):
    raw = out / "_raw"
    mode = e.get("mode", "clay")
    for vname, v in e.get("variants", {"": {}}).items():
        name = f"{e['id']}_{vname}" if vname else e["id"]
        root = lib.new_scene(mode, samples, holdout=("yellow",))
        with lib.remap(v.get("remap", {})):
            e["build"]()
        if mode != "clay":  # unlit front view, tight crop: source for app-icon compositing
            lib.fit_camera(root, [dict(yaw=0)], 0.0, elev=0.0)
            lib.render(raw / f"{name}__flat.png", HERO_PX)
            continue
        if e.get("gltf"):
            (out / "gltf").mkdir(parents=True, exist_ok=True)
            bpy.ops.export_scene.gltf(filepath=str(out / "gltf" / f"{name}.glb"), export_format="GLB",
                                      export_apply=True, export_lights=False, export_cameras=False)
        p = dict(yaw=v.get("yaw", e.get("yaw", lib.DEFAULT_YAW)), tilt=v.get("tilt", e.get("tilt", 0.0)))
        lib.fit_camera(root, [p], v.get("margin", 0.06))
        lib.render(raw / f"{name}__small.png", SMALL_PX)
        _, verts = lib.fit_camera(root, [p], 0.12)
        shadow = lib.add_shadow(verts)
        lib.render(raw / f"{name}__hero.png", HERO_PX)
        if e.get("anim"):
            bpy.data.objects.remove(shadow)
            poses = anim_poses(e["anim"], **p)
            lib.fit_camera(root, poses, 0.06)
            for i, ps in enumerate(poses):
                lib.pose(root, **ps)
                lib.render(out / "anim" / name / f"{name}_{i:03d}.png", ANIM_PX)


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--out", required=True)
    ap.add_argument("--only", default="*", help="comma-separated id globs")
    ap.add_argument("--samples", type=int, default=32)
    a = ap.parse_args(sys.argv[sys.argv.index("--") + 1:])
    out = pathlib.Path(a.out)
    (out / "_raw").mkdir(parents=True, exist_ok=True)
    reg = [{k: v for k, v in e.items() if k != "build"} | {"variants": list(e.get("variants", {"": {}}))}
           for e in ICONS.values()]
    (out / "_raw" / "registry.json").write_text(json.dumps(
        {"icons": reg, "frames": FRAMES, "anim_px": ANIM_PX, "blender": bpy.app.version_string}, indent=1))
    pats = a.only.split(",")
    todo = [e for e in ICONS.values() if any(fnmatch.fnmatch(e["id"], p) for p in pats)]
    assert todo, f"--only {a.only!r} matches no icon"
    for n, e in enumerate(todo, 1):
        print(f"[dahae] {n}/{len(todo)} {e['id']}", flush=True)
        render_icon(e, out, a.samples)


main()
