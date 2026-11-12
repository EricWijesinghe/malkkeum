"""Shared scene, materials, lighting, camera and modelling primitives (runs inside Blender).

Model space: X right, Z up, front faces -Y. Builders use any size; the camera auto-fits.
"""
import math
from contextlib import contextmanager

import bmesh
import bpy
from mathutils import Matrix, Vector

PALETTE = {
    "teal": "#1E9EBA", "dteal": "#187A8F", "yellow": "#FFD95A", "ink": "#17232C",
    # derived neutrals/tints
    "white": "#F6FBFC", "lteal": "#8FD0E2", "red": "#E8604C",  # red: "no/unavailable" only
}
# Idle (inactive nav / disabled) look: palette collapsed to slate greys.
IDLE = {"teal": "#9FB3BD", "dteal": "#7F96A1", "yellow": "#EEF3F5", "white": "#EEF3F5",
        "lteal": "#C7D5DB", "ink": "#5E727D"}

DEFAULT_YAW, CAM_ELEV = -20.0, 15.0
state = {"root": None, "mode": "clay", "remap": {}, "holdout": ()}


def _lin(hex_):
    def f(c):
        c /= 255
        return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4
    h = hex_.lstrip("#")
    return (*[f(int(h[i:i + 2], 16)) for i in (0, 2, 4)], 1.0)


def mat(name):
    """Material for a palette name, honouring the current mode (clay/flat/mono) and remap."""
    mode = state["mode"]
    hex_ = state["remap"].get(name, PALETTE[name])
    if mode == "mono":
        hex_ = "#FFFFFF"
    hold = mode == "mono" and name in state["holdout"]
    key = f"{mode}_{hex_}_{hold}"
    m = bpy.data.materials.get(key)
    if m:
        return m
    m = bpy.data.materials.new(key)
    m.use_nodes = True
    nt = m.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    if hold:
        sh = nt.nodes.new("ShaderNodeHoldout")
        nt.links.new(sh.outputs[0], out.inputs["Surface"])
    elif mode == "clay":
        sh = nt.nodes.new("ShaderNodeBsdfPrincipled")
        sh.inputs["Base Color"].default_value = _lin(hex_)
        sh.inputs["Roughness"].default_value = 0.45
        sh.inputs["Coat Weight"].default_value = 0.1
        sh.inputs["Coat Roughness"].default_value = 0.25
        nt.links.new(sh.outputs[0], out.inputs["Surface"])
    else:  # flat / mono: exact colour, no lighting
        sh = nt.nodes.new("ShaderNodeEmission")
        sh.inputs["Color"].default_value = _lin(hex_)
        nt.links.new(sh.outputs[0], out.inputs["Surface"])
    return m


@contextmanager
def remap(table):
    prev = state["remap"]
    state["remap"] = {**prev, **table}
    try:
        yield
    finally:
        state["remap"] = prev


def _link(o, loc, rot, scale=1.0):
    bpy.context.scene.collection.objects.link(o)
    o.parent = state["root"]
    o.location = loc
    o.rotation_euler = [math.radians(a) for a in rot]
    o.scale = (scale,) * 3
    return o


@contextmanager
def group(loc=(0, 0, 0), rot=(0, 0, 0), scale=1.0):
    """Sub-assembly: everything built inside is transformed together."""
    e = _link(bpy.data.objects.new("g", None), loc, rot, scale)
    prev, state["root"] = state["root"], e
    try:
        yield e
    finally:
        state["root"] = prev


def _mesh_obj(bm, m, loc, rot):
    me = bpy.data.meshes.new("m")
    bm.to_mesh(me)
    bm.free()
    for p in me.polygons:
        p.use_smooth = True
    me.materials.append(mat(m))
    o = _link(bpy.data.objects.new("o", me), loc, rot)
    o.modifiers.new("wn", "WEIGHTED_NORMAL").keep_sharp = True
    return o


def box(m, size, loc=(0, 0, 0), r=0.08, rot=(0, 0, 0)):
    """Rounded box. r = corner radius."""
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    for v in bm.verts:
        v.co = Vector((v.co.x * size[0], v.co.y * size[1], v.co.z * size[2]))
    r = min(r, min(size) * 0.49)
    bmesh.ops.bevel(bm, geom=bm.edges[:], offset=r, segments=6, affect="EDGES", profile=0.5)
    return _mesh_obj(bm, m, loc, rot)


