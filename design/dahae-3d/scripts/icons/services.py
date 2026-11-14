"""Service categories, studio scope, tools and air-conditioner types."""
from lib import ball, box, cyl, group, rrect, slab, sparkle, tube
from registry import icon

from .parts import ac_unit, house, ring, truck, wheel

# ---- categories ----------------------------------------------------------------------------


@icon("cat_studio", "Category: studio (one-room) cleaning", "category", tilt=14, yaw=-32)
def cat_studio():
    box("dteal", (1.8, 1.8, 0.16), (0, 0, 0.08), r=0.06)
    box("teal", (1.8, 0.16, 1.35), (0, 0.82, 0.78), r=0.06)
    box("teal", (0.16, 1.8, 1.35), (-0.82, 0, 0.78), r=0.06)
    slab("yellow", rrect(0.62, 0.52, 0.08), 0.1, (0.15, 0.72, 0.9))
    box("white", (0.8, 1.05, 0.3), (0.3, 0.05, 0.31), r=0.1)
    box("lteal", (0.6, 0.3, 0.14), (0.3, 0.38, 0.5), r=0.06)


@icon("cat_move", "Category: move-out cleaning (truck)", "category")
def cat_move():
    truck()


@icon("cat_bathroom", "Category: bathroom cleaning (bathtub)", "category", tilt=8)
def cat_bathroom():
    box("teal", (1.8, 0.95, 0.75), (0, 0, 0.5), r=0.3)
    box("dteal", (1.92, 1.07, 0.16), (0, 0, 0.88), r=0.08)
    for x in (-0.6, 0.6):
        ball("yellow", 0.13, (x, -0.3, 0.1))
        ball("yellow", 0.13, (x, 0.3, 0.1))
    for x, z, r in ((-0.5, 1.05, 0.3), (-0.05, 1.12, 0.36), (0.38, 1.02, 0.26), (-0.28, 1.35, 0.2)):
        ball("white", r, (x, 0, z))
    tube("dteal", [(0.78, 0.1, 0.9), (0.8, 0.1, 1.4), (0.62, 0.1, 1.58), (0.42, 0.1, 1.45)], 0.07)
    ball("lteal", 0.11, (0.15, 0, 1.62))


@icon("cat_kitchen", "Category: kitchen cleaning (cooking pot)", "category", tilt=10)
def cat_kitchen():
    cyl("teal", 0.78, 0.8, (0, 0, 0.42), bevel=0.14)
    for x in (-0.9, 0.9):
        box("dteal", (0.34, 0.26, 0.13), (x, 0, 0.62), r=0.06)
    cyl("dteal", 0.84, 0.13, (0, 0, 0.9), bevel=0.05)
    ball("dteal", 0.7, (0, 0, 0.94), scale=(1, 1, 0.3))
    ball("yellow", 0.15, (0, 0, 1.24))


@icon("cat_mattress", "Category: mattress cleaning", "category", tilt=16, yaw=-28)
def cat_mattress():
    box("teal", (1.9, 1.15, 0.6), (0, 0, 0.3), r=0.18)
    box("white", (1.93, 1.18, 0.09), (0, 0, 0.3), r=0.04)  # side seam
    box("lteal", (1.6, 0.85, 0.1), (0, 0, 0.58), r=0.05)  # quilted top
    for x in (-0.65, 0.65):
        cyl("dteal", 0.09, 0.2, (x, -0.35, -0.06))
    sparkle("yellow", 0.4, (0.75, -0.3, 1.15))
    sparkle("yellow", 0.2, (0.25, -0.3, 1.38))


@icon("cat_ac", "Category: air-conditioner cleaning", "category")
def cat_ac():
    ac_unit()
    for x in (-0.55, 0, 0.55):
        tube("teal", [(x, -0.3, -0.62), (x + 0.1, -0.3, -0.8), (x - 0.1, -0.3, -1.0), (x, -0.3, -1.18)], 0.065)


@icon("cat_sofa", "Category: sofa cleaning", "category", tilt=6)
def cat_sofa():
    box("dteal", (1.7, 0.3, 0.95), (0, 0.32, 0.72), r=0.14)
    box("teal", (1.5, 0.85, 0.36), (0, 0, 0.45), r=0.12)
    for x in (-0.36, 0.36):
        box("lteal", (0.68, 0.7, 0.16), (x, -0.06, 0.68), r=0.07)
    for x in (-0.86, 0.86):
        box("teal", (0.34, 0.95, 0.7), (x, -0.02, 0.55), r=0.15)
        cyl("yellow", 0.06, 0.24, (x * 0.85, -0.3, 0.1))
        cyl("yellow", 0.06, 0.24, (x * 0.85, 0.3, 0.1))


