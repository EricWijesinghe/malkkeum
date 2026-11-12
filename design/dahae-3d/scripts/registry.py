"""Icon registry. Adding an icon = one decorated builder function in scripts/icons/*.py.

Options (all optional):
  yaw, tilt      pose in degrees (default yaw -20: right side visible; tilt>0 shows the top)
  variants       {"name": {"remap": {...}, "yaw":..., "tilt":..., "margin":...}}; default one unnamed variant
  anim           "turntable" | "pop"  -> 24-frame PNG sequence
  gltf           True -> also export out/gltf/<id>.glb
  mode           "clay" (default) | "flat" | "mono"   (flat/mono: unlit, front view, for app icons)
  internal       True -> raw render only (source for app-icon compositing), not listed as an icon
"""
ICONS = {}


def icon(id_, desc, group, **opts):
    def deco(fn):
        assert id_ not in ICONS, f"duplicate icon id {id_}"
        ICONS[id_] = dict(id=id_, desc=desc, group=group, build=fn, **opts)
        return fn
    return deco
