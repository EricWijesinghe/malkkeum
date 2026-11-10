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
    subprocess.run([psql, "-h", "localhost", "-p", "5433", "-U", "postgres", "-d", "cleaning", "-qc", statement], check=True, env=env)


def phone():
    return f"010{random.randint(10000000, 99999999)}"


def login(audience):
    p = phone()
    code = call("POST", "/v1/auth/otp", {"phone": p})["dev_code"]
    call("POST", "/v1/auth/verify", {"phone": p, "code": "000000" if code != "000000" else "111111", "audience": audience}, expect=400)
    return call("POST", "/v1/auth/verify", {"phone": p, "code": code, "audience": audience})["access_token"]


def step(name):
    print(f"  ok  {name}")


def main():
    # A fresh date per run so repeated runs never fill the same slots.
    visit = (date.today() + timedelta(days=random.randint(5, 55))).isoformat()
    staff = call("POST", "/v1/auth/staff/login", {"email": ADMIN[0], "password": ADMIN[1]})["access_token"]
    call("POST", "/v1/auth/staff/login", {"email": ADMIN[0], "password": "wrong"}, expect=401)
    step("staff login, wrong password rejected")

    cust = login("customer")
    call("PATCH", "/v1/me", {"name": "김지은", "locale": "ko"}, cust)
    call("PATCH", "/v1/me", {"name": "김지은"}, cust)
    coupons = call("GET", "/v1/me/coupons", token=cust)
    assert len(coupons) == 2, coupons
    any_coupon = next(c for c in coupons if c["service_code"] is None)
    step("sign-up issues welcome pack exactly once")

    big = call("POST", "/v1/me/addresses", {"kind": "home", "label": "우리집", "road_address": "서울 강남구 테헤란로 1", "detail": "101동", "district_code": DISTRICT, "size_pyeong": 24}, cust)
    small = call("POST", "/v1/me/addresses", {"kind": "home", "label": "원룸", "road_address": "서울 강남구 역삼로 2", "detail": "3층", "district_code": DISTRICT, "size_pyeong": 9}, cust)
    card = call("POST", "/v1/me/payment-methods", {"provider": "card", "auth_key": "ok", "display_name": "신한 •• 12"}, cust)
    bad_card = call("POST", "/v1/me/payment-methods", {"provider": "card", "auth_key": "fake_decline", "display_name": "거절카드"}, cust)

    err = call("POST", "/v1/bookings", {"service_code": "studio", "address_id": big["id"], "visit_date": visit, "start_hour": 9, "payment_method_id": card["id"]}, cust, expect=422)
    assert err["error"]["code"] == "studio_too_large"
    call("POST", "/v1/bookings", {"service_code": "studio", "address_id": small["id"], "visit_date": visit, "start_hour": 9, "payment_method_id": card["id"]}, cust)
    step("studio rule blocks >10 pyeong, allows small home")

    call("POST", "/v1/bookings", {"service_code": "kitchen", "address_id": big["id"], "visit_date": visit, "start_hour": 13, "payment_method_id": bad_card["id"]}, cust, expect=402)
    step("declined card creates no booking")

    b = call("POST", "/v1/bookings", {"service_code": "bathroom", "unit_index": 1, "address_id": big["id"], "visit_date": visit, "start_hour": 9, "coupon_id": any_coupon["id"], "payment_method_id": card["id"]}, cust)
    assert (b["status"], b["list_price"], b["discount"], b["paid_amount"]) == (1, 52000, 5000, 47000), b
    err = call("POST", "/v1/bookings", {"service_code": "kitchen", "address_id": big["id"], "visit_date": visit, "start_hour": 14, "coupon_id": any_coupon["id"], "payment_method_id": card["id"]}, cust, expect=409)
    assert err["error"]["code"] == "coupon_used"
    step("bathroom x2 = 52,000 - 5,000 coupon = 47,000 paid; coupon single-use")

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

    photo = f"{BASE}/files/{'ab' * 16}.jpg"
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
    cancelled = call("POST", f"/v1/bookings/{c['id']}/cancel", token=cust)
    assert cancelled["status"] == -1
    detail = call("GET", f"/v1/admin/bookings/{c['id']}", token=staff)
    assert detail["payments"][0]["status"] == "refunded", detail["payments"]
    step("free cancellation refunds in full")

    dash = call("GET", "/v1/admin/dashboard", token=staff)
    call("GET", "/v1/admin/dashboard", token=cust, expect=403)
    step(f"dashboard (30d bookings: {dash['bookings_30d']}); customer blocked from console")
    print("ALL SMOKE CHECKS PASSED")


if __name__ == "__main__":
    main()
