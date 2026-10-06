import java.security.KeyStore
import java.util.Collections

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.lmk"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_21
        targetCompatibility = JavaVersion.VERSION_21
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_21.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.example.lmk"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            val keystoreFile = file("release.keystore")
            if (keystoreFile.exists()) {
                val rawStorePass = System.getenv("KEYSTORE_PASSWORD")?.trim()?.removeSurrounding("\"")?.removeSurrounding("'")
                val storePass = if (!rawStorePass.isNullOrEmpty()) rawStorePass else "android"

                val rawKeyPass = System.getenv("KEY_PASSWORD")?.trim()?.removeSurrounding("\"")?.removeSurrounding("'")
                val keyPass = if (!rawKeyPass.isNullOrEmpty()) rawKeyPass else storePass

                val rawAlias = System.getenv("KEY_ALIAS")?.trim()?.removeSurrounding("\"")?.removeSurrounding("'")
                var resolvedAlias = if (!rawAlias.isNullOrEmpty()) rawAlias else null

                try {
                    val keyStore = KeyStore.getInstance(keystoreFile, storePass.toCharArray())
                    val availableAliases: List<String> = Collections.list(keyStore.aliases()).map { it.toString() }
                    println("--> Keystore loaded: found ${availableAliases.size} alias(es): $availableAliases")

                    if (resolvedAlias != null && keyStore.containsAlias(resolvedAlias)) {
                        println("--> Keystore: using confirmed alias '$resolvedAlias'.")
                    } else if (resolvedAlias != null && availableAliases.any { it.equals(resolvedAlias, ignoreCase = true) }) {
                        val matched = availableAliases.first { it.equals(resolvedAlias, ignoreCase = true) }
                        println("--> Keystore: auto-corrected alias case sensitivity from '$resolvedAlias' to '$matched'.")
                        resolvedAlias = matched
                    } else if (availableAliases.size == 1) {
                        val autoAlias = availableAliases.first()
                        println("--> Keystore: auto-selecting the only available alias '$autoAlias' (configured alias was '${resolvedAlias ?: "<none>"}').")
                        resolvedAlias = autoAlias
                    } else if (availableAliases.isNotEmpty()) {
                        println("--> WARNING: Configured alias '${resolvedAlias ?: "<none>"}' not found in keystore. Available aliases: $availableAliases")
                    }
                } catch (e: Exception) {
                    println("--> Note: Could not auto-inspect release.keystore ($e). Falling back to provided credentials.")
                }

                storeFile = keystoreFile
                storePassword = storePass
                keyAlias = resolvedAlias ?: "androiddebugkey"
                keyPassword = keyPass
            } else {
                val debug = signingConfigs.getByName("debug")
                storeFile = debug.storeFile
                storePassword = debug.storePassword
                keyAlias = debug.keyAlias
                keyPassword = debug.keyPassword
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
            proguardFiles(
                getDefaultProguardFile("proguard-android.txt"),
                "proguard-rules.pro"
            )
        }
    }
}
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

configurations.all {
    resolutionStrategy {
        force("androidx.browser:browser:1.8.0")
        force("androidx.core:core:1.15.0")
        force("androidx.core:core-ktx:1.15.0")
    }
}

flutter {
    source = "../.."
}
