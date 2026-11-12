"""Reusable sub-assemblies shared by several icons."""
import math

from lib import ball, box, check_pts, circ, cyl, group, house_pts, rnd, roof_pts, rrect, slab, star, tube


def house(w=1.5, h=0.95, rh=0.7, d=0.7, body="teal", roof="dteal"):
    slab(body, house_pts(w, h, rh), d, bevel=0.08)
    slab(roof, roof_pts(w, h, rh), d + 0.16, bevel=0.07)


def check(m="yellow", s=1.0, loc=(0, 0, 0), depth=0.2, w=0.26):
    return slab(m, check_pts(s, w), depth, loc, bevel=0.06)


def bubble(m, w=1.7, h=1.25, depth=0.45, loc=(0, 0, 0), flip=False):
    k = -1 if flip else 1
    pts = [(-w / 2, -h / 2), (-0.34 * w, -h / 2), (-0.40 * w, -h / 2 - 0.36), (-0.06 * w, -h / 2),
           (w / 2, -h / 2), (w / 2, h / 2), (-w / 2, h / 2)]
    pts = [(k * x, z) for x, z in pts][::k]
    return slab(m, rnd(pts, 0.3), depth, loc, bevel=0.1)


def calendar_base():
    box("teal", (1.6, 0.34, 1.5), (0, 0, 0), r=0.16)
    box("dteal", (1.62, 0.36, 0.44), (0, 0, 0.54), r=0.16)
    for x in (-0.42, 0.42):
        box("white", (0.13, 0.42, 0.34), (x, 0, 0.8), r=0.06)


# person(): see the domed version below


def pin(glyph):
    """Map pin with a dark face disc; glyph(y) draws the symbol on it."""
    ball("teal", 0.72, (0, 0, 0.5))
    cyl("teal", 0.03, 1.2, (0, 0, -0.45), r2=0.62, bevel=0.02)
    ball("dteal", 0.46, (0, -0.63, 0.5), scale=(1, 0.2, 1))
    glyph(-0.74)


def ac_unit(w=1.9):
    box("teal", (w + 0.14, 0.3, 0.86), (0, 0.2, 0), r=0.14)  # frame so the pale body holds on light backgrounds
    box("lteal", (w, 0.55, 0.72), (0, 0, 0), r=0.18)
    box("teal", (w * 0.8, 0.12, 0.13), (0, -0.25, -0.2), r=0.05)
    box("dteal", (w * 0.8, 0.3, 0.06), (0, -0.3, -0.34), r=0.03, rot=(-25, 0, 0))
    ball("yellow", 0.06, (w * 0.38, -0.27, 0.12))


def open_box():
    box("dteal", (1.4, 1.4, 0.1), (0, 0, 0.05), r=0.04)
    for y in (-0.66, 0.66):
        box("teal", (1.44, 0.1, 0.95), (0, y, 0.475), r=0.04)
    for x in (-0.66, 0.66):
        box("teal", (0.1, 1.4, 0.95), (x, 0, 0.475), r=0.04)
    for loc, rot in (((0, -0.68, 0.92), (55, 0, 0)), ((0, 0.68, 0.92), (-55, 0, 0)),
                     ((-0.68, 0, 0.92), (0, -55, 0)), ((0.68, 0, 0.92), (0, 55, 0))):
        with group(loc, rot):
            size = (1.36, 0.08, 0.55) if rot[0] else (0.08, 1.36, 0.55)
            box("lteal", size, (0, 0, 0.27), r=0.035)


def elevator(doors="lteal", arrows="yellow"):
    box("dteal", (1.35, 0.5, 1.8), (0, 0, 0.9), r=0.12)
    for x in (-0.26, 0.26):
        slab(doors, rrect(0.46, 1.25, 0.05), 0.08, (x, -0.25, 0.72), bevel=0.03)
    slab(arrows, rnd([(-0.3, 1.47), (-0.06, 1.47), (-0.18, 1.67)], 0.03), 0.08, (0, -0.25, 0), bevel=0.03)
    slab(arrows, rnd([(0.06, 1.67), (0.3, 1.67), (0.18, 1.47)], 0.03), 0.08, (0, -0.25, 0), bevel=0.03)


def wheel(loc, r=0.26):
    cyl("dteal", r, 0.2, loc, rot=(90, 0, 0), bevel=0.07)
    cyl("yellow", r * 0.42, 0.24, loc, rot=(90, 0, 0), bevel=0.03)


def ring(m, big_r, r, loc=(0, 0, 0), plane="xz"):
    """Torus; plane xz faces the viewer, xy lies flat, yz faces sideways."""
    def p(a, b):
        return {"xz": (loc[0] + a, loc[1], loc[2] + b), "xy": (loc[0] + a, loc[1] + b, loc[2]),
                "yz": (loc[0], loc[1] + a, loc[2] + b)}[plane]
    return tube(m, [p(x, z) for x, z in circ(big_r, n=12)], r, cyclic=True)


