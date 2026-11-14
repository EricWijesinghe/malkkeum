/// Container probe (the runtime image has no curl). `--health`: liveness, `--ready`: DB and migrations.
async fn probe(path: &str) -> i32 {
    let port = std::env::var("BIND_ADDR")
        .ok()
        .and_then(|b| b.rsplit(':').next().map(String::from))
        .unwrap_or_else(|| "8080".into());
    let ok = reqwest::get(format!("http://127.0.0.1:{port}{path}"))
        .await
        .is_ok_and(|r| r.status().is_success());
    if ok { 0 } else { 1 }
}

#[tokio::main]
async fn main() {
    match std::env::args().nth(1).as_deref() {
        Some("--health") => std::process::exit(probe("/health").await),
        Some("--ready") => std::process::exit(probe("/ready").await),
        _ => {}
    }
    let args: Vec<String> = std::env::args().skip(1).collect();
    // No logging here: stdout carries the two restored keys.
    if args.first().is_some_and(|a| a == "keys-open") {
        std::process::exit(api::keys_bundle::cli(&args));
    }
    if args.first().is_some_and(|a| a.starts_with("backup-")) {
        api::telemetry::init_logging("warn");
        std::process::exit(api::backup::cli(&args).await);
    }
    api::telemetry::init_logging("info,sqlx=warn");
    let args: Vec<String> = std::env::args().collect();
    if args.get(1).map(String::as_str) == Some("demo") {
        std::process::exit(api::demo::cli(&args[2..]).await);
    }
    if let Err(e) = api::serve().await {
        tracing::error!(error = %e, "fatal");
        std::process::exit(1);
    }
}
