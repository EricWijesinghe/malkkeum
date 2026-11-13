"""Static checks for the native store builds (customer, partner). No Mac or device needed.

  python -I scripts/ci/check-native.py     # exit 1 on any failed check
  python -I scripts/ci/check-native.py --aab <app.aab|app.apk> --manifest <merged AndroidManifest.xml>
  python -I scripts/ci/check-native.py --ipa <Runner.ipa>      # after flutter build ipa (Codemagic)

Console ships only as web (website image), so it has no native store build to check.
"""
import plistlib
import re
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

REPO = Path(__file__).resolve().parents[2]
APPS = REPO / "app" / "apps"
NATIVE_APPS = ["customer", "partner"]
ANDROID_NS = "{http://schemas.android.com/apk/res/android}"
KAKAO_AUTH_ACTIVITY = "com.kakao.sdk.flutter.auth.AuthCodeHandlerActivity"
NAVER_SCHEME = "malkkeumnaver"  # legacy iOS < 17.4 only
NAVER_PATH = "/auth/naver/callback"
# PortOne appScheme: ISP / app-card apps reopen the customer app with it after authenticating (iOS only;
# on Android they return by finishing, and a singleTop MainActivity would start a second copy instead).
PAY_APP_SCHEME = "malkkeumpay"
PAY_APPS = {"customer"}
CORE_WEBVIEW = APPS.parent / "packages" / "core" / "lib" / "src" / "portone_webview.dart"
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
    for want in PAY_SCHEMES:
        check(want in queries, f"{app} Info.plist: LSApplicationQueriesSchemes lacks card/wallet app scheme {want} (PortOne WebView)")
    if app in PAY_APPS:
        check(PAY_APP_SCHEME in schemes, f"{app} Info.plist: CFBundleURLSchemes lacks the PortOne appScheme {PAY_APP_SCHEME}")
        check(info.get("FlutterDeepLinkingEnabled") is False,
              f"{app} Info.plist: FlutterDeepLinkingEnabled must be false, or the {PAY_APP_SCHEME}:// return pushes a route over the payment")
    check(len(info.get("LSApplicationQueriesSchemes", [])) <= 50, f"{app} Info.plist: iOS honours at most 50 LSApplicationQueriesSchemes")
    for key in ["CFBundleDisplayName", "CFBundleName"]:
        value = str(info.get(key, "")).strip()
        check(value != "" and value != app, f"{app} Info.plist: {key} must be the store name, not the folder name")
    check(not any(k.startswith("NSLocationAlways") for k in info),
          f"{app} Info.plist: no Always-location text; geolocator_apple is built with BYPASS_PERMISSION_LOCATION_ALWAYS=1")
    check(info.get("GIDClientID") == "$(GOOGLE_IOS_CLIENT_ID)", f"{app} Info.plist: GIDClientID")
    check("remote-notification" in info.get("UIBackgroundModes", []), f"{app} Info.plist: UIBackgroundModes lacks remote-notification")
    check(info.get("ITSAppUsesNonExemptEncryption") is False, f"{app} Info.plist: ITSAppUsesNonExemptEncryption must be false")
    for key in ["NSCameraUsageDescription", "NSPhotoLibraryUsageDescription"]:
        check(str(info.get(key, "")).strip() != "", f"{app} Info.plist: {key} empty")
    has_location = str(info.get(LOCATION_USAGE_KEY, "")).strip() != ""
    check(has_location == (app in LOCATION_APPS), f"{app} Info.plist: {LOCATION_USAGE_KEY} must be set only for {sorted(LOCATION_APPS)}")
    check(info.get("CFBundleIdentifier") == "$(PRODUCT_BUNDLE_IDENTIFIER)", f"{app} Info.plist: CFBundleIdentifier")
    return info


def check_naver_dart(app):
    lib = REPO / "app" / "packages" / "core" / "lib" / "src"
    native = (lib / "social_native_io.dart").read_text(encoding="utf-8")
    m = re.search(r"_naverLegacyScheme = '([^']+)'", native)
    check(m is not None and m.group(1) == NAVER_SCHEME, "social_native_io.dart: _naverLegacyScheme must be malkkeumnaver")
    check(f"const _naverPath = '{NAVER_PATH}'" in native, "social_native_io.dart: _naverPath must be the App Link path")
    check("Uri.https(SocialKeys.appLinkHost, _naverPath)" in native, "social_native_io.dart: Naver redirect must be the https App Link")
    check("naverUsesAppLink(" in native and "Platform.operatingSystemVersion" in native,
          "social_native_io.dart: Naver must choose https by iOS version")
    auth = (lib / "social_auth.dart").read_text(encoding="utf-8")
    check("String.fromEnvironment('APP_LINK_DOMAIN')" in auth, "social_auth.dart: SocialKeys.appLinkHost missing")
    check("has('NAVER_CLIENT_ID') && has('APP_LINK_DOMAIN')" in auth, "social_auth.dart: Naver must require APP_LINK_DOMAIN")


