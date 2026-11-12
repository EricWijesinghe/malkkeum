"""Entry point (system Python + Pillow): render with Blender, then export sizes/app icons/contact sheets/manifest.

  python scripts/render_all.py                     # everything
  python scripts/render_all.py --only "nav_*,faq"  # subset (id globs), post-processing still covers all
  python scripts/render_all.py --post-only         # redo exports from existing raw renders
"""
import argparse
import glob
import os
import pathlib
import subprocess
import sys

import post

ROOT = pathlib.Path(__file__).resolve().parent.parent


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--only", default="*")
    ap.add_argument("--samples", type=int, default=32)
    ap.add_argument("--threads", type=int, default=4, help="Blender CPU threads (memory is tight on this PC)")
    ap.add_argument("--post-only", action="store_true")
    ap.add_argument("--out", default=str(ROOT / "out"))
    ap.add_argument("--blender", default=os.environ.get("BLENDER") or next(
        iter(sorted(glob.glob("F:/tools/blender/blender-*/blender.exe"), reverse=True)), "blender"))
    a = ap.parse_args()
    if not a.post_only:
        cmd = [a.blender, "-b", "-t", str(a.threads), "--factory-startup", "--python-exit-code", "1", "-P",
               str(ROOT / "scripts" / "blender_render.py"), "--", "--out", a.out, "--only", a.only,
               "--samples", str(a.samples)]
        p = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, text=True, errors="replace")
        lines = p.stdout.splitlines()
        print("\n".join(ln for ln in lines if ln.startswith("[dahae]")))
        if p.returncode:
            sys.exit("Blender failed:\n" + "\n".join(lines[-40:]))
    post.run(pathlib.Path(a.out), ROOT / "manifest.json", ROOT / "export" / "icons3d")


if __name__ == "__main__":
    main()
