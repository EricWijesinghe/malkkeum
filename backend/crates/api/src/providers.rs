//! Adapters for paid external services. Dev mode uses in-process fakes so the
//! whole system runs offline; production adapters plug in behind the same API.

pub mod fcm;
pub mod payout;
pub mod portone;
pub mod sms;
pub mod social;

use crate::{
    config::Config,
    error::ApiError,
    integrations::{Integrations, PayoutMode},
    ops,
};
use payout::{Transfer, TransferStatus};
use reqwest::Request;
use rand::{RngCore, rngs::OsRng};
use sqlx::PgPool;
use serde_json::{Value, json};
use std::{
    sync::{Arc, RwLock},
    time::Duration,
};

const HTTP_TIMEOUT: Duration = Duration::from_secs(10);

#[derive(Debug, thiserror::Error)]
pub enum ProviderError {
    #[error("declined: {0}")]
    Declined(String),
    #[error("provider not configured: {0}")]
    NotConfigured(&'static str),
    #[error("provider request failed: {0}")]
    Upstream(String),
    #[error("not found")]
    NotFound,
}

impl From<ProviderError> for ApiError {
    fn from(e: ProviderError) -> Self {
        match e {
            ProviderError::Declined(m) => ApiError::PaymentFailed(m),
            ProviderError::NotFound => ApiError::NotFound,
            ProviderError::NotConfigured(_) => ApiError::Unavailable("provider_not_configured"),
            ProviderError::Upstream(_) => ApiError::Unavailable("provider_unreachable"),
        }
    }
}

/// Billing key that the fake gateway always declines, for testing failure UX.
pub const FAKE_DECLINE_KEY: &str = "fake_decline";

/// What the payment provider says about one payment (amount in won).
pub struct PaymentInfo {
    pub status: String,
    pub total: i64,
    pub currency: String,
    /// Provider's method object; for virtual accounts it carries the account details.
    pub method: Value,
}

/// Identity verification result (PASS / 본인인증).
pub struct IdentityInfo {
    pub status: String,
    pub ci: Option<String>,
    pub name: Option<String>,
}

/// Keys in use right now; replaced as a whole when the owner saves the setup wizard.
struct Live {
    integ: Arc<Integrations>,
    fcm: Option<fcm::Fcm>,
}

impl Live {
    fn new(integ: Integrations) -> Self {
        let fcm = integ.fcm.clone().map(fcm::Fcm::new);
        Self { integ: Arc::new(integ), fcm }
    }
}

/// Maps a provider result to the ops health record. A declined card or a missing payment means the
/// provider answered, so it counts as healthy.
pub fn outcome<T>(r: &Result<T, ProviderError>) -> Result<(), &'static str> {
    match r {
        Ok(_) | Err(ProviderError::Declined(_) | ProviderError::NotFound) => Ok(()),
        Err(ProviderError::NotConfigured(_)) => Err("not_configured"),
        Err(ProviderError::Upstream(_)) => Err("provider_error"),
    }
}

#[derive(Clone)]
pub struct Providers {
    cfg: Config,
    http: reqwest::Client,
    live: Arc<RwLock<Live>>,
    db: PgPool,
}

fn random_id(prefix: &str) -> String {
    let mut b = [0u8; 12];
    OsRng.fill_bytes(&mut b);
    format!("{prefix}_{}", hex::encode(b))
}

impl Providers {
    pub fn new(cfg: Config, db: PgPool) -> Result<Self, reqwest::Error> {
        let http = reqwest::Client::builder().timeout(HTTP_TIMEOUT).build()?;
        let live = Arc::new(RwLock::new(Live::new(Integrations::from_config(&cfg))));
        Ok(Self { cfg, http, live, db })
    }

    /// Feeds the status page and alert rules. Live traffic only: dev fakes never count as health.
    pub async fn observe(&self, integration: &'static str, outcome: Result<(), &'static str>) {
        if !self.dev() {
            ops::record(&self.db, integration, outcome).await;
        }
    }

    pub fn cfg(&self) -> &Config {
        &self.cfg
    }

