//! Personalized home feed: ranked, explained cards. Pure functions; the API gathers the facts
//! (history, saved homes, consents, aggregate counts) and passes them in with today's date, so the
//! same facts always produce the same feed. Each card carries a `reason` code the app explains
//! ("why you see this") and the numbers behind it.

use chrono::{Datelike, NaiveDate};
use serde::Serialize;

/// District social proof is shown only from this many homes (no individuals, no small numbers).
pub const MIN_DISTRICT_K: i64 = 5;
pub const FEED_LIMIT: usize = 5;
/// A five-star partner is offered again only while the memory is recent.
pub const RATED_FIVE_WINDOW_DAYS: i64 = 180;
/// Repeat bookings in the last 90 days that make the subscription offer relevant.
pub const SUBSCRIPTION_MIN_BOOKINGS: i64 = 2;
/// Days before a holiday when the deep-clean nudge starts.
pub const HOLIDAY_LEAD_DAYS: i64 = 14;

/// Days between cleanings per service, the cadence behind "next cleaning due". Services without
/// a cadence never produce a due card. shortcut: a fixed table, not learned per customer; upgrade
/// once enough history exists to fit each customer's own rhythm.
pub fn cadence_days(service: &str) -> Option<i64> {
    match service {
        "studio" => Some(28),
        "kitchen" | "bathroom" => Some(56),
        "aircon" | "sofa" | "mattress" => Some(180),
        _ => None,
    }
}

/// Korean holidays that trigger 대청소 nudges (설날, 추석 start dates). shortcut: hand-kept table,
/// extend each year.
const HOLIDAYS: [(i32, u32, u32); 6] = [(2026, 2, 17), (2026, 9, 25), (2027, 2, 6), (2027, 10, 15), (2028, 1, 26), (2028, 10, 3)];

#[derive(Debug, Clone, Copy, PartialEq, Eq, PartialOrd, Ord, Serialize)]
#[serde(rename_all = "snake_case")]
pub enum CardKind {
    ResumeQuote,
    NextDue,
    RebookPartner,
    Seasonal,
    SizeEstimate,
    Subscription,
    DistrictProof,
}

impl CardKind {
    /// Marketing cards use history to sell, so they need marketing consent. Everything else is
    /// transactional or personal-history and stays on for everyone.
    pub fn needs_marketing(self) -> bool {
        matches!(self, CardKind::Subscription)
    }
}

/// The customer's latest completed clean of one service.
#[derive(Debug, Clone, PartialEq, Eq)]
pub struct LastClean {
    pub service: String,
    pub completed_on: NaiveDate,
    pub partner_id: Option<String>,
    pub rating: Option<i16>,
}

/// Everything the ranking reads. The API fills what it knows; absent facts simply produce no card.
#[derive(Debug, Clone, PartialEq, Eq, Default)]
pub struct FeedFacts {
    pub today: Option<NaiveDate>,
    pub last_cleans: Vec<LastClean>,
    /// Bookings of any status in the last 90 days.
    pub recent_bookings: i64,
    pub size_pyeong: Option<u16>,
    /// Quote the customer started on this device but did not book.
    pub draft_service: Option<String>,
    pub district: Option<(String, i64)>,
    pub marketing_consent: bool,
}

#[derive(Debug, Clone, PartialEq, Eq, Serialize)]
pub struct FeedCard {
    pub kind: CardKind,
    pub score: u32,
    pub service: Option<String>,
    pub partner_id: Option<String>,
    /// Stable code the app turns into the "why you see this" sentence.
    pub reason: &'static str,
    /// Days or counts behind the reason (days since last clean, homes booked, pyeong, ...).
    pub facts: i64,
    /// Name of the district for DistrictProof.
    pub district: Option<String>,
}

fn card(kind: CardKind, score: u32, reason: &'static str) -> FeedCard {
    FeedCard { kind, score, service: None, partner_id: None, reason, facts: 0, district: None }
}

/// Resume the quote the customer left half-finished on this device. Highest: they were about to buy.
fn resume_quote(f: &FeedFacts) -> Option<FeedCard> {
    let service = f.draft_service.clone()?;
    Some(FeedCard { service: Some(service), ..card(CardKind::ResumeQuote, 1000, "draft_unfinished") })
}

/// Next cleaning due: the most overdue service whose cadence has come up (within a week).
fn next_due(f: &FeedFacts, today: NaiveDate) -> Option<FeedCard> {
    f.last_cleans
        .iter()
        .filter_map(|c| {
            let cadence = cadence_days(&c.service)?;
            let since = (today - c.completed_on).num_days();
            (since >= cadence - 7).then_some((since - cadence, c, since))
        })
        .max_by_key(|(overdue, c, _)| (*overdue, c.service.clone()))
        .map(|(overdue, c, since)| FeedCard {
            service: Some(c.service.clone()),
            facts: since,
            // Score grows with days overdue (from a week early) so it outranks calendar nudges.
            ..card(CardKind::NextDue, 900 + (overdue + 7).clamp(0, 70) as u32, "cadence_due")
        })
}

