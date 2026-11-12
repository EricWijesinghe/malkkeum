"""Second batch: ids from the app plan that had no art yet (customer app)."""
import math

from lib import IDLE, ball, box, circ, cyl, group, remap, rnd, rrect, slab, sparkle, tube
from registry import icon

from .parts import (ac_unit, arc_arrow, bubble, calendar_base, ring, shield, wavy, card, check, clipboard, clock, cloud, coin, cross, document, floorplan, headset,
                    house, key, plus, qmark, sealed_box, sponge, ticket, truck, wallet)

PLAN = dict(tilt=40, yaw=-30)

# ---- home / services -------------------------------------------------------------------------------


@icon("svc_move", "Service: move cleaning (house and box)", "service")
def svc_move():
    with group((-0.35, 0.3, 0), scale=0.95):
        house(d=0.8)
    with group((0.6, -0.55, 0), rot=(0, 0, 15), scale=0.52):
        sealed_box("lteal")


@icon("svc_move_in", "Service: move-in cleaning (door and key)", "service")
def svc_move_in():
    box("dteal", (1.25, 0.24, 2.0), (-0.2, 0.1, 1.0), r=0.1)
    slab("teal", rrect(0.95, 1.7, 0.08), 0.12, (-0.2, -0.05, 0.92), bevel=0.04)
    ball("yellow", 0.1, (0.1, -0.14, 0.9))
    with group((0.35, -0.5, 0.45), rot=(0, -35, 0), scale=0.55):
        key()


@icon("rec_move_combo", "Recommended: move-out + move-in combo (two houses and an arrow)", "service")
def rec_move_combo():
    for x, body in ((-0.85, "lteal"), (0.85, "teal")):
        with group((x, 0, 0), scale=0.62):
            house(d=0.8, body=body)
    tube("yellow", [(-0.6, -0.3, 1.25), (0, -0.3, 1.6), (0.55, -0.3, 1.3)], 0.09)
    cyl("yellow", 0.24, 0.36, (0.68, -0.3, 1.18), rot=(0, 130, 0), r2=0.02, bevel=0.03)
    sparkle("yellow", 0.2, (1.3, -0.3, 1.5))


@icon("banner_coupon", "Home banner: welcome coupon (yellow ticket and confetti)", "service")
def banner_coupon():
    with group(rot=(0, -14, 0)):
        ticket("yellow", "teal", "dteal")
    for x, z, m, a in ((-1.05, 0.85, "teal", 30), (0.2, 1.0, "dteal", -20), (1.15, 0.7, "lteal", 50),
                       (-0.9, -0.9, "lteal", -40), (0.9, -0.95, "teal", 15)):
        box(m, (0.26, 0.1, 0.12), (x, 0, z), r=0.045, rot=(0, a, 0))
    sparkle("teal", 0.18, (-0.3, 0, 1.05))
    ball("dteal", 0.08, (1.3, 0, -0.3))
    ball("teal", 0.08, (-1.3, 0, -0.2))


@icon("notice_pin", "Notice (pushpin)", "content")
def notice_pin():
    with group(rot=(0, 28, 0)):
        cyl("yellow", 0.5, 0.2, (0, 0, 0.95), bevel=0.08)
        cyl("teal", 0.24, 0.6, (0, 0, 0.58), bevel=0.04)
        cyl("dteal", 0.62, 0.2, (0, 0, 0.22), bevel=0.08)
        cyl("lteal", 0.015, 0.85, (0, 0, -0.3), r2=0.08, bevel=0.0)


@icon("step_completed", "Timeline: service completed (sparkling house)", "step")
def step_completed():
    house(d=0.9)
    slab("yellow", rnd([(-0.2, 0), (0.2, 0), (0.2, 0.42), (0, 0.6), (-0.2, 0.42)], 0.16), 0.14, (0, -0.45, 0.06))
    sparkle("yellow", 0.34, (1.05, -0.3, 1.5))
    sparkle("yellow", 0.2, (-1.05, -0.3, 1.25))
    sparkle("yellow", 0.15, (1.2, -0.3, 0.75))


@icon("status_cancelled", "Status: cancelled (grey disc with a cross)", "step")
def status_cancelled():
    with remap(IDLE):
        cyl("teal", 0.95, 0.34, rot=(90, 0, 0), bevel=0.12)
    cross("white", (0, -0.2, 0), 1.25, 0.16)


