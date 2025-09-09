plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // Se resuelve gracias al includeBuild del settings
    id("dev.flutter.flutter-gradle-plugin")
}

flutter {
    // Ruta a la raíz del proyecto Flutter (dos niveles arriba desde android/app)
    source = "../.."
}

android {
    namespace = "com.imaginaria.imaginaria_estudio" // AJUSTA si difiere
    compileSdk = 34

    defaultConfig {
        applicationId = "com.imaginaria.imaginaria_estudio" // AJUSTA si difiere
        minSdk = flutter.minSdkVersion
        targetSdk = 34
        versionCode = 1
        versionName = "1.0"
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
        debug {
            isMinifyEnabled = false
        }
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources.excludes += setOf(
            "META-INF/DEPENDENCIES",
            "META-INF/AL2.0",
            "META-INF/LGPL2.1"
        )
    }
}

dependencies {
    implementation("androidx.multidex:multidex:2.0.1")
}
