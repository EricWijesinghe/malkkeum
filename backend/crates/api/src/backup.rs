//! Offsite backups. `api backup-upload <file>` (run by `malkkeum backup` after the local dump)
//! records the backup status, encrypts the file with a key derived from DATA_KEY, uploads it to
//! the S3-compatible bucket from the console's `backup` card, and applies the retention window.
//! `api backup-fetch` / `api backup-list` serve `malkkeum restore-offsite`. Nothing is exposed over HTTP.
//!
//! Encrypted file format: "MKB1" | 8-byte random nonce prefix | frames of
//! [flag u8 (1 = last)][len u32 BE][AES-256-GCM ciphertext+tag], 64 KiB plaintext per frame.
//! Nonce = prefix || frame index; the flag is authenticated, so truncation and reordering fail.

use crate::{
    config::Config,
    integrations::{Integrations, S3Config},
    ops,
};
use aes_gcm::{
    Aes256Gcm, Key, KeyInit, Nonce,
    aead::{Aead, Payload},
};
use chrono::{DateTime, Duration, Utc};
use futures_util::StreamExt;
use hmac::{Hmac, Mac};
use rand::{RngCore, rngs::OsRng};
use serde_json::{Value, json};
use sha2::{Digest, Sha256};
use sqlx::{PgPool, postgres::PgPoolOptions};
use std::{
    io::{self, Read, Write},
    path::{Path, PathBuf},
};
use tokio::io::AsyncWriteExt;

const MAGIC: &[u8; 4] = b"MKB1";
const CHUNK: usize = 64 * 1024;
const TAG_LEN: usize = 16;
const PREFIX_OBJECT: &str = "malkkeum/";
const SUFFIX: &str = ".enc";
const CONNECTION_TEST_OBJECT: &str = "malkkeum/connection-test.txt";
const EMPTY_SHA256: &str = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855";
const KEY_CONTEXT: &[u8] = b"malkkeum offsite backup v1";

/// Why a remote call failed. `code()` is what the status page and the wizard show.
#[derive(Debug, thiserror::Error)]
pub enum Fail {
    #[error("backup target unreachable")]
    Unreachable,
    #[error("backup target answered {0}")]
    Rejected(u16),
    #[error("local i/o: {0}")]
    Io(#[from] io::Error),
    #[error("backup file damaged or wrong key")]
    Corrupt,
    #[error("invalid listing from backup target")]
    BadListing,
}

impl Fail {
    pub fn code(&self) -> &'static str {
        match self {
            Self::Unreachable => "unreachable",
            Self::Rejected(401 | 403) => "invalid_key",
            Self::Rejected(_) => "provider_error",
            Self::Io(_) | Self::Corrupt | Self::BadListing => "backup_failed",
        }
    }
}

/// Key for the backup files, derived from DATA_KEY so the owner keeps one secret to protect.
pub fn file_key(data_key: &[u8; 32]) -> [u8; 32] {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(data_key).expect("HMAC takes any key length");
    mac.update(KEY_CONTEXT);
    mac.finalize().into_bytes().into()
}

fn frame_nonce(prefix: &[u8; 8], index: u32) -> Nonce<aes_gcm::aead::consts::U12> {
    let mut n = [0u8; 12];
    n[..8].copy_from_slice(prefix);
    n[8..].copy_from_slice(&index.to_be_bytes());
    Nonce::from(n)
}

fn corrupt() -> io::Error {
    io::Error::new(io::ErrorKind::InvalidData, "backup file damaged or wrong key")
}

/// Reads up to one chunk; a short result means end of input.
fn read_chunk<R: Read>(input: &mut R) -> io::Result<Vec<u8>> {
    let mut buf = vec![0u8; CHUNK];
    let mut filled = 0;
    while filled < CHUNK {
        let n = input.read(&mut buf[filled..])?;
        if n == 0 {
            break;
        }
        filled += n;
    }
    buf.truncate(filled);
    Ok(buf)
}