def check_xcconfig(app, ios):
    for name in ["Debug", "Release"]:
        text = (ios / "Flutter" / f"{name}.xcconfig").read_text(encoding="utf-8")
        inc = text.find('#include? "Keys.xcconfig"')
        keys = ["KAKAO_URL_SCHEME", "GOOGLE_IOS_CLIENT_ID", "GOOGLE_REVERSED_CLIENT_ID", "APP_LINK_HOST"]
        defaults = [text.find(k + " =") for k in keys]
        check(inc >= 0 and all(0 <= d < inc for d in defaults),
              f"{app} {name}.xcconfig: defaults must come before the optional #include? Keys.xcconfig")
    writer = (REPO / "scripts" / "ci" / "native-keys.sh").read_text(encoding="utf-8")
    check('APP_LINK_HOST = ${APP_LINK_DOMAIN:-' in writer, "native-keys.sh: Keys.xcconfig must set APP_LINK_HOST")
    check('"APP_LINK_DOMAIN"' in writer, "native-keys.sh: APP_LINK_DOMAIN must be passed as a dart-define")
    check('KAKAO_URL_SCHEME = kakao${KAKAO_NATIVE_KEY' in writer,
          "native-keys.sh: KAKAO_URL_SCHEME must include the kakao prefix (Info.plist uses it as-is)")


def check_entitlements_and_privacy(app, ios):
    ent = plist(ios / "Runner" / "Runner.entitlements")
    check(ent.get("aps-environment") == "production", f"{app} Runner.entitlements: aps-environment must be production")
    check("Default" in ent.get("com.apple.developer.applesignin", []),
          f"{app} Runner.entitlements: Sign in with Apple entitlement missing")
    check("applinks:$(APP_LINK_HOST)" in ent.get("com.apple.developer.associated-domains", []),
          f"{app} Runner.entitlements: associated-domains applinks:$(APP_LINK_HOST) missing (Naver Universal Link)")
    # ASWebAuthenticationSession.Callback.https (iOS 17.4+) is verified through the webcredentials service, not applinks.
    check("webcredentials:$(APP_LINK_HOST)" in ent.get("com.apple.developer.associated-domains", []),
          f"{app} Runner.entitlements: associated-domains webcredentials:$(APP_LINK_HOST) missing (Naver https callback)")
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
    for c in configs:
        check(c["buildSettings"].get("PRODUCT_BUNDLE_IDENTIFIER") == f"com.malkkeum.{app}",
              f"{app} pbxproj: {c['name']} PRODUCT_BUNDLE_IDENTIFIER must be com.malkkeum.{app}")
    # firebase_core/messaging 5/17, google_sign_in_ios and image_picker_ios need iOS 15; SwiftPM plugins follow this value.
    targets = [o["buildSettings"]["IPHONEOS_DEPLOYMENT_TARGET"] for o in objs.values()
               if o.get("isa") == "XCBuildConfiguration" and "IPHONEOS_DEPLOYMENT_TARGET" in o.get("buildSettings", {})]
    check(bool(targets) and all(float(v) >= IOS_MIN for v in targets),
          f"{app} pbxproj: IPHONEOS_DEPLOYMENT_TARGET must be >= {IOS_MIN} in every configuration, found {sorted(set(targets))}")
    # Project-level settings are inherited by the target: every value that is set must be iPhone-only.
    families = {o["buildSettings"]["TARGETED_DEVICE_FAMILY"] for o in objs.values()
                if o.get("isa") == "XCBuildConfiguration" and "TARGETED_DEVICE_FAMILY" in o.get("buildSettings", {})}
    check(families == {"1"}, f"{app} pbxproj: TARGETED_DEVICE_FAMILY must be iPhone-only (1), found {sorted(families)}")
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
    check_info_plist(app, ios)
    check_naver_dart(app)
    check_xcconfig(app, ios)
    check_entitlements_and_privacy(app, ios)
    check_pbxproj(app, ios)
    check_ios_localizations(app, ios)
    check_icons(app, ios)
    check_privacy_types(app, plist(ios / "Runner" / "PrivacyInfo.xcprivacy"))


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
    naver = [(f, d.attrib) for a in root.iter("activity") if a.get(ANDROID_NS + "name") == "com.linusu.flutter_web_auth_2.CallbackActivity"
             for f in a.iter("intent-filter") for d in f.iter("data")]
    check(any(f.get(ANDROID_NS + "autoVerify") == "true" and d.get(ANDROID_NS + "scheme") == "https"
              and d.get(ANDROID_NS + "host") == "${appLinkHost}" and d.get(ANDROID_NS + "path") == NAVER_PATH
              for f, d in naver),
          f"{app} AndroidManifest: CallbackActivity needs an autoVerify https App Link ${{appLinkHost}}{NAVER_PATH}")
    check(not any(d.get(ANDROID_NS + "scheme") == NAVER_SCHEME for _, d in naver),
          f"{app} AndroidManifest: the malkkeumnaver custom scheme must not be registered on Android")
    check(not any(d.get(ANDROID_NS + "scheme") == PAY_APP_SCHEME for d in root.iter("data")),
          f"{app} AndroidManifest: {PAY_APP_SCHEME} must not be registered on Android (card apps return by finishing)")
    check('manifestPlaceholders["kakaoNativeKey"]' in gradle, f"{app} build.gradle.kts: kakaoNativeKey placeholder")
    check('file("google-services.json").exists()' in gradle and 'apply(plugin = "com.google.gms.google-services")' in gradle,
          f"{app} build.gradle.kts: google-services plugin must be conditional")
    check("com.google.gms.google-services" in (android / "settings.gradle.kts").read_text(encoding="utf-8"),
          f"{app} settings.gradle.kts: google-services plugin not declared")
    m = re.search(r"targetSdk = (\d+)", gradle)
    check(m is not None and int(m.group(1)) >= 36, f"{app} build.gradle.kts: targetSdk must be >= 36 (Play rule)")
    check('manifestPlaceholders["appLinkHost"]' in gradle, f"{app} build.gradle.kts: appLinkHost placeholder")
    for env in ["CM_KEYSTORE_PATH", "CM_KEYSTORE_PASSWORD", "CM_KEY_ALIAS", "CM_KEY_PASSWORD"]:
        check(f'"{env}"' in gradle, f"{app} build.gradle.kts: release signing does not read {env}")
    check(not re.search(r'(storePassword|keyPassword|keyAlias)\s*=\s*"', gradle), f"{app} build.gradle.kts: literal signing secret")
    check('getByName("debug")' in gradle, f"{app} build.gradle.kts: debug-signing fallback removed")
    check_android_platform(app, android, root, gradle)


