//! Contract checks: the OpenAPI spec must describe every route the server mounts, every route the
//! Flutter apps call, and the idempotency and paging promises the handlers make.

use serde_json::Value;
use std::{
    collections::{BTreeMap, BTreeSet},
    fs,
    path::{Path, PathBuf},
};

const METHODS: [&str; 5] = ["get", "put", "post", "delete", "patch"];
/// Where a route file's paths get mounted: root, `/v1`, or a nest under `/v1`.
const PREFIXES: [&str; 5] = ["", "/v1", "/v1/admin", "/v1/partner", "/v1/member"];
/// Operations that must accept `Idempotency-Key`: every money-moving or duplicate-prone POST.
const IDEMPOTENT_OPS: [&str; 9] = [
    "createBooking",
    "cancelBooking",
    "payDeposit",
    "payBalance",
    "createReview",
    "createCheckout",
    "confirmCheckout",
    "adminCancelBooking",
    "adminPayoutAction",
];
/// Operations that page with `limit`/`cursor` and advertise `X-Next-Cursor`.
const PAGED_OPS: [&str; 12] = [
    "listBookings",
    "listNotifications",
    "listCheckouts",
    "adminListCheckouts",
    "adminListBookings",
    "partnerSettlements",
    "partnerReviews",
    "partnerQuotes",
    "listMyThreads",
    "partnerThreads",
    "adminPayouts",
    "adminListAudit",
];

fn manifest() -> &'static Path {
    Path::new(env!("CARGO_MANIFEST_DIR"))
}

fn spec() -> Value {
    let text = fs::read_to_string(manifest().join("openapi.json")).expect("read openapi.json");
    serde_json::from_str(&text).expect("openapi.json is valid JSON")
}

/// (method, path) pairs in the spec, lowercase methods.
fn spec_ops(spec: &Value) -> Vec<(String, String, &Value)> {
    let mut out = Vec::new();
    for (path, item) in spec["paths"].as_object().expect("paths object") {
        for (method, op) in item.as_object().expect("path item") {
            if METHODS.contains(&method.as_str()) {
                out.push((method.clone(), path.clone(), op));
            }
        }
    }
    out
}

fn spec_methods(spec: &Value, path: &str) -> Option<BTreeSet<String>> {
    let item = spec["paths"].get(path)?.as_object()?;
    Some(item.keys().filter(|k| METHODS.contains(&k.as_str())).cloned().collect())
}

/// Literal path and the HTTP methods of each `.route("...", ...)` in the non-test part of `src`.
fn route_literals(src: &str) -> Vec<(String, BTreeSet<String>)> {
    let src = src.split("#[cfg(test)]").next().unwrap_or(src);
    let mut out = Vec::new();
    for (i, _) in src.match_indices(".route(") {
        let after = src[i + ".route(".len()..].trim_start();
        let Some(rest) = after.strip_prefix('"') else { continue };
        let Some(end) = rest.find('"') else { continue };
        let expr_start = &rest[end..];
        let stop = [".route(", ".nest(", ".merge(", ";"]
            .iter()
            .filter_map(|t| expr_start.find(t))
            .min()
            .unwrap_or(expr_start.len());
        let expr = &expr_start[..stop];
        let methods = METHODS.iter().filter(|m| contains_call(expr, m)).map(|m| (*m).to_owned()).collect();
        out.push((rest[..end].to_owned(), methods));
    }
    out
}

/// `get(` as a call, not as part of a longer identifier. A chained `get(a).post(b)` counts both methods.
fn contains_call(expr: &str, method: &str) -> bool {
    let pat = format!("{method}(");
    expr.match_indices(&pat)
        .any(|(i, _)| expr[..i].chars().last().is_none_or(|c| !(c.is_alphanumeric() || c == '_')))
}

fn route_sources() -> Vec<(String, String)> {
    let dir = manifest().join("src/routes");
    let mut files: Vec<PathBuf> = fs::read_dir(&dir).expect("routes dir").filter_map(|e| e.ok().map(|e| e.path())).collect();
    // Modules outside routes/ that mount API routes of their own.
    for module in ["app_links", "points", "acquisition", "analytics", "client_errors", "marketing"] {
        files.push(manifest().join(format!("src/{module}.rs")));
    }
    files
        .into_iter()
        .filter(|p| p.extension().is_some_and(|x| x == "rs"))
        .map(|p| {
            (
                p.file_name().unwrap_or_default().to_string_lossy().into_owned(),
                fs::read_to_string(&p).expect("read route file"),
            )
        })
        .collect()
}