/// Streams `input` into the encrypted format. Each frame is written once the next one is read,
/// so the final frame (and only it) carries the last flag.
pub fn encrypt_stream<R: Read, W: Write>(key: &[u8; 32], mut input: R, mut output: W) -> io::Result<()> {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let mut prefix = [0u8; 8];
    OsRng.fill_bytes(&mut prefix);
    output.write_all(MAGIC)?;
    output.write_all(&prefix)?;
    let mut current = read_chunk(&mut input)?;
    let mut index: u32 = 0;
    loop {
        let next = read_chunk(&mut input)?;
        let last = next.is_empty();
        let flag = [u8::from(last)];
        let ct = cipher
            .encrypt(&frame_nonce(&prefix, index), Payload { msg: &current, aad: &flag })
            .map_err(|_| io::Error::other("encryption failed"))?;
        output.write_all(&flag)?;
        output.write_all(&(ct.len() as u32).to_be_bytes())?;
        output.write_all(&ct)?;
        if last {
            return Ok(());
        }
        current = next;
        index = index.checked_add(1).ok_or_else(|| io::Error::other("backup too large"))?;
    }
}

/// Reverses [`encrypt_stream`]. Fails on a wrong key, any changed byte, reordered frames, or a missing last frame.
pub fn decrypt_stream<R: Read, W: Write>(key: &[u8; 32], mut input: R, mut output: W) -> io::Result<()> {
    let cipher = Aes256Gcm::new(Key::<Aes256Gcm>::from_slice(key));
    let mut head = [0u8; 12];
    input.read_exact(&mut head)?;
    if &head[..4] != MAGIC {
        return Err(corrupt());
    }
    let prefix: [u8; 8] = head[4..].try_into().map_err(|_| corrupt())?;
    let mut index: u32 = 0;
    loop {
        let mut frame = [0u8; 5];
        input.read_exact(&mut frame)?;
        let flag = frame[0];
        let len = u32::from_be_bytes([frame[1], frame[2], frame[3], frame[4]]) as usize;
        if flag > 1 || len > CHUNK + TAG_LEN {
            return Err(corrupt());
        }
        let mut ct = vec![0u8; len];
        input.read_exact(&mut ct)?;
        let plain = cipher
            .decrypt(&frame_nonce(&prefix, index), Payload { msg: &ct, aad: &[flag] })
            .map_err(|_| corrupt())?;
        output.write_all(&plain)?;
        if flag == 1 {
            let mut probe = [0u8; 1];
            return if input.read(&mut probe)? == 0 { Ok(()) } else { Err(corrupt()) };
        }
        index = index.checked_add(1).ok_or_else(corrupt)?;
    }
}

fn hmac256(key: &[u8], msg: &[u8]) -> [u8; 32] {
    let mut mac = <Hmac<Sha256> as Mac>::new_from_slice(key).expect("HMAC takes any key length");
    mac.update(msg);
    mac.finalize().into_bytes().into()
}

fn hex(bytes: impl AsRef<[u8]>) -> String {
    bytes.as_ref().iter().map(|b| format!("{b:02x}")).collect()
}

/// AWS Signature V4 signing key for one date, region and service.
pub fn signing_key(secret: &str, date: &str, region: &str, service: &str) -> [u8; 32] {
    let k = hmac256(format!("AWS4{secret}").as_bytes(), date.as_bytes());
    let k = hmac256(&k, region.as_bytes());
    let k = hmac256(&k, service.as_bytes());
    hmac256(&k, b"aws4_request")
}

/// Credentials and scope for one signed request.
pub struct Sigv4<'a> {
    pub access: &'a str,
    pub secret: &'a str,
    pub region: &'a str,
    pub service: &'a str,
}

