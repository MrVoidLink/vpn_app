// android/settings.gradle.kts

pluginManagement {
    // مسیر Flutter SDK
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }
    val flutterSdkPath = properties.getProperty("flutter.sdk")
        ?: throw GradleException("flutter.sdk not set in local.properties")

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        // مخازن اصلی
        google()
        mavenCentral()
        gradlePluginPortal()
        // ریپو آرتیفکت‌های Flutter
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        // (اختیاری) میرورها
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://mirrors.cloud.tencent.com/repository/gradle-plugin/") }
    }

    // Resolve مستقیم پلاگین‌ها به آرتیفکت‌های واقعی
    resolutionStrategy {
        eachPlugin {
            when (requested.id.id) {
                "com.android.application",
                "com.android.library" ->
                    useModule("com.android.tools.build:gradle:${requested.version}")
                "com.google.gms.google-services" ->
                    useModule("com.google.gms:google-services:${requested.version}")
                "org.jetbrains.kotlin.android" ->
                    useModule("org.jetbrains.kotlin:kotlin-gradle-plugin:${requested.version}")
            }
        }
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.3.2" apply false
    id("com.google.gms.google-services") version "4.3.15" apply false
    id("org.jetbrains.kotlin.android") version "1.9.22" apply false
}

dependencyResolutionManagement {
    // ✅ به‌جای FAIL_ON_PROJECT_REPOS
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        // ریپوی Flutter
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }

        // (اختیاری) میرورها
        maven { url = uri("https://maven.aliyun.com/repository/google") }
        maven { url = uri("https://maven.aliyun.com/repository/central") }
        maven { url = uri("https://maven.aliyun.com/repository/gradle-plugin") }
        maven { url = uri("https://mirrors.cloud.tencent.com/repository/gradle-plugin/") }
    }
}

include(":app")
