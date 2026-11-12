"""Move-cleaning wizard (boxes, buildings, elevator, counters) and booking timeline steps."""
import math

from lib import IDLE, ball, box, circ, cyl, group, remap, rnd, roof_pts, rrect, slab, star, tube
from registry import icon

from .parts import bubble, check, elevator, open_box, person

# ---- packing condition ---------------------------------------------------------------------------


@icon("box_empty", "Move condition: empty (open empty box)", "move", tilt=22, yaw=-30)
def box_empty():
    open_box()


@icon("box_partial", "Move condition: partially packed (open box with items)", "move", tilt=22, yaw=-30)
def box_partial():
    open_box()
    ball("yellow", 0.36, (-0.25, -0.1, 0.9))
    box("white", (0.45, 0.45, 0.8), (0.3, 0.15, 0.85), r=0.08, rot=(0, 12, 20))


@icon("box_full", "Move condition: fully packed (sealed boxes)", "move", tilt=22, yaw=-30)
def box_full():
    box("teal", (1.5, 1.5, 1.0), (0, 0, 0.5), r=0.08)
    box("yellow", (0.3, 1.52, 1.02), (0, 0, 0.5), r=0.06)
    with group((0.1, 0.1, 1.0), rot=(0, 0, 25)):
        box("dteal", (0.85, 0.85, 0.6), (0, 0, 0.3), r=0.07)
        box("yellow", (0.2, 0.87, 0.62), (0, 0, 0.3), r=0.05)


# ---- building types ------------------------------------------------------------------------------


def _windows(m, xs, zs, y, size=(0.22, 0.06, 0.22), lit=()):
    for i, z in enumerate(zs):
        for j, x in enumerate(xs):
            box("yellow" if (i, j) in lit else m, size, (x, y, z), r=0.03)


@icon("bld_apartment", "Building type: apartment", "move")
def bld_apartment():
    box("dteal", (0.8, 0.65, 1.5), (0.55, 0.12, 0.75), r=0.08)
    _windows("lteal", (0.42, 0.72), (0.5, 0.85, 1.2), -0.21)
    box("teal", (0.95, 0.75, 2.1), (-0.3, 0, 1.05), r=0.08)
    _windows("white", (-0.5, -0.1), (0.55, 0.95, 1.35, 1.75), -0.375, lit={(1, 1), (2, 0), (3, 1)})


@icon("bld_villa", "Building type: villa (low-rise multi-family)", "move")
def bld_villa():
    box("teal", (1.7, 1.0, 1.15), (0, 0, 0.575), r=0.08)
    slab("teal", rnd([(-0.85, 1.05), (0.85, 1.05), (0, 1.6)], 0.05), 0.98, bevel=0.06)
    slab("dteal", roof_pts(1.7, 1.1, 0.55, t=0.2, over=0.22), 1.16, bevel=0.07)
    _windows("white", (-0.5, 0, 0.5), (0.82,), -0.5, size=(0.28, 0.06, 0.26), lit={(0, 1)})
    _windows("white", (-0.5, 0.5), (0.32,), -0.5, size=(0.28, 0.06, 0.26))
    slab("yellow", rrect(0.3, 0.46, 0.08), 0.08, (0, -0.5, 0.25), bevel=0.03)


@icon("bld_commercial", "Building type: commercial (shop)", "move")
def bld_commercial():
    box("teal", (1.75, 1.0, 1.35), (0, 0, 0.675), r=0.08)
    box("dteal", (1.85, 1.1, 0.18), (0, 0, 1.4), r=0.07)
    for i in range(5):
        box("white" if i % 2 else "yellow", (0.35, 0.45, 0.1), (-0.7 + i * 0.35, -0.62, 0.95), r=0.04, rot=(-28, 0, 0))
    slab("lteal", rrect(0.8, 0.48, 0.07), 0.08, (-0.33, -0.5, 0.42), bevel=0.03)
    slab("dteal", rrect(0.38, 0.62, 0.07), 0.08, (0.5, -0.5, 0.35), bevel=0.03)


# ---- elevator / counters -------------------------------------------------------------------------


@icon("elevator_yes", "Elevator available", "move")
def elevator_yes():
    elevator()


@icon("elevator_no", "No elevator (teal frame, greyed doors, red strike)", "move")
def elevator_no():
    with remap({"lteal": IDLE["lteal"], "white": IDLE["teal"]}):
        elevator(arrows="white")
    box("red", (2.3, 0.16, 0.26), (0, -0.42, 0.9), r=0.08, rot=(0, 45, 0))