/// Builds the `Authorization` header value. `headers` are (lowercase name, value), sorted by name.
pub fn authorization(c: &Sigv4, method: &str, canonical_uri: &str, query: &str, headers: &[(&str, &str)], payload_hash: &str, amz_date: &str) -> String {
    let date = &amz_date[..8];
    let signed: Vec<&str> = headers.iter().map(|(k, _)| *k).collect();
    let signed_list = signed.join(";");
    let canon_headers: String = headers.iter().map(|(k, v)| format!("{k}:{}\n", v.trim())).collect();
    let canonical = format!("{method}\n{canonical_uri}\n{query}\n{canon_headers}\n{signed_list}\n{payload_hash}");
    let scope = format!("{date}/{}/{}/aws4_request", c.region, c.service);
    let to_sign = format!("AWS4-HMAC-SHA256\n{amz_date}\n{scope}\n{}", hex(Sha256::digest(canonical.as_bytes())));
    let key = signing_key(c.secret, date, c.region, c.service);
    let sig = hex(hmac256(&key, to_sign.as_bytes()));
    format!("AWS4-HMAC-SHA256 Credential={}/{scope}, SignedHeaders={signed_list}, Signature={sig}", c.access)
}

/// RFC 3986 encoding of a path, keeping '/'.
fn encode_path(s: &str) -> String {
    s.bytes()
        .map(|b| match b {
            b'A'..=b'Z' | b'a'..=b'z' | b'0'..=b'9' | b'-' | b'_' | b'.' | b'~' | b'/' => (b as char).to_string(),
            _ => format!("%{b:02X}"),
        })
        .collect()
}

/// Host part of the endpoint, for the Host header and the signature.
fn host_of(endpoint: &str) -> &str {
    endpoint.trim_start_matches("https://").split('/').next().unwrap_or_default()
}

/// Path-style request to the bucket. `name` is an object key, or empty for the bucket itself.
struct Req<'a> {
    cfg: &'a S3Config,
    method: &'static str,
    name: &'a str,
    query: &'static str,
    payload_hash: &'a str,
    body: Option<(reqwest::Body, u64)>,
}

async fn send(http: &reqwest::Client, r: Req<'_>) -> Result<reqwest::Response, Fail> {
    let cfg = r.cfg;
    let path = if r.name.is_empty() { format!("/{}", cfg.bucket) } else { format!("/{}/{}", cfg.bucket, r.name) };
    let canonical_uri = encode_path(&path);
    let amz_date = Utc::now().format("%Y%m%dT%H%M%SZ").to_string();
    let host = host_of(&cfg.endpoint).to_string();
    let length = r.body.as_ref().map(|(_, n)| n.to_string());
    let mut headers: Vec<(&str, &str)> = vec![("host", host.as_str()), ("x-amz-content-sha256", r.payload_hash), ("x-amz-date", amz_date.as_str())];
    if let Some(len) = &length {
        headers.push(("content-length", len.as_str()));
    }
    headers.sort_by(|a, b| a.0.cmp(b.0));
    let auth = authorization(
        &Sigv4 { access: &cfg.access_key, secret: &cfg.secret_key, region: &cfg.region, service: "s3" },
        r.method,
        &canonical_uri,
        r.query,
        &headers,
        r.payload_hash,
        &amz_date,
    );
    let url = if r.query.is_empty() { format!("{}{}", cfg.endpoint, canonical_uri) } else { format!("{}{}?{}", cfg.endpoint, canonical_uri, r.query) };
    let method = reqwest::Method::from_bytes(r.method.as_bytes()).map_err(|_| Fail::Corrupt)?;
    let mut req = http
        .request(method, url)
        .header("x-amz-date", &amz_date)
        .header("x-amz-content-sha256", r.payload_hash)
        .header("authorization", auth);
    if let Some((body, n)) = r.body {
        req = req.header("content-length", n.to_string()).body(body);
    }
    let resp = req.send().await.map_err(|_| Fail::Unreachable)?;
    if resp.status().is_success() {
        Ok(resp)
    } else {
        Err(Fail::Rejected(resp.status().as_u16()))
    }
}

/// Hashes a local file (streamed) and returns (hex sha256, length).
async fn hash_file(path: PathBuf) -> Result<(String, u64), Fail> {
    tokio::task::spawn_blocking(move || {
        let mut f = std::fs::File::open(&path)?;
        let len = f.metadata()?.len();
        let mut h = Sha256::new();
        io::copy(&mut f, &mut h)?;
        Ok((hex(h.finalize()), len))
    })
    .await
    .map_err(|_| Fail::Corrupt)?
}