def check_android_platform(app, android, root, gradle):
    """Play target-API behaviour: predictive back, edge-to-edge, 16 KB pages, no foreground service."""
    application = root.find("application")
    check(application is not None and application.get(ANDROID_NS + "enableOnBackInvokedCallback") == "true",
          f"{app} AndroidManifest: android:enableOnBackInvokedCallback=\"true\" missing (predictive back)")
    m = re.search(r"compileSdk = (\S+)", gradle)
    check(m is not None and (m.group(1) == "flutter.compileSdkVersion" or (m.group(1).isdigit() and int(m.group(1)) >= MIN_SDK_LEVEL)),
          f"{app} build.gradle.kts: compileSdk must be flutter.compileSdkVersion or >= {MIN_SDK_LEVEL}")
    # 16 KB pages: AGP >= 8.5.1 zip-aligns uncompressed .so files and NDK r28+ links them 16 KB aligned.
    check("ndkVersion = flutter.ndkVersion" in gradle, f"{app} build.gradle.kts: ndkVersion must follow the Flutter SDK (NDK r28+, 16 KB pages)")
    check("useLegacyPackaging = true" not in gradle, f"{app} build.gradle.kts: useLegacyPackaging breaks 16 KB page alignment")
    m = re.search(r'id\("com\.android\.application"\) version "(\d+)\.(\d+)\.(\d+)"', (android / "settings.gradle.kts").read_text(encoding="utf-8"))
    check(m is not None and tuple(map(int, m.groups())) >= MIN_AGP, f"{app} settings.gradle.kts: AGP must be >= 8.5.1 (16 KB pages)")
    check('ndk { debugSymbolLevel = "FULL" }' in gradle, f"{app} build.gradle.kts: release must upload native debug symbols")
    check(not any(s.get(ANDROID_NS + "foregroundServiceType") for s in root.iter("service")),
          f"{app} AndroidManifest: no foreground service is declared to Play; remove foregroundServiceType")
    res = "".join(p.read_text(encoding="utf-8") for p in (android / "app" / "src" / "main" / "res").rglob("*.xml"))
    check("windowOptOutEdgeToEdgeEnforcement" not in res, f"{app} res: edge-to-edge opt-out is ignored at targetSdk 36; remove it")


# --- Secrets stay out of git, CI wiring ------------------------------------------------------

# --- Store submission rules: localized permission text, icons, collected data, Play extras ---

