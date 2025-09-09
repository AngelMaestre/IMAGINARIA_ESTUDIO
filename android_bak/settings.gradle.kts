// settings.gradle.kts — Flutter declarativo + Gradle 8.7 + AGP 8.6

pluginManagement {
    // 1) Cargar flutter.sdk desde local.properties
    val props = java.util.Properties()
    val lp = java.io.File(rootDir, "local.properties")
    check(lp.exists()) {
        "Falta android/local.properties con flutter.sdk=... y sdk.dir=..."
    }
    lp.inputStream().use { props.load(it) }
    val flutterSdk = props.getProperty("flutter.sdk")
        ?: error("Falta 'flutter.sdk' en local.properties")

    // 2) Inyectar build de Flutter (necesario para resolver sus plugins)
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")

    // 3) Repos + declaración del loader (declarativo)
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
    plugins {
        id("dev.flutter.flutter-plugin-loader") version "1.0.0"
        id("com.android.application") version "8.6.1"
        id("org.jetbrains.kotlin.android") version "2.1.0"
    }
}

dependencyResolutionManagement {
    // Preferimos repos de settings, pero sin bloquear plugins/módulos
    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS)
    repositories {
        google()
        mavenCentral()
        maven { url = uri("https://storage.googleapis.com/download.flutter.io") }
    }
}

rootProject.name = "IMAGINARIA_ESTUDIO"
include(":app")
