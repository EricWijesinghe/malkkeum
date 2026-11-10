//! People and accounts: customers with addresses, cards, coupons and sign-in identities; partners
//! with teams, preferences and payout accounts; two demo staff; sign-in records (refresh tokens, OTP).

use super::{Ctx, DemoError};
use crate::{auth::hash_password, crypto};
use chrono::{DateTime, Duration, Utc};
use rand::seq::SliceRandom;
use serde_json::Value;
use uuid::Uuid;

pub const CUSTOMER_COUNT: usize = 40;
const IDENTITY_COUNT: usize = 15;
const OTP_COUNT: usize = 12;

const SURNAMES: [&str; 20] = ["김", "이", "박", "최", "정", "강", "조", "윤", "장", "임", "한", "오", "서", "신", "권", "황", "안", "송", "전", "홍"];
const GIVEN: [&str; 24] = [
    "민준", "서연", "지호", "수빈", "현우", "지민", "예린", "도윤", "하은", "준서", "유진", "승민", "소연", "재원", "채원", "태윤", "다은", "성호",
    "미래", "우진", "지우", "시우", "가은", "동현",
];
const ROADS: [&str; 10] = ["테헤란로", "반포대로", "올림픽로", "마포대로", "양재대로", "강변북로", "언주로", "도산대로", "월드컵북로", "동작대로"];
const DETAILS: [&str; 6] = ["101동 1204호", "102동 805호", "3층 302호", "빌라 2층", "오피스텔 1502호", "가든하우스 1층"];
/// Seoul's 25 districts (code, Korean name), same codes as the app's `districts.dart`.
pub const DISTRICTS: [(&str, &str); 25] = [
    ("11680", "강남구"), ("11650", "서초구"), ("11710", "송파구"), ("11740", "강동구"), ("11440", "마포구"),
    ("11560", "영등포구"), ("11170", "용산구"), ("11200", "성동구"), ("11215", "광진구"), ("11590", "동작구"),
    ("11620", "관악구"), ("11500", "강서구"), ("11470", "양천구"), ("11530", "구로구"), ("11545", "금천구"),
    ("11410", "서대문구"), ("11380", "은평구"), ("11110", "종로구"), ("11140", "중구"), ("11230", "동대문구"),
    ("11260", "중랑구"), ("11290", "성북구"), ("11305", "강북구"), ("11320", "도봉구"), ("11350", "노원구"),
];
/// Service codes from `domain::catalog::default_catalog`.
pub const SERVICE_CODES: [&str; 8] = ["studio", "kitchen", "bathroom", "mattress", "aircon", "sofa", "move_out", "move_in"];

/// (leader name, team name, status, fee bps, self-deleted)
const PROS: [(&str, &str, &str, i64, bool); 12] = [
    ("김태현", "말끔케어 강남팀", "verified", 2000, false),
    ("박소영", "햇살청소 송파팀", "verified", 2000, false),
    ("이준호", "깔끔홈 마포점", "verified", 1800, false),
    ("최유나", "반짝이네 서초팀", "verified", 2000, false),
    ("정민석", "정성가득 용산팀", "verified", 2000, false),
    ("강하린", "맑음크루 성동팀", "verified", 2000, false),
    ("조성민", "새벽청소단 강동팀", "verified", 2000, false),
    ("윤서준", "꼼꼼이 관악팀", "verified", 1800, false),
    ("장미소", "쾌적홈 노원팀", "pending", 2000, false),
    ("임재민", "가족청소 양천팀", "pending", 2000, false),
    ("한지은", "하루청소 은평점", "suspended", 2000, false),
    ("오세훈", "포근홈 동작팀", "verified", 2000, true),
];
/// Pros that have extra team members (indices into `PROS`).
const TEAMS: [usize; 3] = [0, 1, 3];
/// Pro account whose payout account is still waiting for bank verification.
const UNVERIFIED_PAYOUT: usize = 6;

#[derive(Clone)]
pub struct Address {
    pub id: Uuid,
    pub kind: &'static str,
    pub label: &'static str,
    pub road: String,
    pub detail: String,
    pub district: &'static str,
    pub size: i16,
}

#[derive(Clone)]
pub struct Coupon {
    pub id: Uuid,
    pub amount: i64,
    pub service: Option<&'static str>,
    pub issued: DateTime<Utc>,
    pub expires: DateTime<Utc>,
    pub used: bool,
}

