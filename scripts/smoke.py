"""End-to-end smoke test against a running dev API (DEV_MODE=1).

Covers the spec's milestone acceptance paths: sign-up + welcome coupons, studio
rule, fixed/unit booking with coupon + payment, coupon single use, first-come
accept race, completion + settlement, quote request -> pro quote -> staff quote
-> deposit -> scheduled, chat, cancellation.

Run:  python -I scripts/smoke.py [base_url]
"""

import json
import os
import subprocess
import random
import sys
import urllib.error
import urllib.request
from datetime import date, timedelta

BASE = sys.argv[1] if len(sys.argv) > 1 else "http://127.0.0.1:8080"
ADMIN = ("admin@local.test", "change-me-now-please")
DISTRICT = "11680"  # Gangnam-gu


def call(method, path, body=None, token=None, expect=200):
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    if token:
        req.add_header("Authorization", f"Bearer {token}")
    try:
        with urllib.request.urlopen(req) as r:
            status, payload = r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        status, payload = e.code, json.loads(e.read() or b"null")
    assert status == expect, f"{method} {path}: expected {expect}, got {status} {payload}"
    return payload


def sql(statement):
    # Test-only shortcut to move a booking to its visit day (local dev DB).
    psql = os.environ.get("PSQL", "F:/tools/pgsql/bin/psql.exe")
    env = {**os.environ, "PGPASSWORD": os.environ.get("PGPASSWORD", "localdev")}
    subprocess.run([psql, "-h", "localhost", "-p", os.environ.get("PGPORT", "5433"), "-U", "postgres", "-d", "cleaning", "-qc", statement], check=True, env=env)


def phone():
    return f"010{random.randint(10000000, 99999999)}"


def login(audience):
    p = phone()
    code = call("POST", "/v1/auth/otp", {"phone": p})["dev_code"]
    call("POST", "/v1/auth/verify", {"phone": p, "code": "000000" if code != "000000" else "111111", "audience": audience}, expect=400)
    return call("POST", "/v1/auth/verify", {"phone": p, "code": code, "audience": audience})["access_token"]


def add_card(token, auth_key, name):
    # Cards need an open billing-issue ticket; /v1/me/payment-methods/setup only opens one when PortOne is configured.
    me = call("GET", "/v1/me", token=token)
    if auth_key == "fake_decline":  # the dev decline key is one live billing key DB-wide: free it so reruns work
        sql("UPDATE payment_methods SET deleted_at = now() WHERE billing_key = 'fake_decline' AND deleted_at IS NULL")
    sql(f"INSERT INTO billing_issues (id, user_id, expires_at) VALUES (gen_random_uuid(), '{me['id']}', now() + interval '30 minutes')")
    return call("POST", "/v1/me/payment-methods", {"provider": "card", "auth_key": auth_key, "display_name": name}, token)


def upload_photo(token):
    # Completion photos must be uploads the pro's team owns (routes/partner_jobs.rs complete).
    body = (b'--e2e\r\nContent-Disposition: form-data; name="file"; filename="p.jpg"\r\nContent-Type: image/jpeg\r\n\r\n'
            + b"\xff\xd8\xff\xe0smoke\r\n--e2e--\r\n")
    req = urllib.request.Request(BASE + "/v1/uploads", data=body, method="POST")
    req.add_header("Content-Type", "multipart/form-data; boundary=e2e")
    req.add_header("Authorization", f"Bearer {token}")
    with urllib.request.urlopen(req) as r:
        return json.loads(r.read())["url"]


def step(name):
    print(f"  ok  {name}")


