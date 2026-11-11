"""Static checks for the native store builds (customer, partner). No Mac or device needed.

  python -I scripts/ci/check-native.py     # exit 1 on any failed check

Console ships only as web (website image), so it has no native store build to check.
"""
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
APPS = REPO / "app" / "apps"
NATIVE_APPS = ["customer", "partner"]
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
KAKAO_AUTH_ACTIVITY = "com.kakao.sdk.flutter.auth.AuthCodeHandlerActivity"
NAVER_SCHEME = "malkkeumnaver"
PASSED = [0]
FAILED = []


def check(ok, what):
    if ok:
        PASSED[0] += 1
    else:
        FAILED.append(what)


# --- OpenStep ASCII plist (project.pbxproj); plistlib cannot read it -------------------------

_TOKEN = re.compile(r'\s+|/\*.*?\*/|//[^\n]*|"(?:\\.|[^"\\])*"|[{}();,=]|[^\s{}();,="]+', re.S)
_PUNCT = {"{", "}", "(", ")", ";", ",", "="}


def tokenize(text):
    pos, out = 0, []
    while pos < len(text):
        m = _TOKEN.match(text, pos)
        if not m:
            raise ValueError(f"unexpected character {text[pos]!r} at offset {pos}")
        tok = m.group(0)
        pos = m.end()
        if not (tok.isspace() or tok.startswith(("/*", "//"))):
            out.append(tok)
    return out


class _Parser:
    def __init__(self, toks):
        self.toks, self.i = toks, 0

    def peek(self):
        if self.i >= len(self.toks):
            raise ValueError("unexpected end of file (unbalanced braces or parens?)")
        return self.toks[self.i]

    def take(self, expect=None):
        tok = self.peek()
        if expect is not None and tok != expect:
            raise ValueError(f"expected {expect!r}, got {tok!r} (token {self.i})")
        self.i += 1
        return tok

    def value(self):
        tok = self.take()
        if tok == "{":
            return self.mapping()
        if tok == "(":
            return self.sequence()
        if tok in _PUNCT:
            raise ValueError(f"unexpected {tok!r} (token {self.i})")
        return _unquote(tok)

    def mapping(self):
        out = {}
        while self.peek() != "}":
            key = _unquote(self.take())
            self.take("=")
            out[key] = self.value()
            self.take(";")
        self.take("}")
        return out

    def sequence(self):
        out = []
        while self.peek() != ")":
            out.append(self.value())
            if self.peek() == ",":
                self.take()
        self.take(")")
        return out


def _unquote(tok):
    return re.sub(r"\\(.)", r"\1", tok[1:-1]) if tok.startswith('"') else tok


def load_pbxproj(path):
    toks = tokenize(path.read_text(encoding="utf-8"))
    parser = _Parser(toks)
    root = parser.value()
    if parser.i != len(toks):
        raise ValueError("trailing tokens after the root object")
    return root["objects"]


# --- iOS -------------------------------------------------------------------------------------

def plist(path):
    with path.open("rb") as f:
        return plistlib.load(f)


def check_info_plist(app, ios):
    info = plist(ios / "Runner" / "Info.plist")
    schemes = {s for t in info.get("CFBundleURLTypes", []) for s in t.get("CFBundleURLSchemes", [])}
    for want in ["$(KAKAO_URL_SCHEME)", "$(GOOGLE_REVERSED_CLIENT_ID)", NAVER_SCHEME]:
        check(want in schemes, f"{app} Info.plist: CFBundleURLSchemes lacks {want}")
    queries = set(info.get("LSApplicationQueriesSchemes", []))
    for want in ["kakaokompassauth", "kakaolink", "kakaoplus", "naversearchapp", "naversearchthirdlogin"]:
        check(want in queries, f"{app} Info.plist: LSApplicationQueriesSchemes lacks {want}")
    check(info.get("GIDClientID") == "$(GOOGLE_IOS_CLIENT_ID)", f"{app} Info.plist: GIDClientID")
    check("remote-notification" in info.get("UIBackgroundModes", []), f"{app} Info.plist: UIBackgroundModes lacks remote-notification")
    check(info.get("ITSAppUsesNonExemptEncryption") is False, f"{app} Info.plist: ITSAppUsesNonExemptEncryption must be false")
    for key in ["NSCameraUsageDescription", "NSPhotoLibraryUsageDescription"]:
        check(str(info.get(key, "")).strip() != "", f"{app} Info.plist: {key} empty")
    check(info.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)", f"{app} Info.plist: CFBundleIdentifier")
    return info


