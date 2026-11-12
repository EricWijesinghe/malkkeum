"""Wallet, More-menu, content and confirmation icons."""
from lib import ball, box, circ, cyl, group, heart, house_pts, rnd, rrect, slab, sparkle, star, tube
from registry import icon

from .parts import bubble, calendar_base, card, check, floorplan, person, pin, ring, ticket, wallet


@icon("coupon", "Coupon ticket", "misc")
def coupon():
    with group(rot=(0, -12, 0)):
        ticket()


@icon("points", "Points (coins)", "misc")
def points():
    cyl("teal", 0.72, 0.22, (0.42, 0.3, -0.18), rot=(90, 0, 0), bevel=0.08)
    cyl("yellow", 0.8, 0.24, (-0.15, 0, 0.1), rot=(90, 0, 0), bevel=0.09)
    ring("yellow", 0.62, 0.05, (-0.15, -0.12, 0.1))
    slab("teal", star(0.36, 0.16, 5), 0.08, (-0.15, -0.14, 0.1), bevel=0.03)


@icon("calendar", "Calendar (date picker)", "misc")
def calendar():
    calendar_base()
    for i, z in enumerate((0.1, -0.22, -0.54)):
        for j, x in enumerate((-0.5, -0.17, 0.17, 0.5)):
            box("yellow" if (i, j) == (1, 2) else "white", (0.2, 0.08, 0.2), (x, -0.17, z), r=0.05)


@icon("news", "Dahae news (newspaper)", "misc")
def news():
    box("teal", (1.58, 0.14, 1.88), (0, 0.1, 0), r=0.14)
    box("white", (1.4, 0.14, 1.7), (0, 0, 0), r=0.1)
    box("dteal", (1.12, 0.08, 0.3), (0, -0.06, 0.55), r=0.03)
    box("yellow", (0.5, 0.08, 0.5), (-0.31, -0.06, 0.02), r=0.04)
    for z in (0.2, 0.02, -0.16):
        box("teal", (0.5, 0.06, 0.1), (0.31, -0.06, z), r=0.02)
    for z in (-0.45, -0.63):
        box("lteal", (1.12, 0.06, 0.1), (0, -0.06, z), r=0.02)


@icon("tip_bulb", "Cleaning tip (light bulb)", "misc")
def tip_bulb():
    ball("yellow", 0.72, (0, 0, 0.55))
    cyl("yellow", 0.36, 0.5, (0, 0, -0.15), r2=0.5, bevel=0.03)
    ball("white", 0.16, (-0.3, -0.52, 0.85), scale=(1, 0.4, 1.3), rot=(0, 30, 0))
    cyl("dteal", 0.37, 0.16, (0, 0, -0.44), bevel=0.06)
    cyl("teal", 0.37, 0.16, (0, 0, -0.6), bevel=0.06)
    cyl("dteal", 0.22, 0.14, (0, 0, -0.74), bevel=0.05)
    for x, z, a in ((0, 1.62, 0), (-0.95, 1.25, -50), (0.95, 1.25, 50)):
        box("teal", (0.1, 0.1, 0.3), (x, 0, z), r=0.045, rot=(0, a, 0))


@icon("consult_team_avatar", "Consultation team avatar (abstract mascot with headset)", "misc", yaw=-14)
def consult_team_avatar():
    ball("teal", 0.85, (0, 0, 0), scale=(1, 0.92, 0.94))
    for x in (-0.3, 0.3):
        ball("ink", 0.1, (x, -0.74, 0.12), scale=(1, 0.5, 1.25))
        ball("white", 0.035, (x + 0.03, -0.79, 0.17))
        ball("yellow", 0.13, (x * 1.75, -0.66, -0.12), scale=(1, 0.3, 0.7))
    tube("white", [(-0.2, -0.76, -0.2), (0, -0.79, -0.3), (0.2, -0.76, -0.2)], 0.045)
    tube("dteal", [(-0.88, 0, 0.1), (-0.7, 0, 0.68), (0, 0, 0.95), (0.7, 0, 0.68), (0.88, 0, 0.1)], 0.07)
    for x in (-0.88, 0.88):
        cyl("yellow", 0.27, 0.2, (x, 0, 0.02), rot=(0, 90, 0), bevel=0.07)
    tube("dteal", [(-0.9, -0.1, -0.1), (-0.8, -0.55, -0.5), (-0.4, -0.82, -0.52)], 0.04)
    ball("yellow", 0.1, (-0.36, -0.84, -0.52))


