//! Adapters for paid external services. Dev mode uses in-process fakes so the
//! whole system runs offline; production adapters plug in behind the same API.

use rand::{RngCore, rngs::OsRng};
use serde_json::Value;

#[derive(Debug, thiserror::Error)]
pub enum ProviderError {
    #[error("declined: {0}")]
    Declined(String),
    #[error("provider not configured: {0}")]
    NotConfigured(&'static str),
}

/// Billing key that the fake gateway always declines, for testing failure UX.
pub const FAKE_DECLINE_KEY: &str = "fake_decline";

#[derive(Debug, Clone)]
pub struct Providers {
    dev: bool,
}

fn random_id(prefix: &str) -> String {
    let mut b = [0u8; 12];
    OsRng.fill_bytes(&mut b);
    format!("{prefix}_{}", hex::encode(b))
}

impl Providers {
    pub fn new(dev: bool) -> Self {
        Self { dev }
    }

    fn require_dev(&self, what: &'static str) -> Result<(), ProviderError> {
        // shortcut: only fakes exist yet; add Toss/PortOne, NHN SMS, FCM adapters before launch.
        if self.dev { Ok(()) } else { Err(ProviderError::NotConfigured(what)) }
    }

    pub async fn send_sms(&self, phone: &str, text: &str) -> Result<(), ProviderError> {
        self.require_dev("sms")?;
        tracing::info!(target: "fake_sms", phone, text, "sms sent");
        Ok(())
    }

    /// Exchange the gateway's card-auth result for a reusable billing key.
    pub async fn issue_billing_key(&self, auth_key: &str) -> Result<String, ProviderError> {
        self.require_dev("payments")?;
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

    pub async fn refund(&self, tx_id: &str, amount: i64) -> Result<(), ProviderError> {
        self.require_dev("payments")?;
        tracing::info!(target: "fake_pg", tx_id, amount, "refunded");
        Ok(())
    }

    pub async fn push(&self, tokens: &[String], title: &str, body: &str, data: &Value) -> Result<(), ProviderError> {
        if tokens.is_empty() {
            return Ok(());
        }
        self.require_dev("push")?;
        tracing::info!(target: "fake_push", count = tokens.len(), title, body, %data, "push sent");
        Ok(())
    }
}