#[derive(Clone)]
pub struct Customer {
    pub id: Uuid,
    pub created: DateTime<Utc>,
    pub addresses: Vec<Address>,
    pub coupons: Vec<Coupon>,
}

#[derive(Clone)]
pub struct Pro {
    pub id: Uuid,
    pub team: String,
    pub verified: bool,
    pub deleted: bool,
    pub fee_bps: i64,
    pub services: Vec<&'static str>,
    pub districts: Vec<&'static str>,
    /// Owner row plus active members: who can be assigned to a job.
    pub assignees: Vec<Uuid>,
}

pub struct World {
    pub customers: Vec<Customer>,
    pub pros: Vec<Pro>,
    pub admin: Uuid,
    pub consultant: Uuid,
}

pub async fn run(c: &mut Ctx<'_>) -> Result<World, DemoError> {
    let customers = customers(c).await?;
    let pros = pros(c).await?;
    let (admin, consultant) = staff(c).await?;
    sign_in_records(c, &customers, &pros).await?;
    Ok(World { customers, pros, admin, consultant })
}

fn district_name(code: &str) -> &'static str {
    DISTRICTS.iter().find(|(c, _)| *c == code).map_or("", |(_, n)| n)
}

/// Demo customer phones are 0100000NNNN (normalised digits, as the API stores them).
fn customer_phone(i: usize) -> String {
    format!("0100000{:04}", i + 1)
}

async fn customers(c: &mut Ctx<'_>) -> Result<Vec<Customer>, DemoError> {
    let mut out = Vec::with_capacity(CUSTOMER_COUNT);
    for i in 0..CUSTOMER_COUNT {
        let id = c.id();
        let name = format!("{}{}", c.pick(&SURNAMES), c.pick(&GIVEN));
        // 120-170 days back: older than every visit we generate, so bookings never precede sign-up.
        let created = c.ago_days(120, 170);
        let locale = match i % 10 {
            7 => "en",
            9 => "ja",
            _ => "ko",
        };
        let email = c.chance(0.7).then(|| format!("user{:03}@demo.invalid", i + 1));
        let verified_at = c.chance(0.6).then(|| created + Duration::days(1));
        sqlx::query(
            "INSERT INTO users (id, phone, name, email, locale, welcome_issued, created_at, identity_verified_at)
             VALUES ($1,$2,$3,$4,$5,TRUE,$6,$7)",
        )
        .bind(id)
        .bind(customer_phone(i))
        .bind(&name)
        .bind(&email)
        .bind(locale)
        .bind(created)
        .bind(verified_at)
        .execute(&mut *c.tx)
        .await?;
        c.reg("users", id).await?;

        let addresses = addresses(c, id, created).await?;
        card(c, id, created).await?;
        let coupons = coupons(c, id, created).await?;
        out.push(Customer { id, created, addresses, coupons });
    }
    identities(c, &out).await?;
    Ok(out)
}

async fn addresses(c: &mut Ctx<'_>, user: Uuid, created: DateTime<Utc>) -> Result<Vec<Address>, DemoError> {
    let mut out = Vec::new();
    let count = if c.chance(0.3) { 2 } else { 1 };
    for n in 0..count {
        let id = c.id();
        let (kind, label) = if n == 0 { ("home", "집") } else { ("office", "회사") };
        let (code, _) = *c.pick(&DISTRICTS);
        let road = format!("서울특별시 {} {} {}", district_name(code), c.pick(&ROADS), c.range(1, 200));
        let detail = c.pick(&DETAILS).to_string();
        let size = c.range(8, 45) as i16;
        sqlx::query(
            "INSERT INTO addresses (id, user_id, kind, label, road_address, detail, district_code, size_pyeong, created_at)
             VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9)",
        )
        .bind(id)
        .bind(user)
        .bind(kind)
        .bind(label)
        .bind(&road)
        .bind(&detail)
        .bind(code)
        .bind(size)
        .bind(created)
        .execute(&mut *c.tx)
        .await?;
        c.reg("addresses", id).await?;
        out.push(Address { id, kind, label, road, detail, district: code, size });
    }
    Ok(out)
}