@icon("tool_sponge", "Tool: sponge", "tool", tilt=22, yaw=-28)
def tool_sponge():
    sponge()
    for x, z, r in ((0.75, 1.0, 0.2), (1.0, 0.72, 0.12), (0.45, 1.25, 0.1)):
        ball("lteal", r, (x, 0, z))


# ---- move wizard -----------------------------------------------------------------------------------


@icon("box_unknown", "Move condition: not sure (box with a question mark)", "move", tilt=12, yaw=-25)
def box_unknown():
    box("teal", (1.5, 1.3, 1.3), (0, 0, 0.65), r=0.1)
    qmark("yellow", 0, -0.68, 0.7, 1.15)


@icon("type_normal_move_in", "Cleaning type: normal move-in (key with house tag)", "move")
def type_normal_move_in():
    with group(rot=(0, -35, 0)):
        key()
    tube("dteal", [(-0.3, 0, -0.3), (-0.6, 0, -0.62)], 0.05, smooth=False)
    slab("teal", rnd([(-0.3, 0), (0.3, 0), (0.3, 0.4), (0, 0.68), (-0.3, 0.4)], 0.07), 0.14, (-0.75, 0.0, -1.25))


@icon("type_after_interior", "Cleaning type: after interior work (paint roller)", "move")
def type_after_interior():
    cyl("teal", 0.3, 1.4, (0, 0, 0.8), rot=(0, 90, 0), bevel=0.1)
    cyl("lteal", 0.31, 0.5, (0.25, 0, 0.8), rot=(0, 90, 0), bevel=0.02)
    tube("dteal", [(0.7, 0, 0.8), (0.98, 0, 0.8), (0.98, 0, 0.3), (0, 0, 0.3), (0, 0, -0.1)], 0.06, smooth=False)
    cyl("yellow", 0.13, 0.85, (0, 0, -0.5), bevel=0.06)


@icon("type_lived_in", "Cleaning type: lived-in home (sponge and sparkles)", "move", tilt=22, yaw=-28)
def type_lived_in():
    sponge()
    sparkle("yellow", 0.34, (0.7, -0.3, 1.15))
    sparkle("yellow", 0.18, (0.15, -0.3, 1.3))
    sparkle("lteal", 0.15, (-0.7, -0.3, 1.05))


@icon("type_standard", "Cleaning type: standard (sealed box)", "move", tilt=22, yaw=-30)
def type_standard():
    sealed_box()


@icon("type_same_day", "Cleaning type: same-day move (truck and clock)", "move")
def type_same_day():
    truck()
    clock((-0.75, -0.75, 1.3), 0.5)


@icon("type_some_luggage", "Cleaning type: some belongings left (chair)", "move", tilt=6)
def type_some_luggage():
    box("teal", (1.1, 1.0, 0.24), (0, 0, 0.85), r=0.1)
    box("dteal", (1.1, 0.22, 1.1), (0, 0.4, 1.45), r=0.1)
    box("lteal", (0.9, 0.75, 0.12), (0, -0.07, 1.0), r=0.05)
    for x in (-0.43, 0.43):
        for y in (-0.38, 0.38):
            cyl("yellow", 0.075, 0.8, (x, y, 0.38))


@icon("bld_officetel", "Building type: officetel (glass tower)", "move")
def bld_officetel():
    box("dteal", (1.15, 0.9, 2.4), (0, 0, 1.2), r=0.1)
    for z in (0.75, 1.15, 1.55, 1.95):
        box("lteal", (1.17, 0.92, 0.22), (0, 0, z), r=0.04)
    slab("yellow", rrect(0.36, 0.42, 0.06), 0.08, (0, -0.45, 0.24), bevel=0.03)
    box("teal", (0.5, 0.4, 0.2), (0, 0, 2.45), r=0.06)


@icon("bld_house", "Building type: detached house", "move")
def bld_house():
    box("dteal", (0.26, 0.26, 0.6), (0.48, 0.1, 1.6), r=0.05)
    house(w=1.6, h=0.9, rh=0.75, d=1.0)
    slab("yellow", rrect(0.32, 0.5, 0.08), 0.1, (-0.3, -0.5, 0.26), bevel=0.03)
    slab("white", rrect(0.4, 0.36, 0.07), 0.1, (0.35, -0.5, 0.48), bevel=0.03)


