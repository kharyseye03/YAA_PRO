import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Mots de passe et chemin du keystore, lus depuis android/key.properties.
// Ce fichier est gitignoré et propre à chaque machine : les secrets de
// signature ne doivent jamais entrer dans le dépôt. Voir
// key.properties.example pour le modèle.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
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

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)
                ?.let { rootProject.file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    buildTypes {
        release {
            // Signature de release dès que android/key.properties existe.
            // Sans ce fichier — sur la machine d'un collègue qui n'a pas
            // le keystore — on retombe sur la clé de debug pour que
            // `flutter run --release` continue de fonctionner en local.
            // Un tel build reste installable mais ne peut pas être publié.
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
