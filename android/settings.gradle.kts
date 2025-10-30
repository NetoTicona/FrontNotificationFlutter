pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // CAMBIADO: Versión de Android Gradle Plugin (AGP) antigua
    id("com.android.application") version "7.2.2" apply false

    // CAMBIADO: Versión de Kotlin antigua (compatible con AGP 7.2.2)
    id("org.jetbrains.kotlin.android") version "1.8.0" apply false
}

include(":app")