def cyl(m, r, h, loc=(0, 0, 0), rot=(0, 0, 0), r2=None, bevel=0.05):
    """Cylinder/cone along Z (r at bottom, r2 at top) with rounded rims."""
    r2 = r if r2 is None else r2
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=48, radius1=r, radius2=r2, depth=h)
    rims = [e for e in bm.edges if abs(e.verts[0].co.z - e.verts[1].co.z) < 1e-6]
    b = min(bevel, h * 0.45, max(min(r, r2), 0.02) * 0.9)
    if rims and b > 0.005:
        bmesh.ops.bevel(bm, geom=rims, offset=b, segments=5, affect="EDGES", profile=0.5)
    return _mesh_obj(bm, m, loc, rot)


def ball(m, r, loc=(0, 0, 0), scale=(1, 1, 1), rot=(0, 0, 0)):
    bm = bmesh.new()
    bmesh.ops.create_uvsphere(bm, u_segments=40, v_segments=20, radius=r)
    for v in bm.verts:
        v.co = Vector((v.co.x * scale[0], v.co.y * scale[1], v.co.z * scale[2]))
    return _mesh_obj(bm, m, loc, rot)


def slab(m, pts, depth=0.3, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.05, holes=()):
    """Extruded 2D outline standing in the XZ plane (pts are (x, z)), rounded edges."""
    cu = bpy.data.curves.new("c", "CURVE")
    cu.dimensions, cu.fill_mode = "2D", "BOTH"
    for ring in (pts, *holes):
        sp = cu.splines.new("POLY")
        sp.points.add(len(ring) - 1)
        for p, (x, y) in zip(sp.points, ring):
            p.co = (x, y, 0, 1)
        sp.use_cyclic_u = True
    bevel = min(bevel, depth * 0.45)
    cu.extrude, cu.bevel_depth, cu.bevel_resolution, cu.offset = depth / 2 - bevel, bevel, 4, -bevel
    cu.materials.append(mat(m))
    o = _link(bpy.data.objects.new("s", cu), loc, (0, 0, 0))
    user = Matrix.Identity(4)
    for axis, a in zip("XYZ", rot):
        user = Matrix.Rotation(math.radians(a), 4, axis) @ user
    o.rotation_euler = (user @ Matrix.Rotation(math.radians(90), 4, "X")).to_euler()
    return o


def tube(m, pts, r=0.08, cyclic=False, smooth=True):
    """Round tube through 3D points (smooth = curve through them), ball-capped ends."""
    cu = bpy.data.curves.new("t", "CURVE")
    cu.dimensions, cu.bevel_depth, cu.bevel_resolution = "3D", r, 6
    cu.resolution_u, cu.use_fill_caps = 16, True
    if smooth:
        sp = cu.splines.new("BEZIER")
        sp.bezier_points.add(len(pts) - 1)
        for bp, p in zip(sp.bezier_points, pts):
            bp.co = p
            bp.handle_left_type = bp.handle_right_type = "AUTO"
    else:
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for sp_p, p in zip(sp.points, pts):
            sp_p.co = (*p, 1)
    sp.use_cyclic_u = cyclic
    cu.materials.append(mat(m))
    o = _link(bpy.data.objects.new("t", cu), (0, 0, 0), (0, 0, 0))
    if not cyclic:
        ball(m, r, pts[0])
        ball(m, r, pts[-1])
    return o


# ---- 2D outline helpers (lists of (x, z)) -------------------------------------------------

def rnd(pts, r, n=6):
    """Fillet every corner of a polygon with radius ~r (clamped to half the shorter edge)."""
    out = []
    k = len(pts)
    for i in range(k):
        v, a, b = Vector(pts[i]), Vector(pts[i - 1]), Vector(pts[(i + 1) % k])
        da, db = a - v, b - v
        d = min(r, da.length / 2, db.length / 2)
        if d < 1e-4:
            out.append(tuple(v))
            continue
        p0, p2 = v + da.normalized() * d, v + db.normalized() * d
        for j in range(n + 1):
            t = j / n
            out.append(tuple((1 - t) ** 2 * p0 + 2 * t * (1 - t) * v + t * t * p2))
    return out


def rrect(w, h, r=0.1, c=(0, 0)):
    x, y = c
    return rnd([(x - w / 2, y - h / 2), (x + w / 2, y - h / 2), (x + w / 2, y + h / 2), (x - w / 2, y + h / 2)], r)


def circ(r, c=(0, 0), n=48, a0=0.0, a1=360.0):
    full = abs(a1 - a0) >= 360
    steps = n if full else n + 1
    return [(c[0] + r * math.cos(math.radians(a0 + (a1 - a0) * i / n)),
             c[1] + r * math.sin(math.radians(a0 + (a1 - a0) * i / n))) for i in range(steps)]


