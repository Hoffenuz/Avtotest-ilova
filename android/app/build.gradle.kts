import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.hoffenuz.avtotestu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "28.2.13676358"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // flutter_local_notifications uses java.time to schedule the daily
        // question; desugaring back-ports it to the Android versions this app
        // still supports. Without it the release build refuses to assemble.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // MUST match the Play listing exactly — "Avtodars" is published as
        // com.hoffenuz.Avtotestu (capital A). Android package names are
        // case-sensitive, so the lowercase form would be a separate app and
        // the 522 existing installs would never receive the update.
        // The Kotlin `namespace` above is independent and stays lowercase.
        applicationId = "com.hoffenuz.Avtotestu"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Falling back to the debug key here used to produce a release
            // build that Play always rejects, with nothing in the log to say
            // why. Fail loudly instead — but only when a release is actually
            // being assembled, so `flutter run`/debug builds stay unaffected.
            if (keystorePropertiesFile.exists()) {
                signingConfig = signingConfigs.getByName("release")
            } else {
                gradle.taskGraph.whenReady {
                    val releasing = allTasks.any {
                        it.name.contains("Release") &&
                            (it.name.startsWith("assemble") || it.name.startsWith("bundle"))
                    }
                    if (releasing) {
                        throw GradleException(
                            "android/key.properties not found — a release build would be " +
                                "signed with the debug key and rejected by Google Play. " +
                                "Copy android/key.properties.example and fill in the " +
                                "upload keystore credentials."
                        )
                    }
                }
            }

            // Play Console's optimization tips flag both of these when off.
            // They only touch the Java/Kotlin side (engine glue + plugins) —
            // the Dart code is already AOT-compiled into libapp.so — so the
            // saving is modest, but it also strips unused plugin resources.
            isMinifyEnabled = true
            isShrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
}
