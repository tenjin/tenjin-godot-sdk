import org.gradle.api.tasks.Copy

plugins {
    id("com.android.library")
    id("org.jetbrains.kotlin.android")
}

// Keep in sync with addons/tenjin/plugin.cfg and the export plugin's
// TENJIN_ANDROID_DEPENDENCY.
val pluginVersion = "1.0.0"
val tenjinAndroidSdkVersion = "1.24.0"
val godotVersion = "4.3.0.stable"

android {
    namespace = "com.tenjin.godot"
    compileSdk = 35

    defaultConfig {
        minSdk = 21
        consumerProguardFiles("consumer-rules.pro")
        buildConfigField("String", "PLUGIN_VERSION", "\"$pluginVersion\"")
    }

    buildFeatures {
        buildConfig = true
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }
}

dependencies {
    // Provided by the Godot export template at runtime.
    compileOnly("org.godotengine:godot:$godotVersion")
    // Compile against the SDK only; the export plugin adds it as a Maven
    // dependency of the game so the app resolves it (and its POM) itself.
    compileOnly("com.tenjin:android-sdk:$tenjinAndroidSdkVersion")
}

// Copies the built AARs into the addon so the Godot editor picks them up.
val copyDebugAarToAddon by tasks.registering(Copy::class) {
    dependsOn("assembleDebug")
    from(layout.buildDirectory.file("outputs/aar/plugin-debug.aar"))
    into("../../addons/tenjin/bin/android")
    rename { "tenjin-godot-debug.aar" }
}

val copyReleaseAarToAddon by tasks.registering(Copy::class) {
    dependsOn("assembleRelease")
    from(layout.buildDirectory.file("outputs/aar/plugin-release.aar"))
    into("../../addons/tenjin/bin/android")
    rename { "tenjin-godot-release.aar" }
}

tasks.register("buildAddon") {
    dependsOn(copyDebugAarToAddon, copyReleaseAarToAddon)
}