@icon("bath_count", "Counter: bathrooms (shower)", "move")
def bath_count():
    box("dteal", (0.3, 0.14, 0.3), (-0.6, 0.05, -0.85), r=0.06)
    tube("dteal", [(-0.6, 0, -0.85), (-0.6, 0, 0.55), (-0.38, 0, 0.95), (0.05, 0, 0.98)], 0.075)
    with group((0.25, 0, 0.82), rot=(0, 25, 0)):
        cyl("teal", 0.58, 0.34, r2=0.18, bevel=0.08)
        cyl("yellow", 0.5, 0.06, (0, 0, -0.17), bevel=0.02)
    for x, z in ((0.0, 0.1), (0.3, -0.05), (0.62, 0.15), (0.12, -0.5), (0.48, -0.6), (0.82, -0.35)):
        ball("teal", 0.085, (x + 0.1, 0, z), scale=(1, 1, 1.5))


@icon("balcony_count", "Counter: balconies", "move", tilt=8)
def balcony_count():
    box("teal", (1.8, 0.14, 1.8), (0, 0.42, 0.9), r=0.06)
    slab("lteal", rrect(0.8, 1.2, 0.08), 0.08, (0, 0.34, 0.86), bevel=0.03)
    box("dteal", (0.05, 0.1, 1.2), (0, 0.33, 0.86), r=0.02)
    box("dteal", (2.0, 0.85, 0.16), (0, -0.02, 0.1), r=0.07)
    box("white", (2.0, 0.12, 0.12), (0, -0.4, 0.85), r=0.05)
    for i in range(6):
        box("white", (0.09, 0.09, 0.7), (-0.9 + i * 0.36, -0.4, 0.5), r=0.04)


# ---- booking timeline ----------------------------------------------------------------------------


@icon("step_consult", "Timeline: consultation requested", "step")
def step_consult():
    bubble("teal", 1.5, 1.05, 0.4, (-0.2, 0.15, 0.35))
    for x in (-0.55, -0.2, 0.15):
        ball("white", 0.11, (x, -0.07, 0.35), scale=(1, 0.6, 1))
    bubble("yellow", 1.05, 0.72, 0.36, (0.5, -0.2, -0.42), flip=True)


@icon("step_confirmed", "Timeline: booking confirmed (clipboard)", "step")
def step_confirmed():
    box("teal", (1.35, 0.18, 1.75), (0, 0, 0), r=0.08)
    slab("white", rrect(1.08, 1.4, 0.08), 0.06, (0, -0.1, -0.06), bevel=0.02)
    box("dteal", (0.62, 0.26, 0.26), (0, -0.02, 0.86), r=0.09)
    for z, w in ((0.36, 0.8), (0.12, 0.8), (-0.12, 0.45)):
        box("lteal", (w, 0.05, 0.1), (-0.4 + w / 2, -0.13, z), r=0.02)
    cyl("dteal", 0.42, 0.14, (0.42, -0.2, -0.55), rot=(90, 0, 0))
    check(s=0.55, loc=(0.42, -0.29, -0.55), depth=0.1)


@icon("step_matched", "Timeline: cleaner matched (two figures with a check badge)", "step")
def step_matched():
    person("teal", "teal", (-0.45, 0.2, 0))
    person("lteal", "lteal", (0.45, -0.1, 0), s=0.92)
    cyl("yellow", 0.4, 0.14, (0.05, -0.62, 0.3), rot=(90, 0, 0))
    check("dteal", 0.5, (0.05, -0.71, 0.3), depth=0.1)


@icon("step_done", "Timeline: service completed (rosette)", "step")
def step_done():
    for k in (-1, 1):
        slab("dteal", rnd([(k * 0.55, -0.3), (k * 0.05, -0.5), (k * 0.22, -1.45), (k * 0.45, -1.2), (k * 0.75, -1.35)],
                          0.05)[::k], 0.12, (0, 0.1, 0))
    wavy = [((0.9 + 0.07 * math.cos(math.radians(a * 12))) * math.cos(math.radians(a)),
             (0.9 + 0.07 * math.cos(math.radians(a * 12))) * math.sin(math.radians(a))) for a in range(0, 360, 3)]
    slab("teal", wavy, 0.28, bevel=0.08)
    slab("dteal", circ(0.64), 0.1, (0, -0.15, 0), bevel=0.03)
    slab("yellow", star(0.5, 0.23, 5), 0.12, (0, -0.2, 0), bevel=0.04)