def check_naver_dart(app, info):
    dart = (REPO / "app" / "packages" / "core" / "lib" / "src" / "social_native_io.dart").read_text(encoding="utf-8")
    m = re.search(r"_naverUrlScheme = '([^']+)'", dart)
    check(m is not None and m.group(1) == NAVER_SCHEME, "social_native_io.dart: _naverUrlScheme must be malkkeumnaver")
    check(NAVER_SCHEME in {s for t in info.get("CFBundleURLTypes", []) for s in t.get("CFBundleURLSchemes", [])},
          f"{app}: Naver callback scheme missing from Info.plist")


def check_xcconfig(app, ios):
    for name in ["Debug", "Release"]:
        text = (ios / "Flutter" / f"{name}.xcconfig").read_text(encoding="utf-8")
        inc = text.find('#include? "Keys.xcconfig"')
        keys = ["KAKAO_URL_SCHEME", "GOOGLE_IOS_CLIENT_ID", "GOOGLE_REVERSED_CLIENT_ID"]
        defaults = [text.find(k + " =") for k in keys]
        check(inc >= 0 and all(0 <= d < inc for d in defaults),
              f"{app} {name}.xcconfig: defaults must come before the optional #include? Keys.xcconfig")
    writer = (REPO / "scripts" / "ci" / "native-keys.sh").read_text(encoding="utf-8")
    check('KAKAO_URL_SCHEME = kakao${KAKAO_NATIVE_KEY' in writer,
          "native-keys.sh: KAKAO_URL_SCHEME must include the kakao prefix (Info.plist uses it as-is)")


def check_entitlements_and_privacy(app, ios):
    ent = plist(ios / "Runner" / "Runner.entitlements")
    check(ent.get("aps-environment") == "production", f"{app} Runner.entitlements: aps-environment must be production")
    check("Default" in ent.get("com.apple.developer.applesignin", []),
          f"{app} Runner.entitlements: Sign in with Apple entitlement missing")
    priv = plist(ios / "Runner" / "PrivacyInfo.xcprivacy")
    check(priv.get("NSPrivacyTracking") is False, f"{app} PrivacyInfo: NSPrivacyTracking must be false")
    apis = {a.get("NSPrivacyAccessedAPIType"): a.get("NSPrivacyAccessedAPITypeReasons", [])
            for a in priv.get("NSPrivacyAccessedAPITypes", [])}
    check("CA92.1" in apis.get("NSPrivacyAccessedAPICategoryUserDefaults", []), f"{app} PrivacyInfo: UserDefaults CA92.1")
    check("C617.1" in apis.get("NSPrivacyAccessedAPICategoryFileTimestamp", []), f"{app} PrivacyInfo: FileTimestamp C617.1")


def check_pbxproj(app, ios):
    objs = load_pbxproj(ios / "Runner.xcodeproj" / "project.pbxproj")
    target = next((o for o in objs.values() if o.get("isa") == "PBXNativeTarget" and o.get("name") == "Runner"), None)
    check(target is not None, f"{app} pbxproj: Runner target not found")
    if target is None:
        return
    configs = [objs[i] for i in objs[target["buildConfigurationList"]]["buildConfigurations"]]
    check(sorted(c["name"] for c in configs) == ["Debug", "Profile", "Release"], f"{app} pbxproj: Runner configs")
    for c in configs:
        s = c["buildSettings"]
        check(s.get("CODE_SIGN_ENTITLEMENTS") == "Runner/Runner.entitlements",
              f"{app} pbxproj: {c['name']} lacks CODE_SIGN_ENTITLEMENTS")
        check(s.get("INFOPLIST_FILE") == "Runner/Info.plist", f"{app} pbxproj: {c['name']} INFOPLIST_FILE")
    bundled = {objs[objs[f]["fileRef"]].get("path")
               for p in target["buildPhases"] if objs[p].get("isa") == "PBXResourcesBuildPhase"
               for f in objs[p]["files"]}
    check("PrivacyInfo.xcprivacy" in bundled, f"{app} pbxproj: PrivacyInfo.xcprivacy not in Copy Bundle Resources")
    group = next((o for o in objs.values() if o.get("isa") == "PBXGroup" and o.get("path") == "Runner"), {})
    in_group = {objs[c].get("path") for c in group.get("children", [])}
    for want in ["Info.plist", "Runner.entitlements", "PrivacyInfo.xcprivacy"]:
        check(want in in_group, f"{app} pbxproj: {want} missing from the Runner group")


def check_ios(app):
    ios = APPS / app / "ios"
    info = check_info_plist(app, ios)
    check_naver_dart(app, info)
    check_xcconfig(app, ios)
    check_entitlements_and_privacy(app, ios)
    check_pbxproj(app, ios)


# --- Android ---------------------------------------------------------------------------------

