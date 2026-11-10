use tracing_subscriber::EnvFilter;

/// `api --health`: container health check (the runtime image has no curl).
async fn health() -> i32 {
    let port = std::env::var("BIND_ADDR")
        .ok()
        .and_then(|b| b.rsplit(':').next().map(String::from))
        .unwrap_or_else(|| "8080".into());
    let ok = reqwest::get(format!("http://127.0.0.1:{port}/health"))
        .await
        .is_ok_and(|r| r.status().is_success());
    if ok { 0 } else { 1 }
}

#[tokio::main]
async fn main() {
    if std::env::args().nth(1).as_deref() == Some("--health") {
        std::process::exit(health().await);
    }
    tracing_subscriber::fmt()
        .with_env_filter(EnvFilter::try_from_default_env().unwrap_or_else(|_| "info,sqlx=warn".into()))
        .init();
    if let Err(e) = api::serve().await {
        tracing::error!(error = %e, "fatal");
        std::process::exit(1);
    }
}