@icon("bld_other", "Building type: other (generic block)", "move")
def bld_other():
    box("teal", (1.6, 1.0, 1.5), (0, 0, 0.75), r=0.1)
    box("dteal", (1.7, 1.1, 0.18), (0, 0, 1.55), r=0.07)
    for x in (-0.42, 0, 0.42):
        ball("white", 0.13, (x, -0.5, 0.8), scale=(1, 0.5, 1))


W = 0.13  # floor-plan wall thickness


@icon("room_studio", "Room structure: studio", "move", **PLAN)
def room_studio():
    floorplan()
    box("white", (0.7, 0.5, 0.2), (-0.4, 0.5, 0.17), r=0.07)
    box("yellow", (0.2, 0.5, 0.22), (-0.66, 0.5, 0.2), r=0.06)


@icon("room_one_half", "Room structure: 1.5 rooms", "move", **PLAN)
def room_one_half():
    floorplan(inner=(((W, 0.9), (0.15, 0.42)),), tiles=(((0.62, 0.8), (0.52, 0.45)),))


@icon("room_two", "Room structure: living room + 2 rooms", "move", **PLAN)
def room_two():
    floorplan(inner=(((1.8, W), (0, 0.05)), ((W, 0.85), (0, 0.48))),
              tiles=(((0.72, 0.7), (-0.45, 0.48)), ((0.72, 0.7), (0.45, 0.48))))


@icon("room_three", "Room structure: living room + 3 rooms", "move", **PLAN)
def room_three():
    floorplan(inner=(((1.8, W), (0, 0.1)), ((W, 0.8), (-0.3, 0.5)), ((W, 0.8), (0.3, 0.5))),
              tiles=tuple(((0.44, 0.62), (x, 0.5)) for x in (-0.58, 0, 0.58)))


@icon("room_four_plus", "Room structure: living room + 4 or more rooms", "move", **PLAN)
def room_four_plus():
    floorplan(inner=(((1.8, W), (0, 0.3)), ((1.8, W), (0, -0.3)), ((W, 0.6), (0, 0.6)), ((W, 0.6), (0, -0.6))),
              tiles=tuple(((0.72, 0.46), (x, y)) for x in (-0.45, 0.45) for y in (-0.6, 0.6)))


@icon("duplex_stairs", "Duplex (interior staircase)", "move", tilt=8, yaw=-30)
def duplex_stairs():
    for i in range(4):
        h = 0.36 * (i + 1)
        box("teal" if i % 2 else "dteal", (0.5, 1.1, h), (-0.75 + i * 0.5, 0, h / 2), r=0.06)
        box("lteal", (0.5, 1.1, 0.08), (-0.75 + i * 0.5, 0, h), r=0.035)
    tube("yellow", [(-0.95, -0.5, 0.95), (0.9, -0.5, 2.05)], 0.06, smooth=False)
    for x, z in ((-0.9, 0.36), (0.85, 1.44)):
        cyl("yellow", 0.045, 0.62, (x, -0.5, z + 0.31))


@icon("promo_ac_addon", "Promo: add AC cleaning at a discount (AC and percent tag)", "move")
def promo_ac_addon():
    ac_unit()
    with group((0.55, -0.4, -0.85), rot=(0, -15, 0)):
        slab("yellow", rnd([(-0.6, 0), (-0.25, 0.42), (0.6, 0.42), (0.6, -0.42), (-0.25, -0.42)], 0.1), 0.16, bevel=0.05)
        box("dteal", (0.09, 0.06, 0.6), (0.2, -0.09, 0), r=0.03, rot=(0, 35, 0))
        ball("dteal", 0.09, (0.02, -0.09, 0.17), scale=(1, 0.5, 1))
        ball("dteal", 0.09, (0.38, -0.09, -0.17), scale=(1, 0.5, 1))
        ball("white", 0.06, (-0.38, -0.09, 0), scale=(1, 0.5, 1))


# ---- schedule / ui -----------------------------------------------------------------------------------


def _sun(loc, r=0.55, rays=range(0, 360, 45)):
    ball("yellow", r, loc)
    for a in rays:
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        box("yellow", (0.3, 0.12, 0.12), (loc[0] + c * r * 1.75, loc[1], loc[2] + s * r * 1.75), r=0.055, rot=(0, -a, 0))