IOS_MIN = 15.0
# Card, wallet and identity apps the PortOne page hands to the OS (portone_webview.dart). iOS only needs these for
# canOpenURL; PortOne's iOS guide lists them, so a later canLaunchUrl check does not silently fail.
PAY_SCHEMES = ["ispmobile", "kftc-bankpay", "kakaotalk", "supertoss", "payco", "shinhan-sr-ansimclick", "smhyundaiansimclick",
               "hdcardappcardansimclick", "lottesmartpay", "lotteappcard", "mpocket.online.ios", "kb-acp", "nhappcardansimclick",
               "nonghyupcardansimclick", "hanawalletmembers", "cloudpay", "newsmartpib", "citimobileapp",
               "tauthlink", "ktauthexternalcall", "upluscorporation"]
# i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
IOS_LANGS = ["en", "ko"]
USAGE_KEYS = ["NSCameraUsageDescription", "NSPhotoLibraryUsageDescription"]
BANNED_PERMS = ["android.permission.READ_MEDIA_IMAGES", "android.permission.READ_MEDIA_VIDEO",
                "android.permission.READ_MEDIA_VISUAL_USER_SELECTED", "android.permission.CAMERA",
                "android.permission.READ_EXTERNAL_STORAGE", "android.permission.WRITE_EXTERNAL_STORAGE",
                "android.permission.FOREGROUND_SERVICE", "android.permission.ACCESS_BACKGROUND_LOCATION",
                "com.google.android.gms.permission.AD_ID"]
# Everything the merged manifest (app + plugins) may request, besides location for LOCATION_APPS.
# All are install-time ("normal") permissions: FCM (network state, wake lock, c2dm), notifications (vibrate),
# flutter_secure_storage (biometric; declared by the plugin, never prompted because no key asks for authentication).
MERGED_PERMS = {"android.permission.INTERNET", "android.permission.POST_NOTIFICATIONS", "android.permission.ACCESS_NETWORK_STATE",
                "android.permission.WAKE_LOCK", "android.permission.VIBRATE", "com.google.android.c2dm.permission.RECEIVE",
                "android.permission.USE_BIOMETRIC", "android.permission.USE_FINGERPRINT"}
# geolocator_android always declares this service. It can never run in the foreground here: the merged manifest
# has no FOREGROUND_SERVICE* permission (checked), so Play asks for no foreground service declaration.
PLUGIN_FGS = {"com.baseflow.geolocator.GeolocatorLocationService"}
MIN_SDK_LEVEL = 36
MIN_AGP = (8, 5, 1)
T = "NSPrivacyCollectedDataType"
# Must match docs/store/app-privacy.md: type -> (linked to the user, purposes that must be listed).
PRIVACY_WANT = {
    "customer": {"PhoneNumber": (True, {"AppFunctionality", "DeveloperAdvertising"}),
                 "DeviceID": (True, {"AppFunctionality", "Analytics", "DeveloperAdvertising"}),
                 "ProductInteraction": (False, {"Analytics"}),
                 "CustomerSupport": (True, {"AppFunctionality"})},
    "partner": {"EmailAddress": (True, {"AppFunctionality"}),
                "CustomerSupport": (True, {"AppFunctionality"})},
}
GOOGLE_HOSTS = re.compile(r"google|gstatic|firebase|doubleclick", re.I)
# Foreground location: only the customer app ("use my current location" on the address form). Never background.
LOCATION_APPS = {"customer"}
LOCATION_PERMS = ["android.permission.ACCESS_COARSE_LOCATION", "android.permission.ACCESS_FINE_LOCATION"]
LOCATION_USAGE_KEY = "NSLocationWhenInUseUsageDescription"
ELF_LOAD = 1
PAGE_16KB = 0x4000


def check_ios_localizations(app, ios):
    proj = (ios / "Runner.xcodeproj" / "project.pbxproj").read_text(encoding="utf-8")
    regions = re.search(r"knownRegions = \((.*?)\);", proj, re.S).group(1)
    for lang in IOS_LANGS:
        path = ios / "Runner" / f"{lang}.lproj" / "InfoPlist.strings"
        text = path.read_text(encoding="utf-8") if path.exists() else ""
        check(all(f'"{k}" = "' in text for k in USAGE_KEYS), f"{app} {lang}.lproj/InfoPlist.strings: camera/photo text missing")
        check((f'"{LOCATION_USAGE_KEY}" = "' in text) == (app in LOCATION_APPS),
              f"{app} {lang}.lproj/InfoPlist.strings: location text must be present only for {sorted(LOCATION_APPS)}")
        check(re.search(rf"\b{re.escape(lang)},", regions) is not None, f"{app} pbxproj knownRegions lacks {lang}")
    check(proj.count("InfoPlist.strings in Resources */") >= 1 and "InfoPlist.strings */," in proj,
          f"{app} pbxproj: InfoPlist.strings variant group not wired into the Runner group and Resources phase")