/// Uploads a local file as object `name`.
pub async fn put_file(http: &reqwest::Client, cfg: &S3Config, name: &str, path: &Path) -> Result<(), Fail> {
    let (hash, len) = hash_file(path.to_path_buf()).await?;
    let file = tokio::fs::File::open(path).await?;
    send(http, Req { cfg, method: "PUT", name, query: "", payload_hash: &hash, body: Some((reqwest::Body::from(file), len)) }).await?;
    Ok(())
}

/// Downloads object `name` into the local file `out`.
pub async fn get_file(http: &reqwest::Client, cfg: &S3Config, name: &str, out: &Path) -> Result<(), Fail> {
    let resp = send(http, Req { cfg, method: "GET", name, query: "", payload_hash: EMPTY_SHA256, body: None }).await?;
    let mut file = tokio::fs::File::create(out).await?;
    let mut stream = resp.bytes_stream();
    while let Some(chunk) = stream.next().await {
        file.write_all(&chunk.map_err(|_| Fail::Unreachable)?).await?;
    }
    file.flush().await?;
    Ok(())
}

async fn delete_object(http: &reqwest::Client, cfg: &S3Config, name: &str) -> Result<(), Fail> {
    send(http, Req { cfg, method: "DELETE", name, query: "", payload_hash: EMPTY_SHA256, body: None }).await?;
    Ok(())
}

/// Lists object keys under our prefix (first page, up to 1000 objects).
pub async fn list_objects(http: &reqwest::Client, cfg: &S3Config) -> Result<Vec<(String, DateTime<Utc>)>, Fail> {
    let resp = send(
        http,
        Req { cfg, method: "GET", name: "", query: "list-type=2&prefix=malkkeum%2F", payload_hash: EMPTY_SHA256, body: None },
    )
    .await?;
    let xml = resp.text().await.map_err(|_| Fail::Unreachable)?;
    parse_listing(&xml).ok_or(Fail::BadListing)
}

fn tag<'a>(block: &'a str, name: &str) -> Option<&'a str> {
    let open = format!("<{name}>");
    let start = block.find(&open)? + open.len();
    let end = block[start..].find(&format!("</{name}>"))? + start;
    Some(&block[start..end])
}

/// Reads `<Contents>` blocks of a ListObjectsV2 response.
pub fn parse_listing(xml: &str) -> Option<Vec<(String, DateTime<Utc>)>> {
    let mut out = Vec::new();
    for block in xml.split("<Contents>").skip(1) {
        let key = tag(block, "Key")?.to_string();
        let modified = tag(block, "LastModified")?;
        let at = DateTime::parse_from_rfc3339(modified).ok()?.with_timezone(&Utc);
        out.push((key, at));
    }
    Some(out)
}

/// Object keys older than the retention window. Only our own `.enc` backups are ever selected.
pub fn expired(objects: &[(String, DateTime<Utc>)], now: DateTime<Utc>, retention_days: u32) -> Vec<String> {
    let cutoff = now - Duration::days(i64::from(retention_days));
    objects
        .iter()
        .filter(|(key, at)| key.starts_with(PREFIX_OBJECT) && key.ends_with(SUFFIX) && *at < cutoff)
        .map(|(key, _)| key.clone())
        .collect()
}

/// Connection test for the wizard: writes and removes a tiny object. Proves the keys and bucket work.
pub async fn check(http: &reqwest::Client, cfg: &S3Config) -> Result<(), Fail> {
    let body = b"malkkeum connection test".to_vec();
    let hash = hex(Sha256::digest(&body));
    let len = body.len() as u64;
    send(http, Req { cfg, method: "PUT", name: CONNECTION_TEST_OBJECT, query: "", payload_hash: &hash, body: Some((reqwest::Body::from(body), len)) }).await?;
    delete_object(http, cfg, CONNECTION_TEST_OBJECT).await
}