@icon("ui_clock", "Clock (time slot)", "ui")
def ui_clock():
    clock()


@icon("slot_am", "Morning arrival slot (rising sun)", "ui")
def slot_am():
    _sun((0, 0.1, 0.15), 0.62, range(0, 181, 45))
    box("teal", (2.3, 0.6, 0.3), (0, 0, -0.1), r=0.13)
    box("lteal", (1.5, 0.5, 0.16), (0, 0, -0.42), r=0.07)


@icon("slot_pm", "Afternoon arrival slot (sun and cloud)", "ui")
def slot_pm():
    _sun((-0.15, 0.2, 0.3), 0.6)
    with group((0.5, -0.3, -0.55), scale=0.62):
        cloud("teal")


@icon("ui_pin", "Location pin", "ui")
def ui_pin():
    ball("teal", 0.72, (0, 0, 0.5))
    cyl("teal", 0.03, 1.2, (0, 0, -0.45), r2=0.62, bevel=0.02)
    ball("yellow", 0.34, (0, -0.56, 0.5), scale=(1, 0.5, 1))


@icon("ui_bell", "Notifications (bell)", "ui")
def ui_bell():
    ball("yellow", 0.2, (0, 0, -0.42))
    cyl("teal", 0.82, 0.9, (0, 0, 0.3), r2=0.42, bevel=0.1)
    ball("teal", 0.43, (0, 0, 0.72))
    cyl("dteal", 0.95, 0.18, (0, 0, -0.18), bevel=0.08)
    ball("yellow", 0.13, (0, 0, 1.22))


# ---- chat --------------------------------------------------------------------------------------------


@icon("chat_new", "New consultation (bubble with plus)", "chat")
def chat_new():
    bubble("teal")
    plus("yellow", (0, -0.25, 0), 1.15, 0.16)


@icon("chat_team_avatar", "Dahae consultation team avatar (logo house with headset)", "chat", yaw=-14)
def chat_team_avatar():
    house()
    check(s=0.95, loc=(0, -0.38, 0.62), depth=0.22)
    headset(w=0.95, top=1.95, z=0.55)


@icon("chat_quote", "Quote card (document with coin)", "chat")
def chat_quote():
    document()
    coin((0.42, -0.25, -0.5), 0.5, glyph="dteal")


@icon("chat_hours", "Operating hours (clock and moon)", "chat")
def chat_hours():
    clock((-0.2, 0, -0.1), 0.9)
    moon = circ(0.48, (0, 0), 24, 60, 300) + circ(0.42, (0.3, 0), 24, 261.8, 98.2)[1:-1]
    slab("yellow", moon, 0.2, (0.85, -0.2, 0.75), rot=(0, 25, 0), bevel=0.06)


# ---- payments ------------------------------------------------------------------------------------------


@icon("pay_bank", "Payment: bank transfer (bank)", "pay")
def pay_bank():
    box("dteal", (2.0, 0.95, 0.22), (0, 0, 0.11), r=0.08)
    for x in (-0.66, -0.22, 0.22, 0.66):
        cyl("lteal", 0.13, 0.85, (x, -0.2, 0.62), bevel=0.04)
    box("teal", (1.7, 0.5, 0.75), (0, 0.15, 0.6), r=0.05)
    box("dteal", (1.9, 0.9, 0.16), (0, 0, 1.1), r=0.06)
    slab("teal", rnd([(-1.0, 1.16), (1.0, 1.16), (0, 1.85)], 0.08), 0.85, bevel=0.07)
    ball("yellow", 0.15, (0, -0.42, 1.42), scale=(1, 0.5, 1))


@icon("pay_virtual", "Payment: virtual account (receipt)", "pay")
def pay_virtual():
    zig = [(-0.65 + i * 0.1625, -0.95 + (0.12 if i % 2 else 0)) for i in range(9)]
    slab("teal", rnd([*zig, (0.65, 0.95), (-0.65, 0.95)], 0.05), 0.16, bevel=0.04)
    for z, w, m in ((0.6, 0.9, "white"), (0.35, 0.9, "lteal"), (0.1, 0.6, "lteal")):
        box(m, (w, 0.06, 0.12), (-0.45 + w / 2, -0.09, z), r=0.03)
    box("yellow", (0.9, 0.07, 0.2), (0, -0.09, -0.4), r=0.05)