/// Strips the mount prefix a route file is nested under, leaving the path as the route file wrote it.
fn route_key(spec_path: &str) -> &str {
    let p = spec_path.strip_prefix("/v1").unwrap_or(spec_path);
    ["/admin", "/partner", "/member"].iter().find_map(|x| p.strip_prefix(x)).unwrap_or(p)
}

#[test]
fn spec_is_well_formed() {
    let spec = spec();
    assert!(spec["openapi"].as_str().is_some_and(|v| v.starts_with("3.1")), "OpenAPI 3.1");
    let mut ids = BTreeSet::new();
    for (method, path, op) in spec_ops(&spec) {
        let id = op["operationId"].as_str().unwrap_or_else(|| panic!("{method} {path}: operationId"));
        assert!(ids.insert(id.to_owned()), "duplicate operationId {id}");
        assert!(op["tags"].as_array().is_some_and(|t| !t.is_empty()), "{method} {path}: tags");
        assert!(op["responses"].as_object().is_some_and(|r| !r.is_empty()), "{method} {path}: responses");
    }
}

#[test]
fn every_mounted_route_is_documented() {
    let spec = spec();
    let mut missing = Vec::new();
    for (file, src) in route_sources() {
        for (path, methods) in route_literals(&src) {
            let documented = PREFIXES
                .iter()
                .any(|pre| spec_methods(&spec, &format!("{pre}{path}")).is_some_and(|have| !methods.is_empty() && methods.iter().all(|m| have.contains(m))));
            if !documented {
                missing.push(format!("{file}: {path} {methods:?}"));
            }
        }
    }
    assert!(missing.is_empty(), "routes without an OpenAPI operation:\n{}", missing.join("\n"));
}

#[test]
fn every_documented_operation_is_mounted() {
    let spec = spec();
    let mut mounted: BTreeMap<String, BTreeSet<String>> = BTreeMap::new();
    for (_, src) in route_sources() {
        for (path, methods) in route_literals(&src) {
            mounted.entry(path).or_default().extend(methods);
        }
    }
    let mut stale = Vec::new();
    for (method, path, _) in spec_ops(&spec) {
        let have = mounted.get(route_key(&path));
        if !have.is_some_and(|m| m.contains(&method)) {
            stale.push(format!("{method} {path}"));
        }
    }
    assert!(stale.is_empty(), "documented operations with no route:\n{}", stale.join("\n"));
}

#[test]
fn idempotent_and_paged_operations_say_so() {
    let spec = spec();
    for (_, _, op) in spec_ops(&spec) {
        let id = op["operationId"].as_str().unwrap_or_default();
        let params = op["parameters"].to_string();
        if IDEMPOTENT_OPS.contains(&id) {
            assert!(params.contains("#/components/parameters/IdempotencyKey"), "{id} must document Idempotency-Key");
        }
        if PAGED_OPS.contains(&id) {
            assert!(params.contains("#/components/parameters/Limit"), "{id} must document limit");
            assert!(
                op["responses"]["200"]["headers"]["X-Next-Cursor"].is_object(),
                "{id} must document X-Next-Cursor"
            );
        }
    }
    assert_eq!(IDEMPOTENT_OPS.len(), 9);
}

/// Dart call sites: `api.get('/x')`, `api.post(\n '/x', ...)`, `_uri('/x')`. Returns (method or `*`, path).
fn dart_call_sites(text: &str) -> Vec<(String, String)> {
    let mut out = Vec::new();
    for (i, _) in text.match_indices("'/") {
        let Some(before) = text[..i].trim_end().strip_suffix('(') else { continue };
        let ident: String = before
            .chars()
            .rev()
            .take_while(|c| c.is_alphanumeric() || *c == '_')
            .collect::<Vec<_>>()
            .into_iter()
            .rev()
            .collect();
        let method = match ident.as_str() {
            "get" | "getBytes" => "get",
            "post" => "post",
            "put" => "put",
            "patch" => "patch",
            "delete" => "delete",
            "_uri" => "*",
            _ => continue,
        };
        if let Some(path) = dart_literal(&text[i + 1..]) {
            out.push((method.to_owned(), path));
        }
    }
    out
}

