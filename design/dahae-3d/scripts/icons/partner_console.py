"""Partner app (p_*) and console rail (c_*) icons. Console ones are used at 24 dp: bold shapes only."""
import math

from lib import ball, box, circ, cyl, group, rnd, rrect, slab, star, tube
from registry import icon

from .parts import arc_arrow, check, clipboard, coin, person, shield, wallet

# ---- partner -----------------------------------------------------------------------------------------


@icon("p_nav_jobs", "Partner nav: jobs (clipboard and broom)", "partner")
def p_nav_jobs():
    with group((-0.25, 0.15, 0.1)):
        clipboard()
        for z, w in ((0.36, 0.8), (0.08, 0.8), (-0.2, 0.5)):
            box("lteal", (w, 0.05, 0.12), (-0.4 + w / 2, -0.13, z), r=0.03)
    with group((0.6, -0.35, -0.85), rot=(0, 22, 0)):
        cyl("yellow", 0.07, 1.5, (0, 0, 1.0))
        box("dteal", (0.7, 0.26, 0.2), (0, 0, 0.26), r=0.08)
        box("lteal", (0.66, 0.2, 0.34), (0, 0, 0.0), r=0.06)


@icon("p_camera", "Partner: completion photos (camera)", "partner")
def p_camera():
    box("dteal", (0.6, 0.5, 0.24), (-0.35, 0, 0.62), r=0.08)
    box("teal", (1.9, 0.7, 1.15), (0, 0, 0), r=0.2)
    cyl("dteal", 0.46, 0.3, (0.1, -0.38, -0.02), rot=(90, 0, 0), bevel=0.08)
    cyl("lteal", 0.3, 0.34, (0.1, -0.38, -0.02), rot=(90, 0, 0), bevel=0.05)
    ball("white", 0.08, (0.0, -0.56, 0.08))
    box("yellow", (0.3, 0.1, 0.18), (-0.65, -0.33, 0.32), r=0.06)


@icon("p_verified", "Partner: verified (shield with check)", "partner")
def p_verified():
    shield()
    check(s=1.0, loc=(0, -0.26, 0.05), depth=0.18)


@icon("p_payout", "Partner: payouts (wallet and coins)", "partner")
def p_payout():
    wallet(cards=False)
    coin((0.55, -0.45, -0.6), 0.42)
    coin((0.95, -0.3, -0.35), 0.36)


# ---- console rail --------------------------------------------------------------------------------------


@icon("c_dashboard", "Console: dashboard (bar chart)", "console")
def c_dashboard():
    slab("teal", rrect(1.9, 1.8, 0.3), 0.3, bevel=0.1)
    for x, h, m in ((-0.5, 0.5, "lteal"), (0, 0.85, "white"), (0.5, 1.2, "yellow")):
        box(m, (0.34, 0.2, h), (x, -0.2, -0.62 + h / 2), r=0.08)


@icon("c_pricing", "Console: pricing (price tag)", "console")
def c_pricing():
    with group(rot=(0, -30, 0)):
        slab("teal", rnd([(-1.0, 0), (-0.4, 0.62), (0.95, 0.62), (0.95, -0.62), (-0.4, -0.62)], 0.14), 0.3,
             holes=[circ(0.16, (-0.52, 0))], bevel=0.09)
        tube("yellow", [(-0.52 + 0.3 * math.cos(a), 0.0, 0.3 * math.sin(a) + 0.28) for a in
                        (math.radians(d) for d in range(0, 360, 45))], 0.055, cyclic=True)
        for z, w in ((0.2, 0.8), (-0.15, 0.5)):
            box("white", (w, 0.08, 0.16), (-0.05 + w / 2, -0.15, z), r=0.05)


@icon("c_subscriptions", "Console: subscriptions (two-arrow repeat cycle)", "console")
def c_subscriptions():
    arc_arrow("teal", 0.75, 0.16, 25, 150)
    arc_arrow("dteal", 0.75, 0.16, 205, 330)
    ball("yellow", 0.24, (0, 0, 0))


@icon("c_customers", "Console: customers (two people)", "console")
def c_customers():
    person("lteal", "lteal", (0.5, 0.3, 0.1), s=0.85)
    person("teal", "teal", (-0.25, -0.1, 0))


@icon("c_partners", "Console: partners (person with star badge)", "console")
def c_partners():
    person("teal", "dteal")
    slab("yellow", star(0.38, 0.17, 5), 0.14, (0.5, -0.55, 0.3), bevel=0.05)


@icon("c_staff", "Console: staff (person with ID lanyard)", "console")
def c_staff():
    person("dteal", "teal")
    tube("yellow", [(-0.3, -0.42, 0.72), (0, -0.56, 0.42), (0.3, -0.42, 0.72)], 0.045)
    slab("white", rrect(0.34, 0.3, 0.06), 0.08, (0, -0.6, 0.26), bevel=0.03)


@icon("c_settings", "Console: settings (gear)", "console")
def c_settings():
    n, pts = 8, []
    for i in range(n * 4):
        a = math.radians((i - 0.5) * 360 / (n * 4))
        r = 0.95 if i % 4 < 2 else 0.7
        pts.append((r * math.cos(a), r * math.sin(a)))
    slab("teal", rnd(pts, 0.07), 0.36, holes=[circ(0.3)], bevel=0.1)
    ring_r = 0.3
    tube("yellow", [(ring_r * math.cos(math.radians(d)), -0.02, ring_r * math.sin(math.radians(d)))
                    for d in range(0, 360, 45)], 0.07, cyclic=True)


@icon("c_monitor", "Console: monitoring (screen with pulse)", "console")
def c_monitor():
    box("dteal", (0.3, 0.3, 0.45), (0, 0.05, -0.75), r=0.08)
    box("dteal", (1.0, 0.5, 0.14), (0, 0, -0.98), r=0.06)
    box("teal", (2.0, 0.24, 1.35), (0, 0, 0.05), r=0.14)
    slab("dteal", rrect(1.72, 1.07, 0.08), 0.06, (0, -0.12, 0.05), bevel=0.02)
    tube("yellow", [(-0.7, -0.17, 0.0), (-0.35, -0.17, 0.0), (-0.15, -0.17, 0.35), (0.1, -0.17, -0.3),
                    (0.3, -0.17, 0.05), (0.7, -0.17, 0.05)], 0.055, smooth=False)