def star(R, r, n=5, rot=90.0, fillet=0.04):
    pts = []
    for i in range(n * 2):
        a = math.radians(rot + i * 180 / n)
        q = R if i % 2 == 0 else r
        pts.append((q * math.cos(a), q * math.sin(a)))
    return rnd(pts, fillet)


def heart(s=1.0):
    pts = []
    for i in range(48):
        t = 2 * math.pi * i / 48
        pts.append((s * 16 * math.sin(t) ** 3 / 17,
                    s * (13 * math.cos(t) - 5 * math.cos(2 * t) - 2 * math.cos(3 * t) - math.cos(4 * t)) / 17))
    return pts[::-1]


def stroke(pts, w, r=None):
    """Outline of a thick polyline (mitred joins, rounded ends/corners)."""
    left, right = [], []
    k = len(pts)
    for i in range(k):
        p = Vector(pts[i])
        d1 = (p - Vector(pts[i - 1])).normalized() if i > 0 else None
        d2 = (Vector(pts[i + 1]) - p).normalized() if i < k - 1 else None
        d1, d2 = d1 or d2, d2 or d1
        t = (d1 + d2).normalized()
        nrm = Vector((-t.y, t.x))
        m = w / 2 / max(nrm.dot(Vector((-d1.y, d1.x))), 0.35)
        left.append(tuple(p + nrm * m))
        right.append(tuple(p - nrm * m))
    return rnd(left + right[::-1], w * 0.45 if r is None else r)


def check_pts(s=1.0, w=0.26, c=(0, 0)):
    return stroke([(c[0] - 0.46 * s, c[1] + 0.02 * s), (c[0] - 0.14 * s, c[1] - 0.32 * s),
                   (c[0] + 0.48 * s, c[1] + 0.38 * s)], w * s)


def house_pts(w, h, rh, r=0.12):
    """Pentagon house outline, base centred on the origin."""
    return rnd([(-w / 2, 0), (w / 2, 0), (w / 2, h), (0, h + rh), (-w / 2, h)], r)


def roof_pts(w, h, rh, t=0.22, over=0.2):
    """Chevron roof stroke sitting on a house_pts(w, h, rh) outline."""
    sx, sz = w / 2, -rh
    k = over / math.hypot(sx, sz)
    return stroke([(-w / 2 - sx * k, h + sz * k), (0, h + rh), (w / 2 + sx * k, h + sz * k)], t)


def sparkle(m, s, loc, depth=0.14):
    return slab(m, star(s, s * 0.36, 4, 90, s * 0.08), depth, loc, bevel=0.04)


# ---- scene / camera / render ---------------------------------------------------------------

def new_scene(mode="clay", samples=32, holdout=()):
    bpy.ops.wm.read_factory_settings(use_empty=True)
    state.update(mode=mode, remap={}, holdout=holdout)
    sc = bpy.context.scene
    sc.render.engine = "BLENDER_EEVEE"
    sc.eevee.taa_render_samples = samples
    sc.render.film_transparent = True
    sc.render.image_settings.file_format = "PNG"
    sc.render.image_settings.color_mode = "RGBA"
    sc.render.resolution_percentage = 100
    sc.view_settings.view_transform = "Standard"  # keep brand colours true (no AgX/Filmic shift)
    sc.view_settings.look = "None"
    w = bpy.data.worlds.new("w")
    w.use_nodes = True
    bg = w.node_tree.nodes["Background"]
    bg.inputs[0].default_value = (1, 1, 1, 1)
    bg.inputs[1].default_value = 0.45
    sc.world = w
    # key from upper-left-front (soft shadow), fill from right, rim from above-behind
    for name, direction, energy, angle, shadow in (
        ("key", (0.55, 0.6, -0.75), 2.6, 35, True),
        ("fill", (-0.8, 0.5, -0.2), 0.7, 60, False),
        ("rim", (-0.2, -0.7, -0.6), 0.6, 40, False),
    ):
        ld = bpy.data.lights.new(name, "SUN")
        ld.energy, ld.angle, ld.use_shadow = energy, math.radians(angle), shadow
        lo = bpy.data.objects.new(name, ld)
        sc.collection.objects.link(lo)
        lo.rotation_euler = Vector(direction).to_track_quat("-Z", "Y").to_euler()
    root = bpy.data.objects.new("root", None)
    sc.collection.objects.link(root)
    state["root"] = root
    return root