    /// Snapshot of the live integration keys.
    pub fn integ(&self) -> Arc<Integrations> {
        // A panic while holding the lock cannot leave Live half-written (it is replaced whole).
        self.live.read().unwrap_or_else(|e| e.into_inner()).integ.clone()
    }

    fn fcm(&self) -> Option<fcm::Fcm> {
        self.live.read().unwrap_or_else(|e| e.into_inner()).fcm.clone()
    }

    /// Switches every provider to new keys (setup wizard save, periodic refresh).
    pub fn set_integrations(&self, integ: Integrations) {
        *self.live.write().unwrap_or_else(|e| e.into_inner()) = Live::new(integ);
    }

    pub fn http(&self) -> &reqwest::Client {
        &self.http
    }

    fn dev(&self) -> bool {
        self.cfg.dev_mode
    }

    fn require_dev(&self, what: &'static str) -> Result<(), ProviderError> {
        // shortcut: only the legacy 'pg' gateway has no real adapter; PortOne is wired in portone.rs.
        if self.dev() { Ok(()) } else { Err(ProviderError::NotConfigured(what)) }
    }

    pub async fn send_sms(&self, phone: &str, text: &str) -> Result<(), ProviderError> {
        if !self.dev() {
            let integ = self.integ();
            let cfg = integ.solapi.as_ref().ok_or(ProviderError::NotConfigured("sms"))?;
            let sent = sms::send_sms(&self.http, cfg, phone, text).await;
            self.observe("solapi", outcome(&sent)).await;
            return sent;
        }
        tracing::info!(target: "fake_sms", phone, text, "sms sent");
        Ok(())
    }

    /// Customer message for an event kind. Sent as AlimTalk when a template is configured for `kind`
    /// (Solapi carries the text as SMS fallback); if that call fails, a plain SMS goes out instead.
    /// Kinds without a template send nothing here (in-app and push still cover them).
    pub async fn send_customer_message(&self, phone: &str, kind: &str, title: &str, body: &str) -> Result<(), ProviderError> {
        let integ = self.integ();
        let Some(cfg) = integ.solapi.as_ref() else {
            return Ok(());
        };
        let Some(template) = cfg.templates.get(kind) else {
            return Ok(());
        };
        let text = format!("{title}\n{body}");
        if self.dev() {
            tracing::info!(target: "fake_alimtalk", phone, kind, text, "alimtalk sent");
            return Ok(());
        }
        let variables = json!({ "#{title}": title, "#{body}": body });
        let sent = match cfg.pf_id.as_deref() {
            Some(pf_id) => sms::send_alimtalk(&self.http, cfg, pf_id, template, phone, &text, variables).await,
            None => Err(ProviderError::NotConfigured("alimtalk")),
        };
        let final_result = match sent {
            Ok(()) => Ok(()),
            Err(e) => {
                tracing::warn!(error = %e, kind, "alimtalk failed; sending sms");
                sms::send_sms(&self.http, cfg, phone, &text).await
            }
        };
        self.observe("solapi", outcome(&final_result)).await;
        final_result
    }

    /// Exchange the gateway's card-auth result for a reusable billing key.
    /// Dev mode fakes it. Live: the key must be `ISSUED` and bound to `customer` and `issue` before it is stored.
    pub async fn issue_billing_key(&self, auth_key: &str, customer: &str, issue: &str) -> Result<String, ProviderError> {
        if !self.dev() {
            let verified = portone::verify_billing_key(self, auth_key, customer, issue).await;
            self.observe("portone", outcome(&verified)).await;
            return verified.map(|()| auth_key.to_string());
        }
        if auth_key == FAKE_DECLINE_KEY {
            return Ok(FAKE_DECLINE_KEY.into());
        }
        Ok(random_id("bk"))
    }

    pub async fn charge(&self, billing_key: &str, amount: i64, idempotency_key: &str) -> Result<String, ProviderError> {
        self.require_dev("payments")?;
        if billing_key == FAKE_DECLINE_KEY {
            return Err(ProviderError::Declined("card_declined".into()));
        }
        tracing::info!(target: "fake_pg", amount, idempotency_key, "charged");
        Ok(random_id("tx"))
    }

