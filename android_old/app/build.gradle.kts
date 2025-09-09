plugins {
    id("com.android.application")
   id("org.jetbrains.kotlin.android") version "1.9.23"
    // Plugin de Flutter para Android (necesario para 'flutter.' en defaultConfig)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.imaginaria.imaginaria_estudio"

    // Valor fijo recomendado (Flutter 3.16 usa 34)
    compileSdk = 34

    defaultConfig {
        applicationId = "com.imaginaria.imaginaria_estudio"

        // Estos vienen del plugin de Flutter (no los pongas a pelo)
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // Ajusta según tu proguard si lo usas
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            // Si aún no firmas release, puedes dejar debug signing temporalmente:
            // signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Java 17 requerido por AGP 8.x
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    kotlinOptions {
        jvmTarget = "17"
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.appcompat:appcompat:1.6.1")
    // Kotlin stdlib (alineada con 1.9.22)
    implementation("org.jetbrains.kotlin:kotlin-stdlib:1.9.22")
}
