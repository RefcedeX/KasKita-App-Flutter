plugins {
    id("com.android.application")
    id("com.google.gms.google-services")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.kaskita"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        applicationId = "com.example.kaskita"
        minSdk = flutter.minSdkVersion
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")

            // Menonaktifkan R8/Proguard
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

android.applicationVariants.all {
    outputs.all {
        val output =
            this as com.android.build.gradle.internal.api.ApkVariantOutputImpl

        val abi =
            if (output.getFilter(com.android.build.OutputFile.ABI) != null)
                "-${output.getFilter(com.android.build.OutputFile.ABI)}"
            else
                ""

        output.outputFileName =
            "KasKita-v${android.defaultConfig.versionName}${abi}.apk"
    }
}