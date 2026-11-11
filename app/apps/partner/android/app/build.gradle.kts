plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing: CI secrets (Codemagic CM_KEYSTORE_*) or android/key.properties.
// Without either, release builds fall back to debug keys so `flutter run --release` still works.
val keyProps = java.util.Properties().apply {
    val f = rootProject.file("key.properties")
    if (f.exists()) f.inputStream().use { load(it) }
}
fun signingValue(env: String, prop: String): String? = System.getenv(env) ?: keyProps.getProperty(prop)

// Build-time --dart-define values. The Flutter tool passes them to Gradle as base64 "KEY=VALUE" entries.
val dartDefines: Map<String, String> =
    (project.findProperty("dart-defines") as String?)
        ?.split(",")
        ?.associate { entry ->
            val (key, value) = String(java.util.Base64.getDecoder().decode(entry)).split("=", limit = 2)
            key to value
        }
        .orEmpty()
// Firebase (push) needs google-services.json, written by CI from a secret. Without it the plugin stays off.
val hasFirebaseConfig = file("google-services.json").exists()
if (hasFirebaseConfig) apply(plugin = "com.google.gms.google-services")
val releaseStore = signingValue("CM_KEYSTORE_PATH", "storeFile")


android {
    namespace = "com.malkkeum.partner"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.malkkeum.partner"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        // Google Play requires API 36 for updates from 2026-08-31; pinned so an older Flutter SDK cannot lower it.
        targetSdk = 36
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        // Kakao login redirect scheme is kakao<native app key>.
        manifestPlaceholders["kakaoNativeKey"] = dartDefines["KAKAO_NATIVE_KEY"].orEmpty()
        // Naver App Link host (https://<host>/auth/naver/callback); the Naver button is hidden without it.
        manifestPlaceholders["appLinkHost"] = dartDefines["APP_LINK_DOMAIN"].orEmpty()
    }

    signingConfigs {
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
            // Codemagic sets CM_BUILD_ID: a release bundle there must never fall back to the debug key.
            check(releaseStore != null || System.getenv("CM_BUILD_ID") == null) { "CM_KEYSTORE_PATH is unset on Codemagic" }
            signingConfig = if (releaseStore != null) signingConfigs.getByName("release") else signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