# ---- second batch of shared parts (app-id alignment) -----------------------------------------------

def person(head, body, loc=(0, 0, 0), s=1.0):
    with group(loc, scale=s):
        ball(head, 0.4, (0, 0, 1.17))
        cyl(body, 0.62, 0.78, (0, 0, 0.39), r2=0.42, bevel=0.3)


def truck():
    box("teal", (1.35, 0.95, 1.0), (-0.3, 0, 0.82), r=0.12)
    box("white", (1.37, 0.97, 0.16), (-0.3, 0, 0.6), r=0.05)
    box("dteal", (0.72, 0.9, 0.74), (0.72, 0, 0.69), r=0.16)
    slab("lteal", rrect(0.38, 0.3, 0.07), 0.08, (0.78, -0.44, 0.8))
    box("lteal", (0.06, 0.6, 0.3), (1.07, 0, 0.8), r=0.03)
    wheel((-0.55, -0.42, 0.26))
    wheel((0.68, -0.42, 0.26))


def ticket(body="teal", star_m="yellow", dots="white"):
    w, h, r = 1.9, 1.15, 0.17
    pts = ([(-w / 2, -h / 2), (w / 2, -h / 2)] + circ(r, (w / 2, 0), 10, -90, -270)
           + [(w / 2, h / 2), (-w / 2, h / 2)] + circ(r, (-w / 2, 0), 10, 90, -90))
    slab(body, rnd(pts, 0.14), 0.24, bevel=0.07)
    slab(star_m, star(0.34, 0.15, 5), 0.1, (-0.3, -0.13, 0), bevel=0.03)
    for z in (-0.36, -0.12, 0.12, 0.36):
        box(dots, (0.07, 0.06, 0.13), (0.42, -0.12, z), r=0.03)


def card():
    slab("teal", rrect(1.9, 1.25, 0.16), 0.12, bevel=0.04)
    box("dteal", (1.86, 0.05, 0.22), (0, -0.05, 0.28), r=0.02)
    slab("yellow", rrect(0.36, 0.28, 0.07), 0.06, (-0.55, -0.07, -0.08), bevel=0.02)
    for x in (0.05, 0.3, 0.55):
        box("white", (0.18, 0.04, 0.08), (x, -0.06, -0.38), r=0.02)


def wallet(cards=True):
    if cards:
        slab("white", rrect(1.2, 0.7, 0.08), 0.05, (-0.05, 0.02, 0.62), rot=(0, 6, 0), bevel=0.02)
        slab("yellow", rrect(1.2, 0.7, 0.08), 0.05, (0.1, -0.06, 0.5), rot=(0, -4, 0), bevel=0.02)
    box("dteal", (1.75, 0.42, 1.15), (0, 0, -0.1), r=0.17)
    box("teal", (1.77, 0.44, 0.5), (0, 0, 0.24), r=0.17)
    box("teal", (0.55, 0.48, 0.34), (0.66, 0, -0.1), r=0.14)
    ball("yellow", 0.1, (0.7, -0.25, -0.1), scale=(1, 0.5, 1))


def clipboard():
    box("teal", (1.35, 0.18, 1.75), (0, 0, 0), r=0.08)
    slab("white", rrect(1.08, 1.4, 0.08), 0.06, (0, -0.1, -0.06), bevel=0.02)
    box("dteal", (0.62, 0.26, 0.26), (0, -0.02, 0.86), r=0.09)


def document():
    box("teal", (1.48, 0.14, 1.88), (0, 0.1, 0), r=0.14)
    box("white", (1.3, 0.14, 1.7), (0, 0, 0), r=0.1)
    box("dteal", (0.9, 0.07, 0.16), (-0.1, -0.06, 0.52), r=0.03)
    for z, w in ((0.24, 1.0), (0.02, 1.0), (-0.2, 0.6)):
        box("lteal", (w, 0.06, 0.11), (-0.5 + w / 2, -0.06, z), r=0.02)


def coin(loc=(0, 0, 0), s=1.0, glyph="teal"):
    with group(loc, scale=s):
        cyl("yellow", 0.8, 0.24, rot=(90, 0, 0), bevel=0.09)
        ring("yellow", 0.62, 0.05, (0, -0.12, 0))
        slab(glyph, star(0.36, 0.16, 5), 0.08, (0, -0.14, 0), bevel=0.03)


def clock(loc=(0, 0, 0), s=1.0):
    with group(loc, scale=s):
        cyl("teal", 0.92, 0.3, rot=(90, 0, 0), bevel=0.1)
        cyl("white", 0.72, 0.34, rot=(90, 0, 0), bevel=0.03)
        box("dteal", (0.12, 0.08, 0.52), (0, -0.19, 0.22), r=0.04)
        box("dteal", (0.42, 0.08, 0.12), (0.17, -0.19, 0), r=0.04)
        ball("yellow", 0.1, (0, -0.2, 0), scale=(1, 0.6, 1))