/// Stores the last backup status in `settings` (read by the status page and the alert rules).
pub async fn store_status(db: &PgPool, status: &Value) -> Result<(), sqlx::Error> {
    sqlx::query(
        "INSERT INTO settings (key, value) VALUES ($1, $2)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value, updated_at = now()",
    )
    .bind(ops::BACKUP_STATUS_KEY)
    .bind(status)
    .execute(db)
    .await
    .map(|_| ())
}

/// Encrypts `file`, uploads it as `malkkeum/<name>.enc`, then applies retention. Returns Ok when all of it worked.
async fn offsite(http: &reqwest::Client, cfg: &S3Config, data_key: &[u8; 32], file: &Path) -> Result<(), Fail> {
    let name = format!("{PREFIX_OBJECT}{}{SUFFIX}", file.file_name().and_then(|n| n.to_str()).unwrap_or("backup"));
    let tmp = std::env::temp_dir().join(format!("malkkeum-{}.enc", std::process::id()));
    let key = file_key(data_key);
    let src = std::fs::File::open(file)?;
    let dst = std::fs::File::create(&tmp)?;
    let result: Result<(), Fail> = async {
        let mut sealed = io::BufWriter::new(dst);
        encrypt_stream(&key, io::BufReader::new(src), &mut sealed)?;
        sealed.flush()?;
        put_file(http, cfg, &name, &tmp).await?;
        let objects = list_objects(http, cfg).await?;
        for old in expired(&objects, Utc::now(), cfg.retention_days) {
            delete_object(http, cfg, &old).await?;
        }
        Ok(())
    }
    .await;
    let _ = std::fs::remove_file(&tmp);
    result
}

async fn open(config: &Config) -> Result<(PgPool, Integrations), String> {
    let db = PgPoolOptions::new().max_connections(2).connect(&config.database_url).await.map_err(|e| e.to_string())?;
    let integ = crate::integrations::load(&db, config).await.map_err(|e| e.to_string())?;
    Ok((db, integ))
}

/// `api backup-upload <file>`: the cron job's second step. Local status is recorded first, so a
/// failing offsite target never hides a good local dump.
async fn upload_cmd(config: &Config, file: &str) -> i32 {
    let path = Path::new(file);
    let Ok(meta) = std::fs::metadata(path) else {
        eprintln!("backup file not found: {file}");
        return 1;
    };
    let (db, integ) = match open(config).await {
        Ok(v) => v,
        Err(e) => {
            eprintln!("database: {e}");
            return 1;
        }
    };
    let name = path.file_name().and_then(|n| n.to_str()).unwrap_or(file);
    let mut status = json!({ "at": Utc::now(), "file": name, "size_bytes": meta.len(), "offsite": null });
    if let Err(e) = store_status(&db, &status).await {
        eprintln!("status: {e}");
        return 1;
    }
    let Some(cfg) = integ.backup.as_ref() else {
        println!("offsite backup not set up (console: 설정 > 백업)");
        return 0;
    };
    let http = reqwest::Client::new();
    let outcome = offsite(&http, cfg, &config.data_key, path).await;
    let code = outcome.as_ref().err().map(Fail::code);
    if let Err(e) = ops::write_outcome(&db, "backup", outcome.as_ref().map(|_| ()).map_err(|e| e.code())).await {
        eprintln!("ops record: {e}");
    }
    status["offsite"] = json!({ "ok": code.is_none(), "at": Utc::now(), "error": code });
    if let Err(e) = store_status(&db, &status).await {
        eprintln!("status: {e}");
    }
    match outcome {
        Ok(()) => {
            println!("offsite backup uploaded: {name}");
            0
        }
        Err(e) => {
            eprintln!("offsite backup failed: {e}");
            1
        }
    }
}