def check_icons(app, ios):
    for png in (ios / "Runner" / "Assets.xcassets" / "AppIcon.appiconset").glob("*.png"):
        head = png.read_bytes()[:26]
        check(head[:8] == b"\x89PNG\r\n\x1a\n" and head[25:26] not in (b"\x04", b"\x06"),
              f"{app} {png.name}: app icon must be a PNG without alpha channel")


def check_privacy_types(app, priv):
    types = priv.get("NSPrivacyCollectedDataTypes", [])
    check(len(types) > 0, f"{app} PrivacyInfo: NSPrivacyCollectedDataTypes empty but the app collects personal data")
    check(all(t.get("NSPrivacyCollectedDataTypeTracking") is False for t in types), f"{app} PrivacyInfo: collected type marked as tracking")
    names = {t.get("NSPrivacyCollectedDataType") for t in types}
    check({"NSPrivacyCollectedDataTypePhoneNumber", "NSPrivacyCollectedDataTypeName"} <= names,
          f"{app} PrivacyInfo: phone and name must be declared")
    by = {t.get(T, "")[len(T):]: t for t in types}
    for name, (linked, purposes) in PRIVACY_WANT[app].items():
        got = by.get(name, {})
        have = {p[len(T + "Purpose"):] for p in got.get(T + "Purposes", [])}
        check(got.get(T + "Linked") is linked and purposes <= have,
              f"{app} PrivacyInfo: {name} must be declared with linked={linked} and purposes {sorted(purposes)}")


def check_camera_and_analytics():
    dart = "".join(p.read_text(encoding="utf-8") for app in NATIVE_APPS for p in (APPS / app / "lib").rglob("*.dart"))
    rn = (REPO / "docs" / "store" / "review-notes.md").read_text(encoding="utf-8")
    # NSCameraUsageDescription stays even though the apps open the gallery only: image_picker_ios links
    # AVCaptureDevice, and App Store Connect rejects such a binary without the purpose string (ITMS-90683).
    check("ImageSource.camera" in dart or "NSCameraUsageDescription" in rn,
          "review-notes.md: must explain NSCameraUsageDescription while no screen opens the camera")
    main = (APPS / "customer" / "lib" / "main.dart").read_text(encoding="utf-8")
    check(re.search(r"\?\s*'ios'\s*:\s*'android'", main) is None, "customer main.dart: analytics must not label every non-iOS platform as android")


def check_pay_scheme():
    """The app passes the scheme Info.plist registers, and both hosted PortOne pages forward it."""
    dart = CORE_WEBVIEW.read_text(encoding="utf-8")
    check(f"const payAppScheme = '{PAY_APP_SCHEME}://';" in dart, f"core portone_webview.dart: payAppScheme must be {PAY_APP_SCHEME}://")
    for page in ["index.html", "billing.html"]:
        html = (REPO / "website" / "pay" / page).read_text(encoding="utf-8")
        check("req.appScheme = app" in html, f"website/pay/{page}: requestPayment/requestIssueBillingKey must pass appScheme")


def check_android_extras(app, android, root=None):
    if root is None:
        root = ET.parse(android / "app" / "src" / "main" / "AndroidManifest.xml").getroot()
    perms = {e.get(ANDROID_NS + "name") for e in root.iter("uses-permission")}
    for banned in BANNED_PERMS:
        check(banned not in perms, f"{app} AndroidManifest: {banned} not allowed (photo picker only; no camera, background location, foreground service or ad id)")
    check(not any(p.startswith("android.permission.FOREGROUND_SERVICE") for p in perms), f"{app} AndroidManifest: foreground service permission not allowed")
    for perm in LOCATION_PERMS:
        check((perm in perms) == (app in LOCATION_APPS), f"{app} AndroidManifest: {perm} must be declared only for {sorted(LOCATION_APPS)}")


def elf_16kb_failures(aab):
    """Names of arm64/x86_64 .so files in an AAB whose LOAD segments are not 16 KB aligned."""
    import struct
    import zipfile
    bad, count = [], 0
    with zipfile.ZipFile(aab) as z:
        for name in z.namelist():
            if not (name.startswith(("base/lib/", "lib/")) and name.endswith(".so")):  # AAB or APK
                continue
            data = z.read(name)
            if data[:4] != b"\x7fELF" or data[4] != 2:  # 32-bit ABIs are not subject to the rule
                continue
            count += 1
            phoff = struct.unpack_from("<Q", data, 0x20)[0]
            phentsize, phnum = struct.unpack_from("<HH", data, 0x36)
            for i in range(phnum):
                base = phoff + i * phentsize
                if struct.unpack_from("<I", data, base)[0] == ELF_LOAD:
                    if struct.unpack_from("<Q", data, base + 48)[0] < PAGE_16KB:
                        bad.append(name)
                        break
    return count, bad


