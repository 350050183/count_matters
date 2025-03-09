pluginManagement {
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")
//    repositoriesMode.set(RepositoriesMode.PREFER_SETTINGS) // 强制优先使用 settings 仓库
    repositories {
        // 阿里云镜像（可选）
        maven {
            url = uri("https://maven.aliyun.com/repository/public")
        }
        // Kotlin 官方仓库（必须添加）
        maven {
            url = uri("https://maven.pkg.jetbrains.space/kotlin/p/kotlin/bootstrap")
        }
        maven {
            url = uri("https://maven.pkg.jetbrains.space/public/p/kotlinx-coroutines/maven")
        }
        // Google 仓库
        maven {
            url = uri("https://maven.google.com")
        }
        // 原始仓库（临时启用）
        maven { url = uri("https://repo.maven.apache.org/maven2") } // Maven Central
        maven { url = uri("https://plugins.gradle.org/m2") }        // Gradle 插件仓库
        maven { url = uri("https://jitpack.io") }                  // JitPack（可选）
        // Maven Central（必须）
        gradlePluginPortal()
        google()
        mavenCentral()
    }
}

plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "8.7.0" apply false
    id("org.jetbrains.kotlin.android") version "1.8.22" apply false
}

include(":app")