def check_android(app):
    android = APPS / app / "android"
    gradle = (android / "app" / "build.gradle.kts").read_text(encoding="utf-8")
    root = ET.parse(android / "app" / "src" / "main" / "AndroidManifest.xml").getroot()
    perms = {e.get(ANDROID_NS + "name") for e in root.iter("uses-permission")}
    for want in ["android.permission.INTERNET", "android.permission.POST_NOTIFICATIONS"]:
        check(want in perms, f"{app} AndroidManifest: {want} missing")
    kakao = [a for a in root.iter("activity") if a.get(ANDROID_NS + "name") == KAKAO_AUTH_ACTIVITY]
    datas = [d.attrib for a in kakao for f in a.iter("intent-filter") for d in f.iter("data")]
    check(any(d.get(ANDROID_NS + "scheme") == "kakao${kakaoNativeKey}" and d.get(ANDROID_NS + "host") == "oauth"
              for d in datas), f"{app} AndroidManifest: Kakao AuthCodeHandlerActivity scheme kakao${{kakaoNativeKey}}")
    naver = [d.attrib for a in root.iter("activity") if a.get(ANDROID_NS + "name") == "com.linusu.flutter_web_auth_2.CallbackActivity"
             for f in a.iter("intent-filter") for d in f.iter("data")]
    check(any(d.get(ANDROID_NS + "scheme") == "malkkeumnaver" for d in naver),
          f"{app} AndroidManifest: flutter_web_auth_2 CallbackActivity for malkkeumnaver (Naver login)")
    check('manifestPlaceholders["kakaoNativeKey"]' in gradle, f"{app} build.gradle.kts: kakaoNativeKey placeholder")
    check('file("google-services.json").exists()' in gradle and 'apply(plugin = "com.google.gms.google-services")' in gradle,
          f"{app} build.gradle.kts: google-services plugin must be conditional")
    check("com.google.gms.google-services" in (android / "settings.gradle.kts").read_text(encoding="utf-8"),
          f"{app} settings.gradle.kts: google-services plugin not declared")
    m = re.search(r"targetSdk = (\d+)", gradle)
    check(m is not None and int(m.group(1)) >= 36, f"{app} build.gradle.kts: targetSdk must be >= 36 (Play rule)")
    for env in ["CM_KEYSTORE_PATH", "CM_KEYSTORE_PASSWORD", "CM_KEY_ALIAS", "CM_KEY_PASSWORD"]:
        check(f'"{env}"' in gradle, f"{app} build.gradle.kts: release signing does not read {env}")
    check(not re.search(r'(storePassword|keyPassword|keyAlias)\s*=\s*"', gradle), f"{app} build.gradle.kts: literal signing secret")
    check('getByName("debug")' in gradle, f"{app} build.gradle.kts: debug-signing fallback removed")


# --- Secrets stay out of git, CI wiring ------------------------------------------------------

def check_gitignore(app):
    text = "\n".join((p).read_text(encoding="utf-8") for p in [
        REPO / "app" / ".gitignore", APPS / app / ".gitignore", APPS / app / "android" / ".gitignore"] if p.exists())
    for pat in ["keys.json", "ios/Flutter/Keys.xcconfig", "android/app/google-services.json",
                "ios/Runner/GoogleService-Info.plist", "key.properties"]:
        check(re.search(rf"^{re.escape(pat)}$", text, re.M) is not None, f"{app} .gitignore lacks {pat}")


def check_ci():
    cm = (REPO / "codemagic.yaml").read_text(encoding="utf-8")
    first_build = cm.find("flutter build")
    check(0 <= cm.find("check-native.py") < first_build, "codemagic.yaml: check-native.py must run before flutter build")
    ci = (REPO / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    m = re.search(r"^  native:\n(.*?)(?=^  [\w-]+:\s*$|\Z)", ci, re.S | re.M)
    check(m is not None, "ci.yml: native job missing")
    job = m.group(1) if m else ""
    check("check-native.py" in job, "ci.yml: native job must run check-native.py")
    uses = re.findall(r"uses:\s*(\S+)", job)
    check(bool(uses) and all(re.search(r"@[0-9a-f]{40}$", u) for u in uses), "ci.yml: native job actions must be SHA-pinned")


def main():
    failures_before = []
    for app in NATIVE_APPS:
        try:
            check_ios(app)
            check_android(app)
            check_gitignore(app)
        except (OSError, ValueError, KeyError, ET.ParseError, plistlib.InvalidFileException) as e:
            failures_before.append(f"{app}: {type(e).__name__}: {e}")
    try:
        check_ci()
    except (OSError, ValueError) as e:
        failures_before.append(f"ci: {type(e).__name__}: {e}")
    for line in failures_before + FAILED:
        print("FAIL", line)
    print(f"native checks: {PASSED[0]} passed, {len(FAILED) + len(failures_before)} failed")
    return 1 if FAILED or failures_before else 0


if __name__ == "__main__":
    sys.exit(main())
