// Lee flutter.sdk desde local.properties
val props = java.util.Properties().apply {
    load(file("local.properties").inputStream())
}
val flutterSdk: String = props.getProperty("flutter.sdk")
require(flutterSdk.isNotBlank()) { "Missing flutter.sdk in local.properties" }

// Asegura que Gradle pueda “ver” el plugin de Flutter
pluginManagement {
    includeBuild("flutter.sdk=/opt/hostedtoolcache/flutter/stable-3.35.3-x64" >

Skip to content
Navigation Menu
")
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
    plugins {
        id("dev.flutter.flutter-plugin-loader") version "1.0.0" apply false
        id("com.android.application") version "8.1.2" apply false // >= 8.1.1
        id("org.jetbrains.kotlin.android") version "1.9.24" apply false
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "IMAGINARIA_ESTUDIO"
include(":app")
