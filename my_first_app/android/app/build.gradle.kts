plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.homeremedies.my_first_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.homeremedies.my_first_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // Handle duplicate classes bundled inside the Shabd SDK fat JAR
    packaging {
        resources {
            pickFirsts += listOf(
                "META-INF/MANIFEST.MF",
                "META-INF/LICENSE",
                "META-INF/NOTICE",
                "META-INF/LICENSE.md",
                "META-INF/NOTICE.md",
                "META-INF/versions/**",
                "META-INF/services/**",
                "META-INF/maven/**"
            )
        }
    }
}

configurations.all {
    // Exclude transitive okio-jvm since the Shabd SDK fat JAR bundles its own copy
    exclude(group = "com.squareup.okio", module = "okio-jvm")
    exclude(group = "com.squareup.okio", module = "okio")
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.jar"))))
}

flutter {
    source = "../.."
}