/// `api backup-fetch <object> <out>`: download and decrypt one offsite backup.
async fn fetch_cmd(config: &Config, name: &str, out: &str) -> i32 {
    let Ok((_db, integ)) = open(config).await else {
        eprintln!("database unavailable");
        return 1;
    };
    let Some(cfg) = integ.backup.as_ref() else {
        eprintln!("offsite backup is not set up");
        return 1;
    };
    let object = if name.starts_with(PREFIX_OBJECT) { name.to_string() } else { format!("{PREFIX_OBJECT}{name}") };
    let out = PathBuf::from(out);
    let cipher = out.with_extension("enc.part");
    let http = reqwest::Client::new();
    let result: Result<(), Fail> = async {
        get_file(&http, cfg, &object, &cipher).await?;
        let src = std::fs::File::open(&cipher)?;
        let mut dst = io::BufWriter::new(std::fs::File::create(&out)?);
        decrypt_stream(&file_key(&config.data_key), io::BufReader::new(src), &mut dst).map_err(|_| Fail::Corrupt)?;
        dst.flush()?;
        Ok(())
    }
    .await;
    let _ = std::fs::remove_file(&cipher);
    match result {
        Ok(()) => {
            println!("restored file written: {}", out.display());
            0
        }
        Err(e) => {
            let _ = std::fs::remove_file(&out);
            eprintln!("fetch failed: {e}");
            1
        }
    }
}

/// `api backup-list`: object names, newest last.
async fn list_cmd(config: &Config) -> i32 {
    let Ok((_db, integ)) = open(config).await else {
        eprintln!("database unavailable");
        return 1;
    };
    let Some(cfg) = integ.backup.as_ref() else {
        eprintln!("offsite backup is not set up");
        return 1;
    };
    match list_objects(&reqwest::Client::new(), cfg).await {
        Ok(mut objects) => {
            objects.sort_by_key(|(_, at)| *at);
            for (key, at) in objects {
                println!("{}  {}", key.trim_start_matches(PREFIX_OBJECT), at.with_timezone(&chrono::FixedOffset::east_opt(9 * 3600).expect("KST offset")).format("%Y-%m-%d %H:%M"));
            }
            0
        }
        Err(e) => {
            eprintln!("list failed: {e}");
            1
        }
    }
}