/// Partner the customer rated 5 stars recently: book them again.
fn rebook_partner(f: &FeedFacts, today: NaiveDate) -> Option<FeedCard> {
    f.last_cleans
        .iter()
        .filter(|c| c.rating == Some(5) && c.partner_id.is_some())
        .filter(|c| (today - c.completed_on).num_days() <= RATED_FIVE_WINDOW_DAYS)
        .max_by_key(|c| c.completed_on)
        .map(|c| FeedCard {
            service: Some(c.service.clone()),
            partner_id: c.partner_id.clone(),
            facts: (today - c.completed_on).num_days(),
            ..card(CardKind::RebookPartner, 700, "rated_five")
        })
}

/// Seasonal needs from the calendar: aircon before summer, moving peaks, 대청소 before holidays.
fn seasonal(today: NaiveDate) -> Option<FeedCard> {
    if let Some(holiday) = HOLIDAYS.iter().filter_map(|&(y, m, d)| NaiveDate::from_ymd_opt(y, m, d)).find(|h| {
        let lead = (*h - today).num_days();
        (0..=HOLIDAY_LEAD_DAYS).contains(&lead)
    }) {
        return Some(FeedCard { facts: (holiday - today).num_days(), ..card(CardKind::Seasonal, 520, "holiday_deep_clean") });
    }
    match today.month() {
        5 | 6 => Some(FeedCard { service: Some("aircon".into()), ..card(CardKind::Seasonal, 500, "summer_aircon") }),
        2 | 3 | 8 | 9 => Some(FeedCard { service: Some("move_in".into()), ..card(CardKind::Seasonal, 450, "moving_peak") }),
        _ => None,
    }
}

/// Saved home size: price a clean without asking for the size again.
fn size_estimate(f: &FeedFacts) -> Option<FeedCard> {
    f.size_pyeong.map(|p| FeedCard {
        service: Some("studio".into()),
        facts: i64::from(p),
        ..card(CardKind::SizeEstimate, 350, "saved_home_size")
    })
}

/// Repeat customer: a subscription saves them the next booking.
fn subscription(f: &FeedFacts) -> Option<FeedCard> {
    (f.recent_bookings >= SUBSCRIPTION_MIN_BOOKINGS).then(|| FeedCard {
        facts: f.recent_bookings,
        ..card(CardKind::Subscription, 600, "repeat_customer")
    })
}

/// The number shown for a district: under ten it reads as "5+", from ten up it rounds down to the ten ("30+").
pub fn bucket_homes(homes: i64) -> i64 {
    if homes < 10 { MIN_DISTRICT_K } else { homes / 10 * 10 }
}

/// Aggregate district proof, shown only when enough distinct homes are behind the number. The count is bucketed.
fn district_proof(f: &FeedFacts) -> Option<FeedCard> {
    let (name, count) = f.district.as_ref()?;
    (*count >= MIN_DISTRICT_K).then(|| FeedCard {
        facts: bucket_homes(*count),
        district: Some(name.clone()),
        ..card(CardKind::DistrictProof, 200, "district_booked")
    })
}