def check_aab(aab):
    count, bad = elf_16kb_failures(aab)
    check(count > 0, f"{aab}: no 64-bit native libraries found (wrong bundle?)")
    for name in bad:
        check(False, f"{aab}: {name} is not 16 KB page aligned (Play requires it for targetSdk 35+)")


def check_merged_manifest(path):
    """The manifest Gradle merged from the app and every plugin (plain XML under build/app/intermediates/merged_manifests)."""
    root = ET.parse(path).getroot()
    app = root.get("package", "").rsplit(".", 1)[-1]
    check(app in NATIVE_APPS, f"{path}: package {root.get('package')} is not a store app")
    check_android_extras(app, None, root)
    perms = {e.get(ANDROID_NS + "name") for e in root.iter("uses-permission")}
    check("android.permission.POST_NOTIFICATIONS" in perms, f"{path}: POST_NOTIFICATIONS missing")
    allowed = MERGED_PERMS | (set(LOCATION_PERMS) if app in LOCATION_APPS else set()) | {f"com.malkkeum.{app}.DYNAMIC_RECEIVER_NOT_EXPORTED_PERMISSION"}
    for perm in sorted(perms - allowed):
        check(False, f"{path}: unexpected permission {perm} (a plugin added it; review, then remove it or extend MERGED_PERMS)")
    for s in root.iter("service"):
        check(not s.get(ANDROID_NS + "foregroundServiceType") or s.get(ANDROID_NS + "name") in PLUGIN_FGS,
              f"{path}: {s.get(ANDROID_NS + 'name')} declares a foreground service type")
    application = root.find("application")
    check(application is not None and application.get(ANDROID_NS + "enableOnBackInvokedCallback") == "true", f"{path}: predictive back not enabled")
    sdk = root.find("uses-sdk")
    check(sdk is not None and int(sdk.get(ANDROID_NS + "targetSdkVersion", "0")) >= MIN_SDK_LEVEL, f"{path}: targetSdkVersion must be >= {MIN_SDK_LEVEL}")


def check_store_docs():
    cm = (REPO / "codemagic.yaml").read_text(encoding="utf-8")
    builds = [ln for ln in cm.splitlines() if "flutter build " in ln]
    check(len(builds) == 4 and all("FCI_TAG" in ln for ln in builds),
          "codemagic.yaml: all four flutter build lines must take the version name from the tag (FCI_TAG)")
    # i18n-archive: extra languages archived in archive/i18n-extra-languages (see README to restore)
    for lang in ["ko", "en"]:
        check((REPO / "docs" / "store" / "release-notes" / f"{lang}.md").exists(), f"release notes template missing: {lang}")
    rn = (REPO / "docs" / "store" / "review-notes.md").read_text(encoding="utf-8")
    check("<REVIEW_PHONE>" in rn and "<REVIEW_CODE>" in rn, "review-notes.md: keep the phone and code as placeholders")
    check(re.search(r"010[-\s]?\d{4}[-\s]?\d{4}", rn) is None, "review-notes.md: real phone number committed")
    for doc in ["docs/store/data-safety.md", "website/privacy.html"]:
        check("Anthropic" in (REPO / doc).read_text(encoding="utf-8"), f"{doc}: must disclose the Anthropic AI processor")


def check_gitignore(app):
    text = "\n".join((p).read_text(encoding="utf-8") for p in [
        REPO / "app" / ".gitignore", APPS / app / ".gitignore", APPS / app / "android" / ".gitignore"] if p.exists())
    for pat in ["keys.json", "ios/Flutter/Keys.xcconfig", "android/app/google-services.json",
                "ios/Runner/GoogleService-Info.plist", "key.properties"]:
        check(re.search(rf"^{re.escape(pat)}$", text, re.M) is not None, f"{app} .gitignore lacks {pat}")


# --- Website: App Link fallback page and the API-served well-known files ---------------------

