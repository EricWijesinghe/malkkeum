"""App icon ids (DAHAE-PLAN section 4) -> render name. Ids that share art are aliases: no second render.

An id not listed here is not exported to the app. Value = render name under out/_raw/<name>__small.png.
"""
SAME = """
svc_move svc_move_in rec_move_combo banner_coupon tip_bulb notice_pin
step_consult step_confirmed step_matched step_completed status_cancelled
scope_dusting scope_vacuum scope_dishes scope_bathroom scope_trash
tool_vacuum tool_mop tool_cloth tool_sponge
ac_wall ac_stand ac_ceiling
box_empty box_partial box_full box_unknown
type_normal_move_in type_after_interior type_lived_in type_standard type_same_day type_some_luggage
bld_apartment bld_villa bld_commercial bld_officetel bld_house bld_other
room_studio room_one_half room_two room_three room_four_plus duplex_stairs
ui_clock slot_am slot_pm ui_pin ui_bell promo_ac_addon
chat_new chat_team_avatar chat_quote chat_hours pay_bank pay_virtual
menu_scope menu_payments menu_addresses menu_account menu_contact menu_version
menu_subscriptions menu_partner menu_language menu_theme menu_privacy menu_terms menu_licenses
empty_inbox error_offline
p_nav_jobs p_camera p_verified p_payout
c_dashboard c_pricing c_subscriptions c_customers c_partners c_staff c_settings c_monitor
""".split()

ALIASES = {
    # nav: one colour asset each; the app greys the inactive state at runtime
    "nav_home": "nav_home_active", "nav_bookings": "nav_bookings_active",
    "nav_chat": "nav_chat_active", "nav_more": "nav_more_active",
    "svc_studio": "cat_studio", "svc_move_out": "cat_move", "svc_bathroom": "cat_bathroom",
    "svc_kitchen": "cat_kitchen", "svc_mattress": "cat_mattress", "svc_aircon": "cat_ac", "svc_sofa": "cat_sofa",
    "svc_whole_home": "cat_whole_home", "svc_window": "cat_window", "svc_disinfection": "cat_disinfection",
    "news_megaphone": "announcement", "faq_bubble": "faq",
    "tool_trash": "tool_trash_bags", "tool_gloves": "tool_rubber_gloves", "tool_spray": "tool_detergent",
    "ac_two_in_one": "ac_2in1",
    "cnt_bathroom": "bath_count", "cnt_balcony": "balcony_count",
    "elev_yes": "elevator_yes", "elev_no": "elevator_no",
    "ui_calendar": "calendar", "ui_coupon": "coupon", "ui_points": "points",
    "pay_card": "wallet_card", "pay_wallet": "wallet_generic",
    "menu_notices": "announcement", "menu_tips": "tip_bulb", "menu_faq": "faq", "menu_coupons": "coupon",
    "confirm_check": "confirm_check_big", "logo_3d": "logo_house_check",
    "p_nav_quotes": "chat_quote", "p_nav_schedule": "calendar",
    "c_bookings": "nav_bookings_active", "c_quotes": "chat_quote", "c_chat": "nav_chat_active",
    "c_marketing": "announcement", "c_payments": "wallet_card", "c_payouts": "p_payout",
}

EXPORT = {**{i: i for i in SAME}, **ALIASES}
LARGE = ("confirm_check", "logo_3d", "banner_coupon")  # also exported at 160 dp
