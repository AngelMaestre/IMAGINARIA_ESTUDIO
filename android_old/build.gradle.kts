plugins {
    // No aplicar aquí, solo declarar si quieres; ya lo hacemos en settings/app
    id("com.android.application") apply false
    id("org.jetbrains.kotlin.android") apply false
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}