def main():
    # A fresh date per run so repeated runs never fill the same slots.
    # Weekday, not a fixed-date public holiday: quote estimates carry a peak surcharge on those (domain::peak).
    # shortcut: lunar holidays (Seollal, Chuseok) are not skipped; a run landing on one fails the estimate check.
    visit = date.today() + timedelta(days=random.randint(5, 55))
    while visit.weekday() >= 5 or (visit.month, visit.day) in {(1, 1), (3, 1), (5, 5), (6, 6), (8, 15), (10, 3), (10, 9), (12, 25)}:
        visit += timedelta(days=1)
    visit = visit.isoformat()
    staff = call("POST", "/v1/auth/staff/login", {"email": ADMIN[0], "password": ADMIN[1]})["access_token"]
    call("POST", "/v1/auth/staff/login", {"email": ADMIN[0], "password": "wrong"}, expect=401)
    step("staff login, wrong password rejected")

    cust = login("customer")
    call("PATCH", "/v1/me", {"name": "김지은", "locale": "ko"}, cust)
    call("PATCH", "/v1/me", {"name": "김지은"}, cust)
    coupons = call("GET", "/v1/me/coupons", token=cust)
    assert len(coupons) == 1, coupons  # default welcome_pack: one coupon for any service (console-editable)
    any_coupon = next(c for c in coupons if c["service_code"] is None)
    off = any_coupon["amount"]
    step("sign-up issues welcome pack exactly once")

    big = call("POST", "/v1/me/addresses", {"kind": "home", "label": "우리집", "road_address": "서울 강남구 테헤란로 1", "detail": "101동", "district_code": DISTRICT, "size_pyeong": 24}, cust)
    small = call("POST", "/v1/me/addresses", {"kind": "home", "label": "원룸", "road_address": "서울 강남구 역삼로 2", "detail": "3층", "district_code": DISTRICT, "size_pyeong": 9}, cust)
    card = add_card(cust, "ok", "신한 •• 12")
    bad_card = add_card(cust, "fake_decline", "거절카드")

    err = call("POST", "/v1/bookings", {"service_code": "studio", "address_id": big["id"], "visit_date": visit, "start_hour": 9, "payment_method_id": card["id"]}, cust, expect=422)
    assert err["error"]["code"] == "studio_too_large"
    call("POST", "/v1/bookings", {"service_code": "studio", "address_id": small["id"], "visit_date": visit, "start_hour": 9, "payment_method_id": card["id"]}, cust)
    step("studio rule blocks >10 pyeong, allows small home")

    call("POST", "/v1/bookings", {"service_code": "kitchen", "address_id": big["id"], "visit_date": visit, "start_hour": 13, "payment_method_id": bad_card["id"]}, cust, expect=402)
    step("declined card creates no booking")

    b = call("POST", "/v1/bookings", {"service_code": "bathroom", "unit_index": 1, "address_id": big["id"], "visit_date": visit, "start_hour": 9, "coupon_id": any_coupon["id"], "payment_method_id": card["id"]}, cust)
    assert (b["status"], b["list_price"], b["discount"], b["paid_amount"]) == (1, 52000, off, 52000 - off), b
    err = call("POST", "/v1/bookings", {"service_code": "kitchen", "address_id": big["id"], "visit_date": visit, "start_hour": 14, "coupon_id": any_coupon["id"], "payment_method_id": card["id"]}, cust, expect=409)
    assert err["error"]["code"] == "coupon_used"
    step(f"bathroom x2 = 52,000 - {off:,} coupon = {52000 - off:,} paid; coupon single-use")

    pros = [login("partner") for _ in range(2)]
    pro_list = call("GET", "/v1/admin/pros", token=staff)
    for t in pros:
        me = call("GET", "/v1/partner/me", token=t)
        call("POST", f"/v1/admin/pros/{me['id']}/status", {"status": "verified"}, staff)
        call("PUT", "/v1/partner/prefs", {"services": ["bathroom", "move_in"], "districts": [DISTRICT], "weekdays": [0, 1, 2, 3, 4, 5, 6], "day_parts": ["morning", "afternoon"], "days_off": [], "notify": {}}, t)
        call("PUT", "/v1/partner/payout-account", {"bank": "신한", "account_number": "110-123-456789", "holder": "홍길동"}, t)
    feed = call("GET", "/v1/partner/jobs?kind=direct", token=pros[0])
    assert any(j["id"] == b["id"] for j in feed), "job not visible"
    assert "address" not in call("GET", f"/v1/partner/jobs/{b['id']}", token=pros[0])["booking"]
    step(f"pros verified ({len(pro_list) + 2} known); job visible without address")

    call("POST", f"/v1/partner/jobs/{b['id']}/accept", token=pros[0])
    err = call("POST", f"/v1/partner/jobs/{b['id']}/accept", token=pros[1], expect=409)
    assert err["error"]["code"] == "already_taken"
    detail = call("GET", f"/v1/partner/jobs/{b['id']}", token=pros[0])
    assert detail["booking"]["address"]["road_address"] and detail["customer_name"] == "김*은"
    assert call("GET", f"/v1/bookings/{b['id']}", token=cust)["status"] == 2
    step("first pro wins, second gets already_taken; address + masked name revealed; customer sees team assigned")

    photo = upload_photo(pros[0])
    call("POST", f"/v1/partner/jobs/{b['id']}/complete", {"before_photos": [], "after_photos": [photo], "checklist": [True] * 4}, pros[0], expect=400)
    early = call("POST", f"/v1/partner/jobs/{b['id']}/complete", {"before_photos": [photo], "after_photos": [photo], "checklist": [True] * 4}, pros[0], expect=409)
    assert early["error"]["code"] == "job_not_started"
    sql(f"UPDATE bookings SET visit_date = (now() AT TIME ZONE 'Asia/Seoul')::date WHERE id = '{b['id']}'")  # time travel to visit day
    done = call("POST", f"/v1/partner/jobs/{b['id']}/complete", {"before_photos": [photo], "after_photos": [photo], "checklist": [True] * 4}, pros[0])
    assert done["net"] == 41600, done
    assert call("GET", f"/v1/bookings/{b['id']}", token=cust)["status"] == 3
    step("completion needs photos; payout 41,600 (52,000 - 20%) scheduled")

    answers = {"cleaning_type": "after_interior", "luggage": "empty", "building": "apartment", "layout": "three_rooms", "duplex": False, "bathrooms": 2, "balconies": 2, "elevator": True, "floor_3_or_higher": True}
    assert call("POST", "/v1/quote/estimate", answers)["total"] == 580800
    q = call("POST", "/v1/bookings", {"service_code": "move_in", "address_id": big["id"], "visit_date": visit, "start_hour": 8, "answers": answers}, cust)
    assert (q["status"], q["estimate"]) == (0, 580800) and q["thread_id"], q
    msgs = call("GET", f"/v1/chat/threads/{q['thread_id']}/messages", token=cust)
    assert [m["kind"] for m in msgs] == ["system", "card"], msgs
    step("move-in request: status 0, estimate 580,800, thread with system line + card")

    call("POST", f"/v1/partner/jobs/{q['id']}/quote", {"amount": 560000, "note": "분진 많음"}, pros[1])
    quotes = call("GET", f"/v1/admin/bookings/{q['id']}/quotes", token=staff)
    call("POST", f"/v1/chat/threads/{q['thread_id']}/messages", {"kind": "text", "text": "사진 보내드릴게요"}, cust)
    call("POST", f"/v1/admin/threads/{q['thread_id']}/messages", {"kind": "text", "text": "네, 확인할게요"}, staff)
    call("POST", f"/v1/admin/bookings/{q['id']}/send-quote", {"final_price": 560000, "quote_id": quotes[0]["id"]}, staff)
    paid = call("POST", f"/v1/bookings/{q['id']}/deposit", {"payment_method_id": card["id"]}, cust)
    assert (paid["status"], paid["deposit"], paid["paid_amount"]) == (2, 56000, 56000), paid
    my_q = call("GET", "/v1/partner/quotes", token=pros[1])
    assert my_q[0]["state"] == "selected", my_q
    step("pro quote -> staff quote 560,000 -> 56,000 deposit -> pro attached, quote selected")

    threads = call("GET", "/v1/chat/threads", token=cust)
    assert threads[0]["unread_member"] >= 1
    call("POST", f"/v1/chat/threads/{q['thread_id']}/read", token=cust)
    step("chat unread counts and read receipts")

    c = call("POST", "/v1/bookings", {"service_code": "kitchen", "address_id": big["id"], "visit_date": visit, "start_hour": 14, "payment_method_id": card["id"]}, cust)
    cancelled = call("POST", f"/v1/bookings/{c['id']}/cancel", {}, cust)
    assert cancelled["status"] == -1
    detail = call("GET", f"/v1/admin/bookings/{c['id']}", token=staff)
    assert detail["payments"][0]["status"] == "refunded", detail["payments"]
    step("free cancellation refunds in full")

    dash = call("GET", "/v1/admin/dashboard", token=staff)
    call("GET", "/v1/admin/dashboard", token=cust, expect=403)
    step(f"dashboard (30d bookings: {dash['bookings_30d']}); customer blocked from console")
    social_flow(staff, visit)
    print("ALL SMOKE CHECKS PASSED")


