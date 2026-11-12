"""Logo and bottom-navigation icons."""
from lib import IDLE, ball, box, rnd, slab
from registry import icon

from .parts import bubble, calendar_base, check, house

NAV = {"idle": {"remap": IDLE, "margin": 0.12}, "active": {"yaw": -28, "tilt": 6, "margin": 0.03}}


def logo():
    house()
    check(s=0.95, loc=(0, -0.38, 0.62), depth=0.22)
    check(s=0.95, loc=(0, 0.38, 0.62), depth=0.22).rotation_euler.rotate_axis("Y", 3.14159265)  # back face, for the turntable


icon("logo_house_check", "Dahae logo: house with a check inside (3D hero)", "brand",
     anim="turntable", gltf=True)(logo)
icon("logo_flat", "Flat front-view logo (app-icon source)", "brand", mode="flat", internal=True)(logo)
icon("logo_mono", "Monochrome logo silhouette, check knocked out", "brand", mode="mono", internal=True)(logo)


@icon("nav_home", "Bottom nav: Home", "nav", variants=NAV)
def nav_home():
    house(d=0.95)
    slab("yellow", rnd([(-0.2, 0), (0.2, 0), (0.2, 0.42), (0, 0.6), (-0.2, 0.42)], 0.16), 0.14, (0, -0.47, 0.06))


@icon("nav_bookings", "Bottom nav: My bookings (calendar with check)", "nav", variants=NAV)
def nav_bookings():
    calendar_base()
    check(s=0.85, loc=(0, -0.2, -0.22), depth=0.16)


@icon("nav_chat", "Bottom nav: Consultation chat", "nav", variants=NAV)
def nav_chat():
    bubble("teal")
    for x in (-0.42, 0, 0.42):
        ball("yellow", 0.13, (x, -0.24, 0), scale=(1, 0.6, 1))


@icon("nav_more", "Bottom nav: More (grid)", "nav", variants=NAV)
def nav_more():
    for x, z, m in ((-0.42, 0.42, "teal"), (0.42, 0.42, "yellow"), (-0.42, -0.42, "teal"), (0.42, -0.42, "teal")):
        box(m, (0.7, 0.45, 0.7), (x, 0, z), r=0.2)