/// One card for everyone; some customers also have a Kakao Pay method.
async fn card(c: &mut Ctx<'_>, user: Uuid, created: DateTime<Utc>) -> Result<(), DemoError> {
    let id = c.id();
    let key = format!("demo_bk_{}", c.hex(12));
    sqlx::query("INSERT INTO payment_methods (id, user_id, provider, billing_key, display_name, created_at) VALUES ($1,$2,'card',$3,'데모 카드 1234',$4)")
        .bind(id)
        .bind(user)
        .bind(&key)
        .bind(created)
        .execute(&mut *c.tx)
        .await?;
    c.reg("payment_methods", id).await?;
    if c.chance(0.4) {
        let extra = c.id();
        let key = format!("demo_bk_{}", c.hex(12));
        sqlx::query("INSERT INTO payment_methods (id, user_id, provider, billing_key, display_name, created_at) VALUES ($1,$2,'kakaopay',$3,'데모 카카오페이',$4)")
            .bind(extra)
            .bind(user)
            .bind(&key)
            .bind(created)
            .execute(&mut *c.tx)
            .await?;
        c.reg("payment_methods", extra).await?;
    }
    Ok(())
}

/// Welcome pack issued at sign-up, plus an autumn campaign coupon for some customers.
async fn coupons(c: &mut Ctx<'_>, user: Uuid, created: DateTime<Utc>) -> Result<Vec<Coupon>, DemoError> {
    let mut out = vec![
        (Coupon { id: c.id(), amount: 10_000, service: Some("studio"), issued: created, expires: created + Duration::days(14), used: false }, "스튜디오 첫 예약 1만원 할인", "welcome"),
        (Coupon { id: c.id(), amount: 5_000, service: None, issued: created, expires: created + Duration::days(14), used: false }, "전 서비스 5천원 할인", "welcome"),
    ];
    if c.chance(0.3) {
        let expires = if c.chance(0.5) { c.now + Duration::days(10) } else { c.now - Duration::days(2) };
        let issued = expires - Duration::days(30);
        out.push((Coupon { id: c.id(), amount: 3_000, service: None, issued, expires, used: false }, "가을 감사 쿠폰 3천원", "autumn-2026"));
    }
    let mut rows = Vec::with_capacity(out.len());
    for (coupon, name, campaign) in out {
        sqlx::query("INSERT INTO coupons (id, user_id, name, amount, service_code, campaign, issued_at, expires_at) VALUES ($1,$2,$3,$4,$5,$6,$7,$8)")
            .bind(coupon.id)
            .bind(user)
            .bind(name)
            .bind(coupon.amount)
            .bind(coupon.service)
            .bind(campaign)
            .bind(coupon.issued)
            .bind(coupon.expires)
            .execute(&mut *c.tx)
            .await?;
        c.reg("coupons", coupon.id).await?;
        rows.push(coupon);
    }
    Ok(rows)
}

/// Social sign-in for a few customers. PASS identity is recorded without a CI hash.
async fn identities(c: &mut Ctx<'_>, customers: &[Customer]) -> Result<(), DemoError> {
    const PROVIDERS: [&str; 4] = ["kakao", "naver", "google", "apple"];
    for (i, cust) in customers.iter().take(IDENTITY_COUNT).enumerate() {
        let id = c.id();
        let provider = PROVIDERS[i % PROVIDERS.len()];
        sqlx::query("INSERT INTO user_identities (id, provider, provider_user_id, role, subject_id, email, created_at) VALUES ($1,$2,$3,'customer',$4,NULL,$5)")
            .bind(id)
            .bind(provider)
            .bind(format!("demo_{provider}_{:04}", i + 1))
            .bind(cust.id)
            .bind(cust.created)
            .execute(&mut *c.tx)
            .await?;
        c.reg("user_identities", id).await?;
    }
    Ok(())
}