def check_web():
    page = (REPO / "website" / "auth" / "naver" / "callback.html").read_text(encoding="utf-8")
    check('name="referrer" content="no-referrer"' in page, "website/auth/naver/callback.html: must send no Referer")
    check("<script" not in page.lower(), "website/auth/naver/callback.html: no script may read the one-time code")
    caddy = (REPO / "deploy" / "Caddyfile").read_text(encoding="utf-8")
    m = re.search(r"@api path ([^\n]+)", caddy)
    api_paths = m.group(1).split() if m else []
    for want in ["/.well-known/assetlinks.json", "/.well-known/apple-app-site-association"]:
        check(want in api_paths, f"deploy/Caddyfile: {want} must be proxied to the API")
    api = (REPO / "backend" / "crates" / "api" / "src" / "app_links.rs").read_text(encoding="utf-8")
    check('"webcredentials"' in api, "backend app_links.rs: AASA needs a webcredentials section (ASWebAuthenticationSession https callback)")
    check('"/.well-known/assetlinks.json"' in api and '"/.well-known/apple-app-site-association"' in api,
          "backend app_links.rs: both well-known routes must exist")
    # Web builds self-host CanvasKit/skwasm, so the site CSP can stay free of Google hosts.
    files = [p for d in ["deploy", "scripts", ".github"] for p in (REPO / d).rglob("*") if p.is_file() and p != Path(__file__).resolve()]
    builds = [(p, ln) for p in files + [REPO / "codemagic.yaml"] for ln in p.read_text(encoding="utf-8", errors="ignore").splitlines()
              if re.search(r"flutter(\.bat)? build web", ln)]
    check(len(builds) >= 2, "no `flutter build web` line found (deploy/web.Dockerfile moved?)")
    for p, ln in builds:
        check("--no-web-resources-cdn" in ln, f"{p.relative_to(REPO).as_posix()}: flutter build web without --no-web-resources-cdn")
    csp = re.findall(r'Content-Security-Policy "([^"]*)"', caddy)
    check(len(csp) >= 1, "deploy/Caddyfile: Content-Security-Policy header missing")
    for value in csp:
        check(GOOGLE_HOSTS.search(value) is None, "deploy/Caddyfile: CSP must not allow Google hosts (web builds are self-contained)")
    compose = (REPO / "deploy" / "docker-compose.yml").read_text(encoding="utf-8")
    check("ANDROID_CERT_SHA256" in compose and "APPLE_TEAM_ID" in compose,
          "deploy/docker-compose.yml: API needs ANDROID_CERT_SHA256 and APPLE_TEAM_ID")


def check_codemagic_ios(cm):
    """Each iOS workflow signs and builds only its own app (the repo holds three Runner.xcodeproj)."""
    check(re.search(r"^\s+xcode: \d+\.\d+", cm, re.M) is not None, "codemagic.yaml: pin an Xcode version")
    for app in NATIVE_APPS:
        m = re.search(rf"^  {app}-ios:\n(.*?)(?=^  [\w-]+:\s*$|\Z)", cm, re.S | re.M)
        check(m is not None, f"codemagic.yaml: {app}-ios workflow missing")
        wf = m.group(1) if m else ""
        check(f"bundle_identifier: com.malkkeum.{app}" in wf, f"codemagic.yaml {app}-ios: ios_signing bundle_identifier")
        check("app_store_connect: malkkeum_asc" in wf, f"codemagic.yaml {app}-ios: App Store Connect integration malkkeum_asc")
        check(f"working_directory: app/apps/{app}\n        script: xcode-project use-profiles --project ios/Runner.xcodeproj" in wf,
              f"codemagic.yaml {app}-ios: use-profiles must target ios/Runner.xcodeproj of this app")
        check("--export-options-plist=/Users/builder/export_options.plist" in wf, f"codemagic.yaml {app}-ios: export options plist")
        check("check-native.py --ipa" in wf.split("flutter build ipa")[-1], f"codemagic.yaml {app}-ios: check the built ipa")
        check(("BYPASS_PERMISSION_LOCATION_ALWAYS" in wf) == (app in LOCATION_APPS),
              f"codemagic.yaml {app}-ios: BYPASS_PERMISSION_LOCATION_ALWAYS belongs to the geolocator app only")
        check("submit_to_app_store: false" in wf, f"codemagic.yaml {app}-ios: nothing goes to App Review automatically")