# ---- More menu / states ----------------------------------------------------------------------------------


@icon("menu_scope", "Menu: service scope (checklist)", "menu")
def menu_scope():
    clipboard()
    for z in (0.38, 0.0, -0.38):
        ball("yellow", 0.1, (-0.36, -0.14, z), scale=(1, 0.5, 1))
        box("lteal", (0.55, 0.05, 0.12), (0.12, -0.13, z), r=0.03)


@icon("menu_payments", "Menu: payment methods (card and wallet)", "menu")
def menu_payments():
    with group((-0.3, 0.3, 0.55), rot=(0, 12, 0), scale=0.85):
        card()
    with group((0.3, -0.3, -0.25), scale=0.8):
        wallet(cards=False)


@icon("menu_addresses", "Menu: address management (house and pin)", "menu")
def menu_addresses():
    with group((-0.3, 0.2, 0), scale=0.95):
        house(d=0.8)
    with group((0.75, -0.5, 0.75), scale=0.55):
        ball("yellow", 0.72, (0, 0, 0.5))
        cyl("yellow", 0.03, 1.2, (0, 0, -0.45), r2=0.62, bevel=0.02)
        ball("dteal", 0.3, (0, -0.6, 0.5), scale=(1, 0.5, 1))


@icon("menu_account", "Menu: account info (ID card)", "menu")
def menu_account():
    slab("teal", rrect(1.9, 1.35, 0.18), 0.16, bevel=0.05)
    box("yellow", (0.5, 0.2, 0.16), (0, 0, 0.7), r=0.06)
    slab("lteal", rrect(0.72, 0.85, 0.12), 0.06, (-0.45, -0.08, -0.05), bevel=0.02)
    ball("dteal", 0.17, (-0.45, -0.13, 0.12), scale=(1, 0.4, 1))
    ball("dteal", 0.3, (-0.45, -0.12, -0.38), scale=(1, 0.3, 0.75))
    for z, w in ((0.2, 0.7), (-0.05, 0.7), (-0.3, 0.42)):
        box("white", (w, 0.05, 0.12), (0.12 + w / 2, -0.09, z), r=0.03)


@icon("menu_contact", "Menu: contact us (headset)", "menu")
def menu_contact():
    tube("teal", [(-0.85, 0, 0), (-0.8, 0, 0.62), (0, 0, 1.0), (0.8, 0, 0.62), (0.85, 0, 0)], 0.13)
    for x in (-0.85, 0.85):
        box("dteal", (0.36, 0.6, 0.78), (x, 0, -0.15), r=0.16)
        box("yellow", (0.14, 0.5, 0.6), (x * 1.2, 0, -0.15), r=0.06)
    tube("dteal", [(-0.85, -0.1, -0.5), (-0.7, -0.5, -0.82), (-0.2, -0.7, -0.85)], 0.06)
    ball("yellow", 0.15, (-0.12, -0.72, -0.85))


@icon("menu_version", "Menu: version info (phone with info mark)", "menu")
def menu_version():
    slab("dteal", rrect(1.15, 2.0, 0.22), 0.18, bevel=0.06)
    slab("teal", rrect(0.93, 1.66, 0.12), 0.06, (0, -0.08, 0.04), bevel=0.02)
    ball("white", 0.12, (0, -0.13, 0.42), scale=(1, 0.5, 1))
    box("white", (0.2, 0.08, 0.6), (0, -0.12, -0.1), r=0.08)
    ball("yellow", 0.2, (0.55, -0.1, 0.95))


@icon("empty_inbox", "Empty state: nothing here (open tray)", "state", tilt=26, yaw=-28)
def empty_inbox():
    box("lteal", (1.9, 1.3, 0.14), (0, 0, 0.07), r=0.05)
    for y in (-0.58, 0.58):
        box("teal", (1.95, 0.2, 0.7), (0, y, 0.35), r=0.08)
    for x in (-0.88, 0.88):
        box("teal", (0.2, 1.35, 0.7), (x, 0, 0.35), r=0.08)
    box("yellow", (0.9, 0.12, 0.3), (0, -0.66, 0.4), r=0.07)
    sparkle("lteal", 0.3, (0.3, 0, 1.3))


@icon("error_offline", "Error: offline (cloud with a slash)", "state")
def error_offline():
    cloud("teal")
    box("red", (2.3, 0.16, 0.24), (0.05, -0.42, 0.22), r=0.08, rot=(0, 40, 0))


