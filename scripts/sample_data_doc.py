"""Writes docs/sample-data.md: every table, its columns, and one real example row.

Run after `api demo load` against a scratch database, so the examples are realistic but fake:
    PSQL=F:/tools/pgsql/bin/psql.exe PGPASSWORD=localdev python -I scripts/sample_data_doc.py cleaning_demo
Secrets (password hashes, encrypted keys, tokens) are masked, never printed.
"""

import json
import os
import pathlib
import subprocess
import sys

DB = sys.argv[1] if len(sys.argv) > 1 else "cleaning_demo"
PSQL = os.environ.get("PSQL", "psql")
OUT = pathlib.Path(__file__).resolve().parent.parent / "docs" / "sample-data.md"
SECRET_HINTS = ("hash", "secret", "token", "password", "key", "ci_", "billing", "_enc")
MAX_CELL = 60

# One-line meaning per table (English · Korean) for the owner's brother.
MEANING = {
    "addresses": "Customers' saved addresses · 고객 주소",
    "audit_log": "Who changed what in the console · 변경 기록",
    "completion_reports": "Before/after photos and checklist when a job ends · 완료 보고",
    "content_items": "Notices, tips, FAQ, banners, legal pages · 공지·FAQ·약관",
    "ops_alerts": "Owner alerts that were sent (dedup) · 사장님 알림 기록",
    "ops_failures": "Recent integration failures · 연동 오류 기록",
    "ops_health": "Last success/failure per integration · 연동 상태",
    "ops_http_errors": "Server error counts per hour · 서버 오류 집계",
    "partner_prefs": "Which services, areas and hours a partner takes · 파트너 작업 조건",
    "payout_accounts": "Partner bank accounts (number encrypted) · 파트너 정산 계좌",
    "refresh_tokens": "Signed-in devices (hashed) · 로그인 유지 기록",
    "slot_capacity": "How many bookings each arrival hour can take · 시간대별 예약 한도",
    "uploads": "Uploaded photos · 업로드 사진",
    "user_identities": "Kakao/Naver/Google/Apple links to an account · 간편 로그인 연결",
    "users": "Customers who signed up · 고객 계정",
    "pros": "Partner cleaning teams (owner account) · 파트너(청소팀) 계정",
    "team_members": "People in a partner's team · 파트너 팀원",
    "staff": "Office staff who use the console · 콘솔 직원 계정",
    "services": "What can be booked and its price rules · 서비스 목록과 가격 규칙",
    "bookings": "Every booking, from request to completion · 예약",
    "quotes": "Partner price offers for quote-type jobs · 파트너 견적",
    "checkouts": "Payment attempts sent to PortOne · 결제 시도",
    "payments": "Money actually received or refunded · 결제·환불 내역",
    "payment_methods": "Saved one-tap cards (PG token only, no card numbers) · 저장된 간편결제",
    "settlements": "What each partner is owed per job · 파트너 정산",
    "payouts": "Weekly transfers to partners · 파트너 지급",
    "coupons": "Discount coupons · 쿠폰",
    "chat_threads": "One conversation (customer or partner ↔ office) · 상담방",
    "chat_messages": "Messages in a conversation · 상담 메시지",
    "notifications": "Inbox entries shown in the apps · 알림함",
    "push_tokens": "Phone addresses for push notifications · 푸시 알림 기기",
    "reviews": "Star ratings after a job · 리뷰",
    "referrals": "Invite-a-friend links and rewards · 친구 초대",
    "settings": "Shop settings (hours, prices formula, offers) · 매장 설정",
    "integration_settings": "Encrypted keys from the setup wizard · 연동 키(암호화)",
    "otp_codes": "Login codes sent by SMS (hashed) · 로그인 인증번호",
    "ai_usage": "AI assistant replies and their token cost · AI 상담 사용량",
    "demo_rows": "Which rows are sample data (for demo clear) · 체험용 데이터 목록",
}


def psql(sql: str) -> str:
    out = subprocess.run(
        [PSQL, "-h", "localhost", "-p", "5433", "-U", "postgres", "-d", DB, "-tA", "-c", sql],
        capture_output=True, text=True, encoding="utf-8", check=True,
    )
    return out.stdout.strip()


def cell(col: str, v) -> str:
    if v is None:
        return "—"
    if any(h in col.lower() for h in SECRET_HINTS):
        return "•••• (hidden)"
    s = json.dumps(v, ensure_ascii=False) if isinstance(v, (dict, list)) else str(v)
    s = s.replace("|", "\\|").replace("\n", " ")
    return s if len(s) <= MAX_CELL else s[: MAX_CELL - 1] + "…"


def main() -> None:
    tables = psql("SELECT table_name FROM information_schema.tables WHERE table_schema='public' "
                  "AND table_type='BASE TABLE' AND table_name NOT LIKE '_sqlx%' ORDER BY 1").splitlines()
    lines = ["# Sample data · 데이터베이스 예시", "",
             "Every table in the Malkkeum database with one example row from the demo data",
             "(`malkkeum demo load`). All names, phones and amounts are fake. Secret columns are hidden.",
             "모든 표와 예시 한 줄이에요. 이름·전화번호·금액은 모두 가짜이고, 비밀 값은 가렸어요.", ""]
    for t in tables:
        cols = psql(f"SELECT column_name || ':' || data_type FROM information_schema.columns "
                    f"WHERE table_schema='public' AND table_name='{t}' ORDER BY ordinal_position").splitlines()
        count = psql(f'SELECT count(*) FROM "{t}"')
        row_json = psql(f'SELECT row_to_json(x) FROM (SELECT * FROM "{t}" LIMIT 1) x')
        row = json.loads(row_json) if row_json else {}
        lines += [f"## `{t}` — {MEANING.get(t, '')}", "", f"{count} rows in the demo.", "",
                  "| column | type | example |", "|---|---|---|"]
        for c in cols:
            name, typ = c.split(":", 1)
            lines.append(f"| `{name}` | {typ} | {cell(name, row.get(name)) if row else '(empty)'} |")
        lines.append("")
    OUT.write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {OUT} ({len(tables)} tables)")


if __name__ == "__main__":
    main()
