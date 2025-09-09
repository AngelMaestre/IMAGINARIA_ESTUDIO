pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    // Lee flutter.sdk de local.properties
    val localProps = java.util.Properties()
    val localPropsFile = File(rootDir, "local.properties")
    if (localPropsFile.exists()) {
        localPropsFile.inputStream().use { localProps.load(it) }
    }
    val flutterSdk: String = localProps.getProperty("flutter.sdk")
        ?: error("Falta 'flutter.sdk' en local.properties")

    // Muy importante: incluir el build de flutter_tools
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")
}

plugins {
    // Carga el loader del plugin de Flutter
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Versiones alineadas con Flutter 3.16+ (Gradle 8.x)
    id("com.android.application") version "8.4.2" apply false
    id("com.android.library")    version "8.4.2" apply false
    id("org.jetbrains.kotlin.android") version "1.9.23" apply false
}

rootProject.name = "IMAGINARIA_ESTUDIO"
include(":app")
