"""Makes the customer and partner apps store-ready. Idempotent: safe to run again.

  python -I scripts/store_ready.py

- Android: release signing from CI secrets (Codemagic's CM_KEYSTORE_* variables) or
  android/key.properties; debug keys only when neither exists, so local release builds still run.
- Android: INTERNET + notification permissions in the main manifest (Flutter's template only
  declares INTERNET for debug builds, so a release build would have no network), app label.
- iOS: display name, photo/camera usage texts (Korean), export-compliance flag.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent / "app" / "apps"
APPS = {
    "customer": {"label": "말끔"},
    "partner": {"label": "말끔 파트너"},
    "console": {"label": "말끔 콘솔"},
}
PHOTO = "청소 전후 사진과 상담 사진을 올리기 위해 사진 보관함에 접근해요."
CAMERA = "청소 전후 사진을 바로 찍어 올리기 위해 카메라를 사용해요."

SIGNING = '''// Release signing: CI secrets (Codemagic CM_KEYSTORE_*) or android/key.properties.
// Without either, release builds fall back to debug keys so `flutter run --release` still works.
val keyProps = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(env: String, prop: String): String? = System.getenv(env) ?: keyProps.getProperty(prop)
val releaseStore = signingValue("CM_KEYSTORE_PATH", "storeFile")

'''

RELEASE_BLOCK_OLD = '''    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }'''

RELEASE_BLOCK_NEW = '''    signingConfigs {
        if (releaseStore != null) {
            create("release") {
                storeFile = file(releaseStore)
                storePassword = signingValue("CM_KEYSTORE_PASSWORD", "storePassword")
                keyAlias = signingValue("CM_KEY_ALIAS", "keyAlias")
                keyPassword = signingValue("CM_KEY_PASSWORD", "keyPassword")
            }
        }
    }

    buildTypes {
        release {
            signingConfig = if (releaseStore != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }'''

PERMISSIONS = '''    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
'''


def gradle(app: pathlib.Path) -> None:
    p = app / "android" / "app" / "build.gradle.kts"
    s = p.read_text(encoding="utf-8")
    if "releaseStore" in s:
        return
    s = s.replace("        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).\n", "")
    if RELEASE_BLOCK_OLD not in s:
        raise SystemExit(f"{p}: unexpected release block")
    s = s.replace(RELEASE_BLOCK_OLD, RELEASE_BLOCK_NEW)
    # Kotlin script: imports and top-level vals go after the plugins block.
    end = s.index("}\n", s.index("plugins {")) + 2
    s = s[:end] + "\n" + SIGNING + s[end:]
    p.write_text(s, encoding="utf-8", newline="\n")


def manifest(app: pathlib.Path, label: str) -> None:
    p = app / "android" / "app" / "src" / "main" / "AndroidManifest.xml"
    s = p.read_text(encoding="utf-8")
    s = re.sub(r'android:label="[^"]*"', f'android:label="{label}"', s, count=1)
    if "android.permission.INTERNET" not in s:
        s = s.replace('<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n',
                      '<manifest xmlns:android="http://schemas.android.com/apk/res/android">\n' + PERMISSIONS, 1)
    p.write_text(s, encoding="utf-8", newline="\n")


def plist_set(s: str, key: str, value: str, kind: str = "string") -> str:
    entry = f"\t<key>{key}</key>\n\t<{kind}>{value}</{kind}>\n" if kind == "string" else f"\t<key>{key}</key>\n\t<{value}/>\n"
    pattern = re.compile(rf"\t<key>{key}</key>\n\t<[^>]+>[^<\n]*(</[^>]+>)?\n")  # [^<\n]: a <false/> value must not swallow the next line's </dict>
    if pattern.search(s):
        return pattern.sub(entry, s, count=1)
    return s.replace("</dict>\n</plist>", entry + "</dict>\n</plist>", 1)


def plist(app: pathlib.Path, label: str) -> None:
    p = app / "ios" / "Runner" / "Info.plist"
    if not p.exists():
        return
    s = p.read_text(encoding="utf-8")
    s = plist_set(s, "CFBundleDisplayName", label)
    s = plist_set(s, "NSPhotoLibraryUsageDescription", PHOTO)
    s = plist_set(s, "NSCameraUsageDescription", CAMERA)
    s = plist_set(s, "ITSAppUsesNonExemptEncryption", "false", kind="bool")
    p.write_text(s, encoding="utf-8", newline="\n")


def main() -> None:
    for name, cfg in APPS.items():
        app = ROOT / name
        gradle(app)
        manifest(app, cfg["label"])
        plist(app, cfg["label"])
        print("store-ready:", name)


if __name__ == "__main__":
    main()