# ---- More menu, second group ---------------------------------------------------------------------------


@icon("menu_subscriptions", "Menu: subscriptions (calendar with repeat arrows)", "menu")
def menu_subscriptions():
    calendar_base()
    arc_arrow("yellow", 0.34, 0.075, 30, 150, y=-0.2, c=(0, -0.2))
    arc_arrow("yellow", 0.34, 0.075, 210, 330, y=-0.2, c=(0, -0.2))


@icon("menu_partner", "Menu: become a partner (badge with broom)", "menu")
def menu_partner():
    slab("teal", wavy(), 0.28, bevel=0.08)
    slab("dteal", circ(0.66), 0.1, (0, -0.15, 0), bevel=0.03)
    with group((0, -0.24, 0), rot=(0, 30, 0)):
        box("yellow", (0.1, 0.08, 0.75), (0, 0, 0.2), r=0.04)
        box("white", (0.5, 0.1, 0.16), (0, 0, -0.2), r=0.05)
        box("lteal", (0.56, 0.1, 0.24), (0, 0, -0.38), r=0.05)


@icon("menu_language", "Menu: language (globe with speech bubble)", "menu")
def menu_language():
    ball("teal", 0.85, (-0.1, 0, -0.05))
    ring("lteal", 0.86, 0.04, (-0.1, 0, -0.05), plane="xy")
    ring("lteal", 0.86, 0.04, (-0.1, 0, -0.05), plane="yz")
    for z in (-0.47, 0.37):
        ring("lteal", 0.75, 0.035, (-0.1, 0, z), plane="xy")
    with group((0.62, -0.62, 0.62), scale=0.5):
        bubble("yellow", flip=True)
        for x in (-0.42, 0, 0.42):
            ball("dteal", 0.13, (x, -0.24, 0), scale=(1, 0.6, 1))


@icon("menu_theme", "Menu: theme (half sun, half moon)", "menu")
def menu_theme():
    slab("yellow", circ(0.72, (0, 0), 24, 90, 270), 0.34, bevel=0.1)
    slab("dteal", circ(0.72, (0, 0), 24, -90, 90), 0.34, bevel=0.1)
    for a in (110, 150, 180, 210, 250):
        c, s = math.cos(math.radians(a)), math.sin(math.radians(a))
        box("yellow", (0.3, 0.14, 0.13), (c * 1.12, 0, s * 1.12), r=0.06, rot=(0, -a, 0))
    sparkle("lteal", 0.2, (1.1, 0, 0.55))
    sparkle("lteal", 0.13, (1.15, 0, -0.35))
    ball("white", 0.07, (0.3, -0.19, 0.25), scale=(1, 0.5, 1))
    ball("white", 0.05, (0.42, -0.19, -0.2), scale=(1, 0.5, 1))


@icon("menu_privacy", "Menu: privacy (shield with lock)", "menu")
def menu_privacy():
    shield()
    tube("white", [(-0.2, -0.26, 0.12), (-0.2, -0.26, 0.38), (0, -0.26, 0.55), (0.2, -0.26, 0.38), (0.2, -0.26, 0.12)],
         0.065)
    box("yellow", (0.72, 0.2, 0.56), (0, -0.27, -0.15), r=0.12)
    ball("dteal", 0.09, (0, -0.37, -0.12), scale=(1, 0.5, 1))


@icon("menu_terms", "Menu: terms (document with seal)", "menu")
def menu_terms():
    document()
    for k in (-1, 1):
        box("dteal", (0.16, 0.06, 0.45), (0.42 + k * 0.12, -0.12, -0.78), r=0.04, rot=(0, k * -14, 0))
    slab("yellow", wavy(0.34, 0.035, 10), 0.14, (0.42, -0.14, -0.45), bevel=0.04)
    slab("dteal", circ(0.17), 0.06, (0.42, -0.22, -0.45), bevel=0.02)


@icon("menu_licenses", "Menu: open-source licenses (stack of documents)", "menu")
def menu_licenses():
    box("dteal", (1.4, 0.12, 1.8), (0.34, 0.34, 0.24), r=0.12)
    box("lteal", (1.4, 0.12, 1.8), (0.17, 0.17, 0.12), r=0.12)
    document()