@icon("confirm_check_big", "Booking confirmed: big animated check badge", "misc", anim="pop", gltf=True)
def confirm_check_big():
    cyl("teal", 0.95, 0.34, rot=(90, 0, 0), bevel=0.12)
    ring("lteal", 0.74, 0.03, (0, -0.17, 0))
    check(s=1.25, loc=(0.04, -0.26, 0), depth=0.26)
    sparkle("yellow", 0.2, (0.95, -0.1, 0.85))
    sparkle("yellow", 0.13, (-0.98, -0.1, -0.6))


@icon("wallet_card", "Payment: card", "misc", tilt=10)
def wallet_card():
    with group(rot=(0, -10, 0)):
        card()


@icon("wallet_generic", "Payment: generic wallet (other methods)", "misc")
def wallet_generic():
    wallet()


@icon("address_home", "Saved address: my home (pin with house)", "misc")
def address_home():
    pin(lambda y: slab("yellow", [(x, z - 0.26) for x, z in house_pts(0.5, 0.28, 0.26, 0.05)], 0.08, (0, y, 0.5),
                       bevel=0.03))


@icon("address_family", "Saved address: family home (pin with heart)", "misc")
def address_family():
    pin(lambda y: slab("yellow", heart(0.3), 0.08, (0, y, 0.52), bevel=0.03))


@icon("account", "Account info (person)", "misc")
def account():
    person("teal", "dteal")
    ball("yellow", 0.12, (0.3, -0.52, 0.42), scale=(1, 0.5, 1))


@icon("announcement", "Announcements (megaphone)", "misc")
def announcement():
    with group(rot=(0, -18, 0)):
        cyl("teal", 0.26, 1.25, (0, 0, 0), rot=(0, 90, 0), r2=0.78, bevel=0.04)
        ring("yellow", 0.78, 0.075, (0.62, 0, 0), plane="yz")
        cyl("dteal", 0.7, 0.05, (0.6, 0, 0), rot=(0, 90, 0), bevel=0.01)
        cyl("dteal", 0.3, 0.36, (-0.75, 0, 0), rot=(0, 90, 0), bevel=0.08)
        box("dteal", (0.22, 0.22, 0.6), (-0.4, 0, -0.5), r=0.09, rot=(0, 12, 0))


@icon("faq", "FAQ (bubble with question mark)", "misc")
def faq():
    bubble("teal")
    y = -0.27
    tube("yellow", [(-0.24, y, 0.22), (-0.14, y, 0.42), (0.1, y, 0.44), (0.24, y, 0.26), (0.06, y, 0.02), (0, y, -0.14)],
         0.085)
    ball("yellow", 0.105, (0, y, -0.4))


@icon("contact", "Contact us (phone handset)", "misc")
def contact():
    with group(rot=(0, -40, 0)):
        tube("teal", [(-0.78, 0, 0.1), (-0.62, 0, -0.3), (0, 0, -0.52), (0.62, 0, -0.3), (0.78, 0, 0.1)], 0.3)
        for x in (-0.8, 0.8):
            box("dteal", (0.72, 0.66, 0.6), (x, 0, 0.28), r=0.26)
    for r in (0.3, 0.55):
        tube("yellow", [(0.55 + r * 0.38, -0.05, 0.75 + r * 0.92), (0.55 + r * 0.72, -0.05, 0.75 + r * 0.72),
                        (0.55 + r * 0.92, -0.05, 0.75 + r * 0.38)], 0.085)


@icon("version", "Version info (info badge)", "misc")
def version():
    slab("dteal", rrect(1.7, 1.7, 0.45), 0.4, bevel=0.12)
    ball("white", 0.15, (0, -0.2, 0.45), scale=(1, 0.6, 1))
    box("white", (0.26, 0.14, 0.72), (0, -0.2, -0.18), r=0.1)
    ball("yellow", 0.24, (0.78, -0.12, 0.78))


@icon("service_scope", "Service scope (floor plan with marker)", "misc", tilt=40, yaw=-30)
def service_scope():
    floorplan(inner=(((0.13, 1.0), (0.0, 0.42)),), tiles=(((0.82, 0.82), (0.45, 0.45)),))
    ball("yellow", 0.3, (-0.4, -0.3, 1.0))
    cyl("yellow", 0.03, 0.6, (-0.4, -0.3, 0.52), r2=0.24, bevel=0.01)