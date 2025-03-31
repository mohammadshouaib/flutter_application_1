plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin") // Flutter Plugin
    id("com.google.gms.google-services") // Google Services Plugin (Firebase)
}

android {
    namespace = "com.example.flutter_application_1"
    compileSdk = 35 // Replace with the latest compile SDK version

    defaultConfig {
        applicationId = "com.example.flutter_application_1"
        minSdk = 23 // Ensure min SDK is compatible with Firebase
        targetSdk = 35
        versionCode = 1
        versionName = "1.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Replace with your release signingConfig if needed
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Firebase BoM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:33.11.0"))

    // Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // 🔹 Add Firebase Authentication for login/signup
    implementation("com.google.firebase:firebase-auth")

    // 🔹 Add Firebase Firestore (if using database)
    // implementation("com.google.firebase:firebase-firestore")
}