def pose(root, yaw=DEFAULT_YAW, tilt=0.0, scale=1.0):
    """Yaw about model Z, then tilt the top toward the camera."""
    root.matrix_basis = (Matrix.Rotation(math.radians(tilt), 4, "X") @ Matrix.Rotation(math.radians(yaw), 4, "Z")
                         @ Matrix.Scale(scale, 4))
    bpy.context.view_layer.update()


def _world_verts(skip=()):
    dg = bpy.context.evaluated_depsgraph_get()
    for o in bpy.context.scene.objects:
        if o.type not in ("MESH", "CURVE") or o in skip:
            continue
        ev = o.evaluated_get(dg)
        me = ev.to_mesh()
        mw = ev.matrix_world
        yield from (mw @ v.co for v in me.vertices)
        ev.to_mesh_clear()


def fit_camera(root, poses, margin, elev=CAM_ELEV):
    """Orthographic camera framing the model over all given poses. Returns (camera, verts of last pose)."""
    sc = bpy.context.scene
    cd = bpy.data.cameras.new("cam")
    cd.type = "ORTHO"
    cam = bpy.data.objects.new("cam", cd)
    sc.collection.objects.link(cam)
    sc.camera = cam
    e = math.radians(elev)
    cam.location = Vector((0, -20 * math.cos(e), 20 * math.sin(e)))
    cam.rotation_euler = (-cam.location).to_track_quat("-Z", "Y").to_euler()
    bpy.context.view_layer.update()
    inv = cam.matrix_world.inverted()
    xs, ys, verts = [], [], []
    for p in poses:
        pose(root, **p)
        verts = list(_world_verts())
        for v in verts:
            c = inv @ v
            xs.append(c.x)
            ys.append(c.y)
    assert xs, "icon builder produced no geometry"
    w, h = max(xs) - min(xs), max(ys) - min(ys)
    cd.ortho_scale = max(w, h) / (1 - 2 * margin)
    cam.location += cam.matrix_world.to_3x3() @ Vector(((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, 0))
    return cam, verts


def add_shadow(verts):
    """Soft blob contact shadow (Eevee has no shadow catcher). Hero renders only."""
    xs, ys, zs = [v.x for v in verts], [v.y for v in verts], [v.z for v in verts]
    rad = 0.62 * max(max(xs) - min(xs), max(ys) - min(ys))
    bm = bmesh.new()
    bmesh.ops.create_grid(bm, x_segments=1, y_segments=1, size=rad)
    me = bpy.data.meshes.new("shadow")
    bm.to_mesh(me)
    bm.free()
    m = bpy.data.materials.new("shadow")
    m.use_nodes = True
    m.surface_render_method = "BLENDED"
    nt = m.node_tree
    nt.nodes.clear()
    tc = nt.nodes.new("ShaderNodeTexCoord")
    mp = nt.nodes.new("ShaderNodeMapping")
    mp.inputs["Location"].default_value = (-1, -1, 0)
    mp.inputs["Scale"].default_value = (2, 2, 1)
    gr = nt.nodes.new("ShaderNodeTexGradient")
    gr.gradient_type = "QUADRATIC_SPHERE"
    mul = nt.nodes.new("ShaderNodeMath")
    mul.operation = "MULTIPLY"
    mul.inputs[1].default_value = 0.55
    tr, em = nt.nodes.new("ShaderNodeBsdfTransparent"), nt.nodes.new("ShaderNodeEmission")
    em.inputs["Color"].default_value = _lin(PALETTE["ink"])
    mix, out = nt.nodes.new("ShaderNodeMixShader"), nt.nodes.new("ShaderNodeOutputMaterial")
    for a, b in ((tc.outputs["Generated"], mp.inputs["Vector"]), (mp.outputs[0], gr.inputs[0]),
                 (gr.outputs["Fac"], mul.inputs[0]), (mul.outputs[0], mix.inputs[0]),
                 (tr.outputs[0], mix.inputs[1]), (em.outputs[0], mix.inputs[2]), (mix.outputs[0], out.inputs["Surface"])):
        nt.links.new(a, b)
    me.materials.append(m)
    o = bpy.data.objects.new("shadow", me)
    bpy.context.scene.collection.objects.link(o)
    o.location = ((max(xs) + min(xs)) / 2, (max(ys) + min(ys)) / 2, min(zs) - 0.01)
    return o


def render(path, px):
    sc = bpy.context.scene
    sc.render.resolution_x = sc.render.resolution_y = px
    sc.render.filepath = str(path)
    bpy.ops.render.render(write_still=True)