@icon("cat_whole_home", "Category: whole-home cleaning (house with sparkles)", "category", tilt=10)
def cat_whole_home():
    house(d=0.8)
    sparkle("yellow", 0.3, (1.0, -0.4, 1.4))
    sparkle("yellow", 0.18, (-1.0, 0.5, 1.5))


@icon("cat_window", "Category: window cleaning (window with frame and sparkle)", "category", tilt=8)
def cat_window():
    box("dteal", (1.9, 0.2, 0.2), (0, 0, 1.85), r=0.06)
    box("dteal", (1.9, 0.2, 0.2), (0, 0, 0.05), r=0.06)
    box("dteal", (0.2, 0.2, 1.9), (-0.9, 0, 0.95), r=0.06)
    box("dteal", (0.2, 0.2, 1.9), (0.9, 0, 0.95), r=0.06)
    box("teal", (0.14, 0.2, 1.7), (0, 0, 0.95), r=0.04)
    box("teal", (1.7, 0.2, 0.14), (0, 0, 0.95), r=0.04)
    box("lteal", (1.5, 0.08, 1.5), (0, 0.1, 0.95), r=0.04)
    sparkle("yellow", 0.35, (1.2, -0.3, 1.9))
    sparkle("yellow", 0.2, (1.25, -0.3, 1.3))


@icon("cat_disinfection", "Category: pest control and disinfection (spray bottle with droplets)", "category", tilt=6)
def cat_disinfection():
    cyl("teal", 0.4, 1.5, (0, 0, 0.75))
    cyl("dteal", 0.18, 0.3, (0, 0, 1.65))
    box("dteal", (0.5, 0.2, 0.22), (0.2, 0, 1.85), r=0.07)
    ball("lteal", 0.08, (0.7, 0, 1.95))
    ball("lteal", 0.06, (0.95, 0, 1.7))
    ball("yellow", 0.07, (0.8, 0, 2.2))


# ---- studio scope ---------------------------------------------------------------------------


@icon("scope_dusting", "Studio scope: dusting (feather duster)", "scope")
def scope_dusting():
    with group(rot=(0, 35, 0)):
        cyl("yellow", 0.075, 1.1, (0, 0, -0.6))
        cyl("dteal", 0.13, 0.16, (0, 0, -0.02))
        ball("teal", 0.5, (0, 0, 0.62), scale=(0.9, 0.75, 1.3))
        for x, z, r in ((-0.32, 0.4, 0.3), (0.32, 0.4, 0.3), (-0.26, 0.9, 0.28), (0.26, 0.9, 0.28)):
            ball("lteal", r, (x, -0.05, z), scale=(1, 0.8, 1.25))
    sparkle("yellow", 0.22, (-0.55, -0.2, 0.75))


@icon("scope_vacuum", "Studio scope: vacuuming (stick vacuum)", "scope")
def scope_vacuum():
    with group(rot=(0, 22, 0)):
        cyl("dteal", 0.1, 1.5, (0, 0, 0.75))
        cyl("teal", 0.3, 0.7, (0, -0.02, 1.0), bevel=0.1)
        cyl("yellow", 0.25, 0.26, (0, -0.02, 0.5), bevel=0.06)
        box("dteal", (0.22, 0.22, 0.4), (0.1, 0, 1.52), r=0.07, rot=(0, 40, 0))
    box("teal", (1.1, 0.5, 0.24), (0, 0, 0.02), r=0.1)
    box("yellow", (1.02, 0.1, 0.08), (0, -0.2, 0.0), r=0.03)


@icon("scope_dishes", "Studio scope: dishwashing (flat plate stack and sponge)", "scope", tilt=30, yaw=-25)
def scope_dishes():
    for i, m in enumerate(("teal", "lteal", "teal")):
        cyl(m, 0.95, 0.12, (-0.15, 0, i * 0.17), bevel=0.05)
    cyl("lteal", 0.62, 0.05, (-0.15, 0, 0.42), bevel=0.02)
    box("yellow", (0.75, 0.5, 0.3), (0.9, -0.85, 0.05), r=0.1, rot=(0, 0, 20))
    box("dteal", (0.75, 0.5, 0.12), (0.9, -0.85, 0.25), r=0.05, rot=(0, 0, 20))
    for x, y, z, r in ((0.85, 0.3, 0.85, 0.22), (1.15, 0.1, 0.5, 0.14)):
        ball("lteal", r, (x, y, z))


