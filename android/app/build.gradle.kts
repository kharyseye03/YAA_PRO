plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "gn.yaa.pro"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Requis par le Navigation SDK tant que minSdk < 34
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // Identité définitive de l'app sur le Play Store : ne plus jamais
        // la changer une fois la première version publiée.
        applicationId = "gn.yaa.pro"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        // Navigation SDK Google Maps : API 24 minimum
        minSdk = 24
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
}

configurations.all {
    // Le Navigation SDK embarque déjà les classes du SDK Maps :
    // toute dépendance vers play-services-maps créerait des classes
    // en double à la compilation.
    exclude(group = "com.google.android.gms", module = "play-services-maps")
}

dependencies {
    // Le Navigation SDK exige la variante « nio » du desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs_nio:2.1.5")
}

flutter {
    source = "../.."
}