def check_ci():
    cm = (REPO / "codemagic.yaml").read_text(encoding="utf-8")
    first_build = cm.find("flutter build")
    check(0 <= cm.find("check-native.py") < first_build, "codemagic.yaml: check-native.py must run before flutter build")
    check_codemagic_ios(cm)
    ci = (REPO / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    m = re.search(r"^  native:\n(.*?)(?=^  [\w-]+:\s*$|\Z)", ci, re.S | re.M)
    check(m is not None, "ci.yml: native job missing")
    job = m.group(1) if m else ""
    check("check-native.py" in job, "ci.yml: native job must run check-native.py")
    uses = re.findall(r"uses:\s*(\S+)", job)
    check(bool(uses) and all(re.search(r"@[0-9a-f]{40}$", u) for u in uses), "ci.yml: native job actions must be SHA-pinned")


def check_ipa(path):
    """The built .ipa: placeholders expanded, signing profile carries the capabilities, privacy manifest bundled."""
    with zipfile.ZipFile(path) as z:
        names = z.namelist()
        app = next((n for n in names if re.fullmatch(r"Payload/[^/]+\.app/Info\.plist", n)), None)
        check(app is not None, f"{path}: no Payload/*.app/Info.plist")
        if app is None:
            return
        root = app[: -len("Info.plist")]
        info = plistlib.loads(z.read(app))
        bid = info.get("CFBundleIdentifier", "")
        check(bid in {f"com.malkkeum.{a}" for a in NATIVE_APPS}, f"{path}: CFBundleIdentifier {bid!r}")
        check(float(str(info.get("MinimumOSVersion", "0")).split(".")[0]) >= IOS_MIN, f"{path}: MinimumOSVersion below {IOS_MIN}")
        check(re.fullmatch(r"\d+", str(info.get("CFBundleVersion", ""))) is not None, f"{path}: CFBundleVersion must be the rising integer build number")
        check(re.fullmatch(r"\d+\.\d+\.\d+", str(info.get("CFBundleShortVersionString", ""))) is not None, f"{path}: CFBundleShortVersionString must look like 1.2.3")
        check("$(" not in repr(info), f"{path}: Info.plist still holds an unexpanded $(VARIABLE)")
        check(not any(k.startswith("NSLocationAlways") for k in info), f"{path}: Always-location text present")
        check(root + "PrivacyInfo.xcprivacy" in names, f"{path}: PrivacyInfo.xcprivacy not bundled")
        prof = root + "embedded.mobileprovision"
        check(prof in names, f"{path}: embedded.mobileprovision missing (unsigned build?)")
        if prof in names:
            raw = z.read(prof)  # CMS-wrapped; the XML plist sits inside in the clear
            ent = plistlib.loads(raw[raw.index(b"<?xml"): raw.index(b"</plist>") + 8]).get("Entitlements", {})
            check(ent.get("aps-environment") == "production", f"{path}: profile lacks push (aps-environment=production): enable Push Notifications on the App ID")
            check("Default" in ent.get("com.apple.developer.applesignin", []), f"{path}: profile lacks Sign in with Apple: enable it on the App ID")
            check(bool(ent.get("com.apple.developer.associated-domains")), f"{path}: profile lacks Associated Domains: enable it on the App ID")
            check(ent.get("get-task-allow") is False, f"{path}: profile is a development profile (get-task-allow)")
        if root + "GoogleService-Info.plist" not in names:
            print(f"NOTE {path}: no GoogleService-Info.plist, so this build has push off")


def main():
    failures_before = []
    for app in NATIVE_APPS:
        try:
            check_ios(app)
            check_android(app)
            check_android_extras(app, APPS / app / "android")
            check_gitignore(app)
        except (OSError, ValueError, KeyError, ET.ParseError, plistlib.InvalidFileException) as e:
            failures_before.append(f"{app}: {type(e).__name__}: {e}")
    try:
        check_web()
    except (OSError, ValueError) as e:
        failures_before.append(f"web: {type(e).__name__}: {e}")
    try:
        check_ci()
        check_store_docs()
        check_camera_and_analytics()
        check_pay_scheme()
    except (OSError, ValueError) as e:
        failures_before.append(f"ci: {type(e).__name__}: {e}")
    # Built outputs are checked when given: --aab app-release.aab (or an .apk) for 16 KB alignment,
    # --manifest <merged AndroidManifest.xml> for permissions that plugins add.
    for i, arg in enumerate(sys.argv):
        if arg == "--aab" and i + 1 < len(sys.argv):
            try:
                check_aab(sys.argv[i + 1])
            except (OSError, zipfile.BadZipFile) as e:
                failures_before.append(f"{sys.argv[i + 1]}: {type(e).__name__}: {e}")
        if arg == "--ipa" and i + 1 < len(sys.argv):
            try:
                check_ipa(sys.argv[i + 1])
            except (OSError, ValueError, KeyError, zipfile.BadZipFile, plistlib.InvalidFileException) as e:
                failures_before.append(f"{sys.argv[i + 1]}: {type(e).__name__}: {e}")
        if arg == "--manifest" and i + 1 < len(sys.argv):
            try:
                check_merged_manifest(sys.argv[i + 1])
            except (OSError, ValueError, ET.ParseError) as e:
                failures_before.append(f"{sys.argv[i + 1]}: {type(e).__name__}: {e}")
    for line in failures_before + FAILED:
        print("FAIL", line)
    print(f"native checks: {PASSED[0]} passed, {len(FAILED) + len(failures_before)} failed")
    return 1 if FAILED or failures_before else 0


if __name__ == "__main__":
    sys.exit(main())