@icon("scope_bathroom", "Studio scope: bathroom cleaning (toilet)", "scope", yaw=-30)
def scope_bathroom():
    box("teal", (0.5, 0.95, 0.9), (-0.62, 0, 1.0), r=0.14)
    ball("yellow", 0.09, (-0.62, 0, 1.46), scale=(1, 1, 0.5))
    cyl("lteal", 0.26, 0.5, (0.02, 0, 0.25), r2=0.4, bevel=0.06)
    ball("lteal", 0.62, (0.12, 0, 0.6), scale=(1.05, 0.82, 0.55))
    ball("teal", 0.62, (0.12, 0, 0.83), scale=(1.07, 0.84, 0.16))


@icon("scope_trash", "Studio scope: trash disposal (bin)", "scope", tilt=6)
def scope_trash():
    cyl("teal", 0.55, 1.25, (0, 0, 0.62), r2=0.72, bevel=0.1)
    for x in (-0.26, 0, 0.26):
        box("white", (0.1, 0.1, 0.6), (x, -0.615 + abs(x) * 0.2, 0.62), r=0.045)
    cyl("dteal", 0.8, 0.15, (0, 0, 1.3), bevel=0.06)
    box("yellow", (0.34, 0.14, 0.12), (0, 0, 1.42), r=0.05)


# ---- tools ---------------------------------------------------------------------------------


@icon("tool_vacuum", "Tool: vacuum cleaner (canister)", "tool")
def tool_vacuum():
    ball("teal", 0.62, (-0.2, 0, 0.62), scale=(1.3, 0.95, 0.9))
    box("yellow", (0.5, 0.2, 0.1), (-0.2, 0, 1.2), r=0.045)
    wheel((-0.5, -0.5, 0.32), 0.32)
    tube("dteal", [(0.5, 0, 0.75), (0.85, 0, 1.3), (1.2, 0, 1.25), (1.35, 0, 0.7), (1.38, 0, 0.2)], 0.09)
    box("dteal", (0.6, 0.45, 0.15), (1.4, 0, 0.08), r=0.06)


@icon("tool_mop", "Tool: mop", "tool")
def tool_mop():
    with group(rot=(0, -20, 0)):
        cyl("yellow", 0.11, 1.2, (0, 0, 0.95))
        cyl("dteal", 0.26, 0.28, (0, 0, 0.32), bevel=0.08)
        for i, dx in enumerate((-0.54, -0.36, -0.18, 0, 0.18, 0.36, 0.54)):
            tube("teal" if i % 2 else "lteal", [(dx * 0.25, 0, 0.25), (dx * 1.25, 0.1 if i % 2 else -0.1, -0.5)], 0.15,
                 smooth=False)


@icon("tool_trash_bags", "Tool: trash bags", "tool")
def tool_trash_bags():
    for x, y, s, m in ((0.62, 0.25, 0.68, "teal"), (-0.15, 0, 1.0, "dteal")):
        with group((x, y, 0), scale=s):
            ball(m, 0.8, (0, 0, 0.7), scale=(1, 0.9, 0.9))
            cyl(m, 0.3, 0.4, (0, 0, 1.42), r2=0.1, bevel=0.03)
            ring("yellow", 0.13, 0.055, (0, 0, 1.56), plane="xy")
            for k in (-1, 1):
                ball(m, 0.2, (k * 0.16, 0, 1.76), scale=(0.9, 0.5, 1.1), rot=(0, k * 30, 0))


@icon("tool_rubber_gloves", "Tool: rubber gloves", "tool")
def tool_rubber_gloves():
    box("yellow", (0.86, 0.38, 0.8), (0, 0, 0.55), r=0.17)
    for x, h in ((-0.32, 0.55), (-0.107, 0.68), (0.107, 0.64), (0.32, 0.5)):
        box("yellow", (0.19, 0.32, h), (x, 0, 0.9 + h / 2), r=0.09)
    box("yellow", (0.22, 0.32, 0.56), (0.56, 0, 0.62), r=0.1, rot=(0, 38, 0))
    box("teal", (0.92, 0.44, 0.42), (0, 0, 0.02), r=0.1)
    box("white", (0.94, 0.46, 0.1), (0, 0, 0.02), r=0.04)