    /// Refunds (or cancels) a payment at the gateway that took it.
    pub async fn refund(&self, provider: &str, tx_id: &str, amount: i64) -> Result<(), ProviderError> {
        match provider {
            "portone" if !self.dev() => {
                let cancelled = portone::cancel(self, tx_id, amount).await;
                self.observe("portone", outcome(&cancelled)).await;
                cancelled
            }
            _ => {
                self.require_dev("payments")?;
                tracing::info!(target: "fake_pg", provider, tx_id, amount, "refunded");
                Ok(())
            }
        }
    }

    /// Fetches a PortOne payment. Dev mode fakes only `dev:` ids, priced at `dev_total`.
    pub async fn payment(&self, payment_id: &str, dev_total: i64) -> Result<PaymentInfo, ProviderError> {
        if !self.dev() {
            let found = portone::payment(self, payment_id).await;
            self.observe("portone", outcome(&found)).await;
            return found;
        }
        portone::dev_payment(payment_id, dev_total).ok_or(ProviderError::NotFound)
    }

    /// Verifies a PortOne identity verification (PASS / 본인인증).
    pub async fn identity(&self, verification_id: &str) -> Result<IdentityInfo, ProviderError> {
        if !self.dev() {
            let verified = portone::identity(self, verification_id).await;
            self.observe("portone", outcome(&verified)).await;
            return verified;
        }
        portone::dev_identity(verification_id).ok_or(ProviderError::NotFound)
    }

    /// Provider for new payouts: `manual` unless the owner configured Toss in the setup wizard.
    pub fn payout_mode(&self) -> PayoutMode {
        self.integ().payout.as_ref().map_or(PayoutMode::Manual, |p| p.mode)
    }

    /// Sends a transfer through Toss. `idempotency_key` must stay the same for every retry of one
    /// payout. Returns the provider's transfer id.
    pub async fn send_transfer(&self, idempotency_key: &str, ref_id: &str, t: &Transfer) -> Result<String, ProviderError> {
        if self.dev() {
            return Ok(format!("dev_{ref_id}"));
        }
        let secret = self.payout_secret()?;
        let req = payout::send_request(&self.http, &secret, idempotency_key, ref_id, t)?;
        let body = self.payout_call(req).await?;
        payout::parse_sent(&body)
    }

    /// Current state of a Toss transfer, looked up by Toss's payout id (from `send_transfer`).
    pub async fn transfer_status(&self, provider_id: &str) -> Result<TransferStatus, ProviderError> {
        if self.dev() {
            return Ok(TransferStatus::Paid);
        }
        let secret = self.payout_secret()?;
        let req = payout::status_request(&self.http, &secret, provider_id)?;
        Ok(payout::parse_status(&self.payout_call(req).await?))
    }

    fn payout_secret(&self) -> Result<String, ProviderError> {
        self.integ().payout.as_ref().and_then(|p| p.secret_key.clone()).ok_or(ProviderError::NotConfigured("payout"))
    }

    async fn payout_call(&self, req: Request) -> Result<serde_json::Value, ProviderError> {
        let resp = self.http.execute(req).await.map_err(|e| ProviderError::Upstream(e.to_string()))?;
        let status = resp.status();
        let body = resp.json::<serde_json::Value>().await.unwrap_or(serde_json::Value::Null);
        if status.is_success() { Ok(body) } else { Err(payout::classify(status, &body)) }
    }

    pub async fn push(&self, tokens: &[String], title: &str, body: &str, data: &Value) -> Result<(), ProviderError> {
        self.push_collect(tokens, title, body, data).await.map(|_| ())
    }

    /// Pushes to every token. Returns the tokens the push service reports as dead, for the caller to prune.
    pub async fn push_collect(&self, tokens: &[String], title: &str, body: &str, data: &Value) -> Result<Vec<String>, ProviderError> {
        if tokens.is_empty() {
            return Ok(Vec::new());
        }
        if self.dev() {
            tracing::info!(target: "fake_push", count = tokens.len(), title, body, %data, "push sent");
            return Ok(Vec::new());
        }
        let fcm = self.fcm().ok_or(ProviderError::NotConfigured("push"))?;
        let sent = fcm.send(&self.http, tokens, title, body, data).await;
        self.observe("push", outcome(&sent)).await;
        sent
    }
}