async fn pros(c: &mut Ctx<'_>) -> Result<Vec<Pro>, DemoError> {
    let mut out = Vec::with_capacity(PROS.len());
    for (i, (leader, team, status, fee_bps, deleted)) in PROS.iter().enumerate() {
        let id = c.id();
        let created = c.ago_days(120, 190);
        let phone = (!deleted).then(|| format!("0100001{:04}", i + 1));
        // A self-deleted account keeps its row for settlement history; personal fields are wiped.
        let (name, team_name) = if *deleted { ("", "") } else { (*leader, *team) };
        let deleted_at = deleted.then(|| c.now - Duration::days(9));
        sqlx::query(
            "INSERT INTO pros (id, phone, name, team_name, status, fee_bps, locale, created_at, deleted_at)
             VALUES ($1,$2,$3,$4,$5,$6,'ko',$7,$8)",
        )
        .bind(id)
        .bind(&phone)
        .bind(name)
        .bind(team_name)
        .bind(*status)
        .bind(*fee_bps as i32)
        .bind(created)
        .bind(deleted_at)
        .execute(&mut *c.tx)
        .await?;
        c.reg("pros", id).await?;

        let owner = c.id();
        sqlx::query("INSERT INTO team_members (id, pro_id, name, phone, role, invite_status, created_at) VALUES ($1,$2,$3,$4,'owner','active',$5)")
            .bind(owner)
            .bind(id)
            .bind(name)
            .bind(phone.clone().unwrap_or_default())
            .bind(created)
            .execute(&mut *c.tx)
            .await?;
        c.reg("team_members", owner).await?;
        let mut assignees = vec![owner];
        if TEAMS.contains(&i) {
            for (n, member) in ["정다운", "백하준"].iter().enumerate() {
                let mid = c.id();
                let mphone = format!("0100002{:04}", i * 10 + n + 1);
                let invite = if n == 0 { "active" } else { "invited" };
                let last_login = (n == 0).then(|| c.now - Duration::days(3));
                sqlx::query("INSERT INTO team_members (id, pro_id, name, phone, role, invite_status, created_at, last_login_at) VALUES ($1,$2,$3,$4,'member',$5,$6,$7)")
                    .bind(mid)
                    .bind(id)
                    .bind(member)
                    .bind(&mphone)
                    .bind(invite)
                    .bind(created + Duration::days(2))
                    .bind(last_login)
                    .execute(&mut *c.tx)
                    .await?;
                c.reg("team_members", mid).await?;
                if n == 0 {
                    assignees.push(mid);
                }
            }
        }
        let verified = *status == "verified";
        let services = pick_subset(c, &SERVICE_CODES, 5, 8);
        let districts = pick_subset(c, &DISTRICTS.map(|d| d.0), 8, 25);
        prefs(c, id, &services, &districts).await?;
        if verified && !deleted {
            payout(c, id, name, i, created).await?;
        }
        out.push(Pro {
            id,
            team: (*team_name).to_string(),
            verified,
            deleted: *deleted,
            fee_bps: *fee_bps,
            services,
            districts,
            assignees,
        });
    }
    Ok(out)
}

fn pick_subset<T: Copy>(c: &mut Ctx<'_>, all: &[T], lo: usize, hi: usize) -> Vec<T> {
    let mut items = all.to_vec();
    items.shuffle(&mut c.rng);
    let n = c.range(lo as i64, hi as i64) as usize;
    items.truncate(n);
    items
}

async fn prefs(c: &mut Ctx<'_>, pro: Uuid, services: &[&str], districts: &[&str]) -> Result<(), DemoError> {
    let services: Vec<String> = services.iter().map(|s| (*s).to_string()).collect();
    let districts: Vec<String> = districts.iter().map(|s| (*s).to_string()).collect();
    let weekdays: Vec<i16> = if c.chance(0.5) { vec![0, 1, 2, 3, 4] } else { vec![0, 1, 2, 3, 4, 5, 6] };
    let day_parts = vec!["morning".to_string(), "afternoon".to_string()];
    let days_off: Vec<chrono::NaiveDate> = if c.chance(0.5) {
        vec![(c.now + Duration::days(c.range(2, 13))).with_timezone(&c.kst).date_naive()]
    } else {
        vec![]
    };
    sqlx::query("INSERT INTO partner_prefs (pro_id, services, districts, weekdays, day_parts, days_off) VALUES ($1,$2,$3,$4,$5,$6)")
        .bind(pro)
        .bind(&services)
        .bind(&districts)
        .bind(&weekdays)
        .bind(&day_parts)
        .bind(&days_off)
        .execute(&mut *c.tx)
        .await?;
    c.reg("partner_prefs", pro).await?;
    Ok(())
}