@icon("tool_detergent", "Tool: detergent (spray bottle)", "tool")
def tool_detergent():
    box("teal", (0.95, 0.55, 1.1), (0, 0, 0.55), r=0.2)
    slab("yellow", rrect(0.55, 0.5, 0.12), 0.08, (0, -0.27, 0.5))
    cyl("dteal", 0.17, 0.3, (0.05, 0, 1.2))
    box("dteal", (0.75, 0.32, 0.28), (-0.1, 0, 1.47), r=0.1)
    cyl("white", 0.08, 0.14, (-0.52, 0, 1.47), rot=(0, 90, 0), bevel=0.02)
    box("dteal", (0.12, 0.22, 0.42), (-0.28, 0, 1.15), r=0.05, rot=(0, -20, 0))
    for x, z, r in ((-0.8, 1.62, 0.07), (-0.86, 1.42, 0.09), (-0.78, 1.22, 0.06)):
        ball("lteal", r, (x, 0, z))


@icon("tool_cloth", "Tool: cleaning cloth (folded)", "tool", tilt=30, yaw=-30)
def tool_cloth():
    box("teal", (1.4, 1.15, 0.24), (0, 0, 0), r=0.11)
    box("white", (1.3, 1.05, 0.22), (0.02, 0, 0.22), r=0.1)
    box("teal", (1.2, 0.95, 0.22), (0.04, 0, 0.44), r=0.1)
    box("yellow", (1.22, 0.18, 0.23), (0.04, -0.2, 0.44), r=0.06)


# ---- air-conditioner types -------------------------------------------------------------------


@icon("ac_wall", "AC type: wall-mounted", "ac")
def ac_wall():
    ac_unit()
    for x in (-0.55, 0, 0.55):
        tube("yellow", [(x, -0.3, -0.62), (x + 0.09, -0.3, -0.78), (x - 0.09, -0.3, -0.96), (x, -0.3, -1.1)], 0.07)


def _stand():
    box("teal", (0.99, 0.3, 2.12), (0, 0.22, 1.06), r=0.14)  # frame
    box("lteal", (0.85, 0.62, 2.0), (0, 0, 1.05), r=0.18)
    box("teal", (0.58, 0.1, 0.42), (0, -0.28, 1.6), r=0.05)
    ball("yellow", 0.07, (0, -0.31, 1.2))
    box("dteal", (0.58, 0.1, 0.34), (0, -0.28, 0.42), r=0.05)
    box("dteal", (0.98, 0.72, 0.16), (0, 0, 0.08), r=0.07)


@icon("ac_stand", "AC type: floor-standing", "ac")
def ac_stand():
    _stand()
    for z in (1.75, 1.5):
        tube("yellow", [(-0.6, -0.3, z), (-0.78, -0.3, z - 0.09), (-0.96, -0.3, z + 0.09), (-1.12, -0.3, z)], 0.07)


@icon("ac_2in1", "AC type: 2-in-1 (stand + wall unit)", "ac")
def ac_2in1():
    with group((0.8, 0, 0)):
        _stand()
    with group((-0.75, 0, 1.6), scale=0.78):
        ac_unit()
    for x in (-1.1, -0.4):
        tube("yellow", [(x, -0.25, 1.1), (x + 0.07, -0.25, 0.97), (x - 0.07, -0.25, 0.83), (x, -0.25, 0.7)], 0.06)


@icon("ac_ceiling", "AC type: ceiling cassette (seen from below)", "ac", tilt=-48, yaw=-32)
def ac_ceiling():
    box("teal", (2.05, 2.05, 0.24), (0, 0, 0.14), r=0.1)  # ceiling-side frame
    box("lteal", (1.8, 1.8, 0.3), (0, 0, 0), r=0.12)
    box("teal", (0.7, 0.7, 0.1), (0, 0, -0.14), r=0.06)
    for x, y, sx, sy in ((0, 0.62, 1.0, 0.22), (0, -0.62, 1.0, 0.22), (0.62, 0, 0.22, 1.0), (-0.62, 0, 0.22, 1.0)):
        box("dteal", (sx, sy, 0.08), (x, y, -0.15), r=0.06)
    ball("yellow", 0.11, (0.72, -0.72, -0.15))
    for k in (-1, 1):
        tube("yellow", [(k * 0.45, -0.98, -0.3), (k * 0.58, -1.08, -0.55), (k * 0.4, -1.14, -0.82)], 0.09)