/// Text up to the closing quote, skipping `${...}` interpolations (which may contain quotes).
fn dart_literal(s: &str) -> Option<String> {
    let mut depth = 0usize;
    let mut chars = s.char_indices().peekable();
    while let Some((i, c)) = chars.next() {
        match c {
            '$' if chars.peek().is_some_and(|(_, n)| *n == '{') => {
                depth += 1;
                chars.next();
            }
            '}' if depth > 0 => depth -= 1,
            '\'' if depth == 0 => return Some(s[..i].to_owned()),
            '\n' => return None,
            _ => {}
        }
    }
    None
}

/// Spec-shaped segments: any `$` interpolation becomes `{}`, which matches any `{param}`.
fn normalize_dart(path: &str) -> Vec<String> {
    let path = path.split('?').next().unwrap_or(path);
    path.split('/')
        .skip(1)
        .map(|s| if s.contains('$') { "{}".to_owned() } else { s.to_owned() })
        .collect()
}

fn segments_match(spec_path: &str, dart: &[String]) -> bool {
    let spec: Vec<&str> = spec_path.split('/').skip(1).collect();
    spec.len() == dart.len() && spec.iter().zip(dart).all(|(s, d)| s.starts_with('{') || d == "{}" || s == d)
}

fn dart_files(dir: &Path, out: &mut Vec<PathBuf>) {
    let Ok(entries) = fs::read_dir(dir) else { return };
    for e in entries.flatten() {
        let p = e.path();
        if p.is_dir() {
            if !matches!(
                p.file_name().and_then(|n| n.to_str()),
                Some("build" | ".dart_tool" | "test" | "integration_test")
            ) {
                dart_files(&p, out);
            }
        } else if p.extension().is_some_and(|x| x == "dart") {
            out.push(p);
        }
    }
}

/// The apps and shared packages must only call routes the spec documents, with a matching method.
#[test]
fn flutter_clients_call_only_documented_routes() {
    let root = manifest().join("../../../app");
    let mut files = Vec::new();
    for group in ["apps", "packages"] {
        let Ok(entries) = fs::read_dir(root.join(group)) else {
            panic!("app/{group} missing")
        };
        for e in entries.flatten() {
            dart_files(&e.path().join("lib"), &mut files);
        }
    }
    assert!(files.len() > 20, "found the Dart sources ({} files)", files.len());
    let spec = spec();
    let ops: Vec<(String, String)> = spec_ops(&spec).into_iter().map(|(m, p, _)| (m, p)).collect();
    let mut drift = Vec::new();
    let mut seen = 0usize;
    for f in &files {
        let text = fs::read_to_string(f).expect("read dart");
        for (method, path) in dart_call_sites(&text) {
            seen += 1;
            let segs = normalize_dart(&path);
            let ok = ops
                .iter()
                .any(|(m, sp)| (method == "*" || *m == method) && sp.starts_with("/v1/") && segments_match(sp, &segs_v1(&segs)));
            if !ok {
                drift.push(format!("{}: {method} {path}", f.strip_prefix(&root).unwrap_or(f).display()));
            }
        }
    }
    assert!(seen > 50, "found call sites ({seen})");
    assert!(drift.is_empty(), "Flutter calls with no matching OpenAPI operation:\n{}", drift.join("\n"));
}

/// Dart paths are relative to `/v1`; prepend it to the segment list.
fn segs_v1(segs: &[String]) -> Vec<String> {
    std::iter::once("v1".to_owned()).chain(segs.iter().cloned()).collect()
}

#[test]
fn dart_literal_handles_interpolation_with_quotes() {
    assert_eq!(dart_literal("/bookings/${b['id']}/cancel', x)").as_deref(), Some("/bookings/${b['id']}/cancel"));
    assert_eq!(dart_literal("/a/$id'").as_deref(), Some("/a/$id"));
    assert_eq!(dart_literal("/unterminated\n").as_deref(), None);
}

#[test]
fn dart_call_sites_find_method_and_path() {
    let sites = dart_call_sites("final r = await api.get('/services');\n  await api.post(\n    '/checkouts/$id/confirm',\n    body);");
    assert_eq!(
        sites,
        vec![("get".into(), "/services".into()), ("post".into(), "/checkouts/$id/confirm".into())]
    );
}