/// Bank details are encrypted with the real DATA_KEY so a payout run can decrypt them. The number is fake.
async fn payout(c: &mut Ctx<'_>, pro: Uuid, holder: &str, index: usize, created: DateTime<Utc>) -> Result<(), DemoError> {
    let account = "데모-110-000-1234-5678";
    let enc = crypto::encrypt(&c.data_key, account);
    let verified_at = (index != UNVERIFIED_PAYOUT).then(|| created + Duration::days(3));
    sqlx::query("INSERT INTO payout_accounts (pro_id, bank, account_enc, account_last4, holder, verified_at) VALUES ($1,'데모은행',$2,'5678',$3,$4)")
        .bind(pro)
        .bind(&enc)
        .bind(holder)
        .bind(verified_at)
        .execute(&mut *c.tx)
        .await?;
    c.reg("payout_accounts", pro).await?;
    Ok(())
}

async fn staff(c: &mut Ctx<'_>) -> Result<(Uuid, Uuid), DemoError> {
    let mut ids = Vec::new();
    for (email, name, role) in [
        ("demo.admin@demo.invalid", "샘플 관리자", "admin"),
        ("demo.consultant@demo.invalid", "샘플 상담사", "consultant"),
    ] {
        // OS randomness (the demo RNG is seeded, so its output is public) and the row is inactive:
        // nobody can sign in as demo staff. Clear deletes the row.
        let secret: String = (0..32).map(|_| format!("{:02x}", rand::random::<u8>())).collect();
        let hash = hash_password(&secret).map_err(|_| DemoError::Data("staff password hash failed".into()))?;
        let id = c.id();
        sqlx::query("INSERT INTO staff (id, email, name, password_hash, role, active, created_at) VALUES ($1,$2,$3,$4,$5,FALSE,$6)")
            .bind(id)
            .bind(email)
            .bind(name)
            .bind(&hash)
            .bind(role)
            .bind(c.now - Duration::days(100))
            .execute(&mut *c.tx)
            .await?;
        c.reg("staff", id).await?;
        ids.push(id);
    }
    Ok((ids[0], ids[1]))
}

/// Refresh tokens (random hashes, unusable) and expired OTP codes, so the sign-in tables look lived in.
async fn sign_in_records(c: &mut Ctx<'_>, customers: &[Customer], pros: &[Pro]) -> Result<(), DemoError> {
    let mut subjects: Vec<(Uuid, &str)> = customers.iter().take(8).map(|x| (x.id, "customer")).collect();
    subjects.extend(pros.iter().filter(|p| p.verified && !p.deleted).take(3).map(|p| (p.id, "pro")));
    for (n, (subject, role)) in subjects.iter().copied().enumerate() {
        let hash = c.hex(32);
        let revoked: Option<DateTime<Utc>> = (n % 3 == 0).then(|| c.now - Duration::days(5));
        sqlx::query("INSERT INTO refresh_tokens (token_hash, subject, role, expires_at, revoked_at) VALUES ($1,$2,$3,$4,$5)")
            .bind(&hash)
            .bind(subject)
            .bind(role)
            .bind(c.now + Duration::days(30))
            .bind(revoked)
            .execute(&mut *c.tx)
            .await?;
        c.reg("refresh_tokens", &hash).await?;
    }
    for i in 0..OTP_COUNT.min(customers.len()) {
        let id = c.id();
        let created = c.now - Duration::days(2 + i as i64);
        let code_hash = c.hex(32);
        let attempts = c.range(0, 3) as i32;
        sqlx::query("INSERT INTO otp_codes (id, phone, code_hash, attempts, expires_at, created_at) VALUES ($1,$2,$3,$4,$5,$6)")
            .bind(id)
            .bind(customer_phone(i))
            .bind(&code_hash)
            .bind(attempts)
            .bind(created + Duration::minutes(3))
            .bind(created)
            .execute(&mut *c.tx)
            .await?;
        c.reg("otp_codes", id).await?;
    }
    Ok(())
}

/// JSON shape of a stored address snapshot (`bookings.address`), as `booking_core` writes it.
pub(crate) fn address_snapshot(a: &Address) -> Value {
    serde_json::json!({ "kind": a.kind, "label": a.label, "road_address": a.road, "detail": a.detail, "size_pyeong": a.size })
}