def raw(method, path, body=None, headers=None):
    """Like call() but returns (status, payload) without asserting."""
    data = json.dumps(body).encode() if body is not None else None
    req = urllib.request.Request(BASE + path, data=data, method=method)
    req.add_header("Content-Type", "application/json")
    for k, v in (headers or {}).items():
        req.add_header(k, v)
    try:
        with urllib.request.urlopen(req) as r:
            return r.status, json.loads(r.read() or b"null")
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read() or b"null")


def social_flow(staff, visit):
    # Social sign-in (dev fake), phone binding, PortOne checkouts and the admin method switch.
    methods = {m["code"] for m in call("GET", "/v1/payments/methods")}
    assert {"kakaopay", "virtual_account", "card"} <= methods, methods
    step(f"payment methods catalogue ({len(methods)} enabled)")

    token = f"dev:kakao-{random.randint(10**9, 10**10)}"
    first = call("POST", "/v1/auth/social", {"provider": "kakao", "token": token, "audience": "customer"})
    assert first["is_new"] is True and first["needs_phone"] is True, first
    again = call("POST", "/v1/auth/social", {"provider": "kakao", "token": token, "audience": "customer"})
    assert again["subject"] == first["subject"] and again["is_new"] is False, again
    sc = first["access_token"]
    step("social dev:kakao: new account needs_phone=true; same token returns the same account")

    p = phone()
    code = call("POST", "/v1/auth/otp", {"phone": p})["dev_code"]
    bound = call("POST", "/v1/me/phone", {"phone": p, "code": code}, sc)
    assert bound["phone_verified"] is True and bound["phone"] == p, bound
    call("POST", "/v1/me/phone", {"phone": p, "code": code}, sc, expect=400)
    assert call("POST", "/v1/auth/social", {"provider": "kakao", "token": token, "audience": "customer"})["needs_phone"] is False
    step("phone bound via OTP (code is single use); needs_phone=false afterwards")

    addr = call("POST", "/v1/me/addresses", {"kind": "home", "label": "소셜", "road_address": "서울 강남구 테헤란로 9", "detail": "", "district_code": DISTRICT, "size_pyeong": 9}, sc)
    body = {"service_code": "bathroom", "unit_index": 1, "address_id": addr["id"], "visit_date": visit, "start_hour": 14}
    intent = call("POST", "/v1/checkouts", {"kind": "booking", "booking": body, "method": "kakaopay"}, sc)
    assert intent["amount"] == 52000 and intent["method"] == "kakaopay", intent
    done = call("POST", f"/v1/checkouts/{intent['id']}/confirm", {"payment_id": "dev:paid"}, sc)
    assert done["status"] == "paid" and done["booking_id"], done
    assert call("POST", f"/v1/checkouts/{intent['id']}/confirm", {"payment_id": "dev:paid"}, sc) == done
    booked = call("GET", f"/v1/bookings/{done['booking_id']}", token=sc)
    assert booked["status"] == 1 and booked["paid_amount"] == 52000, booked
    step("checkout kakaopay 52,000 -> confirm dev:paid -> booking status 1; re-confirm is idempotent")

    failing = call("POST", "/v1/checkouts", {"kind": "booking", "booking": {**body, "start_hour": 8}, "method": "card"}, sc)
    assert call("POST", f"/v1/checkouts/{failing['id']}/confirm", {"payment_id": "dev:failed"}, sc, expect=402)["error"]["code"] == "payment_failed"
    step("failed payment -> 402 payment_failed, no booking")

    va = call("POST", "/v1/checkouts", {"kind": "booking", "booking": {**body, "start_hour": 13}, "method": "virtual_account"}, sc)
    issued = call("POST", f"/v1/checkouts/{va['id']}/confirm", {"payment_id": "dev:va"}, sc)
    assert issued["status"] == "awaiting_deposit" and issued["virtual_account"]["accountNumber"], issued
    pending = call("GET", "/v1/checkouts?status=awaiting_deposit", token=sc)
    assert any(c["id"] == va["id"] for c in pending), pending
    step("virtual account -> awaiting_deposit, listed for the customer")

    # Card checkout whose confirm never arrives: the Transaction.Paid webhook settles it.
    # Dev has no webhook secret, so the unsigned event is accepted (DEV_MODE rule); PortOne is re-read.
    next_day = (date.fromisoformat(visit) + timedelta(days=1)).isoformat()
    card = call("POST", "/v1/checkouts", {"kind": "booking", "booking": {**body, "start_hour": 9, "visit_date": next_day}, "method": "card"}, sc)
    status, _ = raw("POST", "/v1/webhooks/portone", {"type": "Transaction.Paid", "data": {"paymentId": card["id"]}})
    assert status == 200, status
    settled = call("POST", f"/v1/checkouts/{card['id']}/confirm", {"payment_id": card["id"]}, sc)
    assert settled["status"] == "paid" and settled["booking_id"], settled
    step("card checkout settled by unsigned dev Transaction.Paid webhook (paymentId = checkout id); confirm is idempotent")

    listed = call("GET", "/v1/admin/checkouts?status=paid", token=staff)
    assert any(c["id"] == card["id"] for c in listed), "paid checkout missing from console list"
    call("GET", "/v1/admin/checkouts", token=sc, expect=403)
    call("GET", "/v1/admin/checkouts?status=bogus", token=staff, expect=400)
    step("console lists checkouts for staff; customer gets 403; unknown status 400")

    all_codes = ["card", "kakaopay", "naverpay", "tosspay", "payco", "samsungpay", "applepay", "transfer", "virtual_account", "phone"]
    call("PUT", "/v1/admin/payment-methods", {"enabled": [c for c in all_codes if c != "phone"]}, staff)
    call("POST", "/v1/checkouts", {"kind": "booking", "booking": {**body, "start_hour": 9}, "method": "phone"}, sc, expect=400)
    call("PUT", "/v1/admin/payment-methods", {"enabled": all_codes}, staff)
    step("admin switches a method off (checkout refused), then back on")

    # Social pro without a verified phone: may view, may not accept.
    spro = call("POST", "/v1/auth/social", {"provider": "kakao", "token": f"dev:pro-{random.randint(10**9, 10**10)}", "audience": "partner"})
    pt = spro["access_token"]
    pro_id = call("GET", "/v1/partner/me", token=pt)["id"]
    call("POST", f"/v1/admin/pros/{pro_id}/status", {"status": "verified"}, staff)
    refused = call("POST", f"/v1/partner/jobs/{done['booking_id']}/accept", token=pt, expect=409)
    assert refused["error"]["code"] == "phone_required", refused
    step("social pro without a phone: accept -> 409 phone_required")

    quote_limit(visit)


def quote_limit(visit):
    # A customer may hold three open quote requests; the fourth is refused.
    spam = login("customer")
    addr = call("POST", "/v1/me/addresses", {"kind": "home", "label": "견적", "road_address": "서울 강남구 역삼로 7", "detail": "", "district_code": DISTRICT, "size_pyeong": 24}, spam)
    answers = {"cleaning_type": "after_interior", "luggage": "empty", "building": "apartment", "layout": "three_rooms", "duplex": False, "bathrooms": 2, "balconies": 2, "elevator": True, "floor_3_or_higher": True}
    base = date.fromisoformat(visit)
    for offset in (2, 3, 4):
        request = {"service_code": "move_in", "address_id": addr["id"], "visit_date": (base + timedelta(days=offset)).isoformat(), "start_hour": 8, "answers": answers}
        call("POST", "/v1/bookings", request, spam)
    fourth = {**request, "visit_date": (base + timedelta(days=5)).isoformat()}
    refused = call("POST", "/v1/bookings", fourth, spam, expect=409)
    assert refused["error"]["code"] == "too_many_open_requests", refused
    step("4th open quote request -> 409 too_many_open_requests")


if __name__ == "__main__":
    main()