/// Ranked, explained feed. Deterministic: score descending, then kind order; one card per kind.
/// Without `today` the feed is empty: time is an input, never read here.
pub fn rank(f: &FeedFacts) -> Vec<FeedCard> {
    let Some(today) = f.today else { return Vec::new() };
    let candidates = [
        resume_quote(f),
        next_due(f, today),
        rebook_partner(f, today),
        seasonal(today),
        size_estimate(f),
        subscription(f),
        district_proof(f),
    ];
    let mut cards: Vec<FeedCard> = candidates
        .into_iter()
        .flatten()
        .filter(|c| f.marketing_consent || !c.kind.needs_marketing())
        .collect();
    cards.sort_by(|a, b| b.score.cmp(&a.score).then(a.kind.cmp(&b.kind)));
    cards.truncate(FEED_LIMIT);
    cards
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::Duration;

    fn day(y: i32, m: u32, d: u32) -> NaiveDate {
        NaiveDate::from_ymd_opt(y, m, d).unwrap()
    }

    fn facts(today: NaiveDate) -> FeedFacts {
        FeedFacts { today: Some(today), marketing_consent: true, ..Default::default() }
    }

    fn clean(service: &str, on: NaiveDate, rating: Option<i16>, partner: Option<&str>) -> LastClean {
        LastClean { service: service.into(), completed_on: on, partner_id: partner.map(str::to_owned), rating }
    }

    fn kinds(cards: &[FeedCard]) -> Vec<CardKind> {
        cards.iter().map(|c| c.kind).collect()
    }

    #[test]
    fn no_today_means_empty_feed() {
        assert!(rank(&FeedFacts::default()).is_empty());
    }

    #[test]
    fn next_due_fires_within_a_week_of_cadence_and_reports_days() {
        let today = day(2026, 11, 12);
        let mut f = facts(today);
        f.last_cleans = vec![clean("studio", today - Duration::days(24), None, None)];
        let cards = rank(&f);
        let due = cards.iter().find(|c| c.kind == CardKind::NextDue).expect("due card");
        assert_eq!((due.service.as_deref(), due.facts, due.reason), (Some("studio"), 24, "cadence_due"));

        f.last_cleans = vec![clean("studio", today - Duration::days(10), None, None)];
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::NextDue), "10 days into a 28-day cadence is not due");
    }

    #[test]
    fn most_overdue_service_wins_and_services_without_cadence_are_ignored() {
        let today = day(2026, 11, 12);
        let mut f = facts(today);
        f.last_cleans = vec![
            clean("kitchen", today - Duration::days(60), None, None),
            clean("studio", today - Duration::days(40), None, None),
            clean("move_in", today - Duration::days(900), None, None),
        ];
        let due = rank(&f).into_iter().find(|c| c.kind == CardKind::NextDue).unwrap();
        assert_eq!(due.service.as_deref(), Some("studio"), "studio is 12 days overdue, kitchen 4");
    }

    #[test]
    fn resume_quote_outranks_everything() {
        let today = day(2026, 2, 16);
        let mut f = facts(today);
        f.draft_service = Some("move_in".into());
        f.last_cleans = vec![clean("studio", today - Duration::days(40), None, None)];
        let cards = rank(&f);
        assert_eq!(cards[0].kind, CardKind::ResumeQuote);
        assert_eq!(cards[0].service.as_deref(), Some("move_in"));
    }

    #[test]
    fn rebook_only_for_recent_five_star_partner() {
        let today = day(2026, 11, 12);
        let mut f = facts(today);
        f.last_cleans = vec![clean("studio", today - Duration::days(30), Some(5), Some("p7"))];
        let card = rank(&f).into_iter().find(|c| c.kind == CardKind::RebookPartner).unwrap();
        assert_eq!(card.partner_id.as_deref(), Some("p7"));

        f.last_cleans = vec![clean("studio", today - Duration::days(30), Some(4), Some("p7"))];
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::RebookPartner));
        f.last_cleans = vec![clean("studio", today - Duration::days(RATED_FIVE_WINDOW_DAYS + 1), Some(5), Some("p7"))];
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::RebookPartner));
    }

    #[test]
    fn seasonal_follows_the_calendar() {
        assert_eq!(seasonal(day(2026, 6, 3)).unwrap().service.as_deref(), Some("aircon"));
        assert_eq!(seasonal(day(2026, 8, 20)).unwrap().reason, "moving_peak");
        assert!(seasonal(day(2026, 11, 12)).is_none());
    }

    #[test]
    fn holiday_deep_clean_starts_two_weeks_before_seollal() {
        let card = seasonal(day(2026, 2, 5)).unwrap();
        assert_eq!((card.reason, card.facts), ("holiday_deep_clean", 12));
        assert_eq!(seasonal(day(2026, 2, 1)).unwrap().reason, "moving_peak", "before the two-week window");
    }

    #[test]
    fn subscription_needs_two_recent_bookings_and_marketing_consent() {
        let today = day(2026, 11, 12);
        let mut f = facts(today);
        f.recent_bookings = 2;
        assert!(rank(&f).iter().any(|c| c.kind == CardKind::Subscription));
        f.marketing_consent = false;
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::Subscription), "no marketing consent, no upsell");
        f.marketing_consent = true;
        f.recent_bookings = 1;
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::Subscription));
    }

    #[test]
    fn district_proof_hidden_below_k_anonymity() {
        let mut f = facts(day(2026, 11, 12));
        f.district = Some(("강남구".into(), MIN_DISTRICT_K - 1));
        assert!(!rank(&f).iter().any(|c| c.kind == CardKind::DistrictProof));
        f.district = Some(("강남구".into(), MIN_DISTRICT_K));
        let card = rank(&f).into_iter().find(|c| c.kind == CardKind::DistrictProof).unwrap();
        assert_eq!((card.district.as_deref(), card.facts), (Some("강남구"), MIN_DISTRICT_K));
    }

    #[test]
    fn district_count_is_bucketed_not_exact() {
        assert_eq!((bucket_homes(5), bucket_homes(9)), (MIN_DISTRICT_K, MIN_DISTRICT_K));
        assert_eq!((bucket_homes(10), bucket_homes(37), bucket_homes(59)), (10, 30, 50));
    }

    #[test]
    fn guest_feed_has_no_personal_or_marketing_cards() {
        let today = day(2026, 6, 3);
        let guest = FeedFacts { today: Some(today), district: Some(("송파구".into(), 40)), ..Default::default() };
        assert_eq!(kinds(&rank(&guest)), vec![CardKind::Seasonal, CardKind::DistrictProof]);
    }

    #[test]
    fn feed_is_capped_sorted_and_deterministic() {
        let today = day(2026, 6, 3);
        let mut f = facts(today);
        f.draft_service = Some("move_in".into());
        f.last_cleans = vec![clean("studio", today - Duration::days(29), Some(5), Some("p1"))];
        f.size_pyeong = Some(25);
        f.recent_bookings = 3;
        f.district = Some(("강남구".into(), 37));
        let first = rank(&f);
        assert!(first.len() <= FEED_LIMIT);
        assert!(first.windows(2).all(|w| w[0].score >= w[1].score));
        assert_eq!(first, rank(&f));
    }
}