/// Runs one backup subcommand. Returns the process exit code.
pub async fn cli(args: &[String]) -> i32 {
    let config = match Config::from_env() {
        Ok(c) => c,
        Err(e) => {
            eprintln!("config: {e}");
            return 1;
        }
    };
    match args {
        [cmd, file] if cmd == "backup-upload" => upload_cmd(&config, file).await,
        [cmd, name, out] if cmd == "backup-fetch" => fetch_cmd(&config, name, out).await,
        [cmd] if cmd == "backup-list" => list_cmd(&config).await,
        _ => {
            eprintln!("usage: api backup-upload <file> | backup-fetch <object> <out> | backup-list");
            2
        }
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use chrono::TimeZone;

    fn enc(key: &[u8; 32], data: &[u8]) -> Vec<u8> {
        let mut out = Vec::new();
        encrypt_stream(key, data, &mut out).expect("encrypt");
        out
    }

    fn dec(key: &[u8; 32], data: &[u8]) -> io::Result<Vec<u8>> {
        let mut out = Vec::new();
        decrypt_stream(key, data, &mut out)?;
        Ok(out)
    }

    #[test]
    fn sigv4_matches_aws_get_vanilla_vector() {
        let c = Sigv4 { access: "AKIDEXAMPLE", secret: "wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", region: "us-east-1", service: "service" };
        let headers = [("host", "example.amazonaws.com"), ("x-amz-date", "20150830T123600Z")];
        let auth = authorization(&c, "GET", "/", "", &headers, EMPTY_SHA256, "20150830T123600Z");
        assert_eq!(
            auth,
            "AWS4-HMAC-SHA256 Credential=AKIDEXAMPLE/20150830/us-east-1/service/aws4_request, SignedHeaders=host;x-amz-date, Signature=5fa00fa31553b73ebf1942676e86291e8372ff2a2260956d9b8aae1d763fbf31"
        );
    }

    #[test]
    fn sigv4_matches_aws_s3_get_object_example() {
        let c = Sigv4 { access: "AKIAIOSFODNN7EXAMPLE", secret: "wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY", region: "us-east-1", service: "s3" };
        let headers = [
            ("host", "examplebucket.s3.amazonaws.com"),
            ("range", "bytes=0-9"),
            ("x-amz-content-sha256", EMPTY_SHA256),
            ("x-amz-date", "20130524T000000Z"),
        ];
        let auth = authorization(&c, "GET", "/test.txt", "", &headers, EMPTY_SHA256, "20130524T000000Z");
        assert!(auth.ends_with("Signature=f0e8bdb87c964420e857bd35b5d6ed310bd44f0170aba48dd91039c6036bdb41"), "{auth}");
    }

    #[test]
    fn signing_key_matches_aws_documented_derivation() {
        let k = signing_key("wJalrXUtnFEMI/K7MDENG+bPxRfiCYEXAMPLEKEY", "20120215", "us-east-1", "iam");
        assert_eq!(hex(k), "f4780e2d9f65fa895f9c67b32ce1baf0b0d8a43505a000a1a9e090d414db404d");
    }

    #[test]
    fn encoding_keeps_slashes_and_escapes_the_rest() {
        assert_eq!(encode_path("/bucket/malkkeum/db 1.enc"), "/bucket/malkkeum/db%201.enc");
        assert_eq!(host_of("https://acc.r2.cloudflarestorage.com/"), "acc.r2.cloudflarestorage.com");
    }

    #[test]
    fn encrypted_backup_round_trips_across_chunk_boundaries() {
        let key = file_key(&[9u8; 32]);
        for len in [0, 1, CHUNK - 1, CHUNK, CHUNK + 1, CHUNK * 3 + 17] {
            let data: Vec<u8> = (0..len).map(|i| (i % 251) as u8).collect();
            let sealed = enc(&key, &data);
            assert_eq!(dec(&key, &sealed).expect("decrypt"), data, "len {len}");
        }
    }

    #[test]
    fn wrong_key_tampering_truncation_and_reordering_are_rejected() {
        let key = [1u8; 32];
        let data = vec![7u8; CHUNK * 2 + 5];
        let sealed = enc(&key, &data);
        assert!(dec(&[2u8; 32], &sealed).is_err(), "wrong key");
        let mut flipped = sealed.clone();
        let mid = flipped.len() / 2;
        flipped[mid] ^= 1;
        assert!(dec(&key, &flipped).is_err(), "tampered byte");
        assert!(dec(&key, &sealed[..sealed.len() - 40]).is_err(), "truncated");
        assert!(dec(&key, b"not a backup at all").is_err(), "wrong format");
        let mut trailing = sealed.clone();
        trailing.push(0);
        assert!(dec(&key, &trailing).is_err(), "trailing data");
    }

    #[test]
    fn retention_selects_only_old_malkkeum_backups() {
        let now = Utc.with_ymd_and_hms(2026, 11, 11, 0, 0, 0).unwrap();
        let old = Utc.with_ymd_and_hms(2026, 9, 1, 0, 0, 0).unwrap();
        let new = Utc.with_ymd_and_hms(2026, 11, 10, 0, 0, 0).unwrap();
        let objects = vec![
            ("malkkeum/db-old.sql.gz.enc".to_string(), old),
            ("malkkeum/db-new.sql.gz.enc".to_string(), new),
            ("malkkeum/connection-test.txt".to_string(), old),
            ("other/db-old.sql.gz.enc".to_string(), old),
        ];
        assert_eq!(expired(&objects, now, 30), vec!["malkkeum/db-old.sql.gz.enc".to_string()]);
    }

    #[test]
    fn listing_xml_is_parsed() {
        let xml = "<ListBucketResult><Contents><Key>malkkeum/a.enc</Key><LastModified>2026-11-10T18:30:00.000Z</LastModified></Contents></ListBucketResult>";
        let parsed = parse_listing(xml).expect("listing");
        assert_eq!(parsed[0].0, "malkkeum/a.enc");
        assert_eq!(parse_listing("<ListBucketResult></ListBucketResult>"), Some(Vec::new()));
    }

    #[test]
    fn file_key_is_derived_not_the_data_key() {
        let k = file_key(&[3u8; 32]);
        assert_ne!(k, [3u8; 32]);
        assert_eq!(k, file_key(&[3u8; 32]));
    }
}