def qmark(m, x, y, z, s=1.0):
    tube(m, [(x + s * dx, y, z + s * dz) for dx, dz in
             ((-0.24, 0.22), (-0.14, 0.42), (0.1, 0.44), (0.24, 0.26), (0.06, 0.02), (0, -0.14))], 0.085 * s)
    ball(m, 0.105 * s, (x, y, z - 0.4 * s))


def plus(m, loc, s=1.0, depth=0.14):
    box(m, (0.7 * s, depth, 0.2 * s), loc, r=0.06 * s)
    box(m, (0.2 * s, depth, 0.7 * s), loc, r=0.06 * s)


def cross(m, loc, s=1.0, depth=0.14):
    for a in (45, -45):
        box(m, (0.85 * s, depth, 0.2 * s), loc, r=0.06 * s, rot=(0, a, 0))


def sealed_box(m="teal", size=(1.5, 1.5, 1.0)):
    box(m, size, (0, 0, size[2] / 2), r=0.08)
    box("yellow", (0.3, size[1] + 0.02, size[2] + 0.02), (0, 0, size[2] / 2), r=0.06)


def sponge():
    box("yellow", (1.5, 0.95, 0.5), (0, 0, 0.25), r=0.17)
    box("dteal", (1.5, 0.95, 0.2), (0, 0, 0.55), r=0.08)


def key(m="yellow"):
    slab(m, circ(0.5), 0.22, holes=[circ(0.2)], bevel=0.07)
    box(m, (1.25, 0.2, 0.22), (1.0, 0, 0), r=0.08)
    for x, h in ((1.2, 0.34), (1.5, 0.26)):
        box(m, (0.16, 0.2, h), (x, 0, -h / 2), r=0.05)


def headset(w=1.0, top=1.0, z=0.0, band="dteal"):
    """Headband over a shape of half-width w and height top; cups at height z, mic on the left."""
    tube(band, [(-w, 0, z), (-w * 0.92, 0, z + (top - z) * 0.62), (0, 0, top), (w * 0.92, 0, z + (top - z) * 0.62),
                (w, 0, z)], 0.075)
    for x in (-w, w):
        cyl("yellow", 0.27, 0.22, (x, 0, z - 0.05), rot=(0, 90, 0), bevel=0.07)
    tube(band, [(-w, -0.1, z - 0.2), (-w * 0.85, -0.5, z - 0.5), (-w * 0.45, -0.72, z - 0.52)], 0.045)
    ball("yellow", 0.11, (-w * 0.4, -0.74, z - 0.52))


def floorplan(inner=(), tiles=()):
    """Floor plan for a tilted view: 1.9 square; inner walls and yellow room tiles as ((sx, sy), (x, y))."""
    box("teal", (1.9, 1.9, 0.14), (0, 0, 0), r=0.06)
    for (sx, sy), (x, y) in tiles:
        box("yellow", (sx, sy, 0.05), (x, y, 0.08), r=0.02)
    outer = (((1.9, 0.13), (0, 0.89)), ((1.9, 0.13), (0, -0.89)), ((0.13, 1.9), (0.89, 0)), ((0.13, 1.9), (-0.89, 0)))
    for (sx, sy), (x, y) in (*outer, *inner):
        box("dteal", (sx, sy, 0.36), (x, y, 0.2), r=0.05)


def cloud(m="teal"):
    box(m, (1.7, 0.6, 0.5), (0, 0, 0), r=0.24)
    for x, z, r in ((-0.4, 0.3, 0.42), (0.15, 0.48, 0.55), (0.6, 0.22, 0.34)):
        ball(m, r, (x, 0, z), scale=(1, 0.75, 1))


def arc_arrow(m, big_r, r, a0, a1, y=0.0, c=(0, 0), head=None):
    """Arc (degrees, counter-clockwise, facing the viewer) ending in a cone arrowhead."""
    pts = circ(big_r, c, 8, a0, a1)
    tube(m, [(x, y, z) for x, z in pts], r)
    a = math.radians(a1)
    tx, tz = -math.sin(a), math.cos(a)
    cyl(head or m, r * 2.5, r * 3.6, (pts[-1][0] + tx * r * 1.2, y, pts[-1][1] + tz * r * 1.2),
        rot=(0, math.degrees(math.atan2(tx, tz)), 0), r2=0.02, bevel=r * 0.25)


def wavy(big_r=0.9, amp=0.07, lobes=12):
    out = []
    for a in range(0, 360, 3):
        q = big_r + amp * math.cos(math.radians(a * lobes))
        out.append((q * math.cos(math.radians(a)), q * math.sin(math.radians(a))))
    return out


def shield(m="teal", depth=0.4):
    slab(m, rnd([(-0.85, 0.7), (-0.85, -0.05), (0, -1.0), (0.85, -0.05), (0.85, 0.7), (0, 0.98)], 0.16), depth,
         bevel=0.12)
