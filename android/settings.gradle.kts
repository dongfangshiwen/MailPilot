pluginManagement {
    val localFile=file("local.properties")
    val p=java.util.Properties().apply { localFile.inputStream().use { load(it) } }
    // Flutter rewrites Windows SDK paths before invoking Gradle. Store them with
    // Java's complete property escaping so AGP Lint accepts drive-letter colons.
    val escaped=java.io.StringWriter().also { p.store(it,null) }.toString()
        .lineSequence().filter { it.isNotBlank() && !it.startsWith("#") }.sorted().joinToString("\n",postfix="\n")
    if(localFile.readText()!=escaped) localFile.writeText(escaped)
    val flutterSdk=requireNotNull(p.getProperty("flutter.sdk")) { "flutter.sdk must be set in local.properties" }
    includeBuild("$flutterSdk/packages/flutter_tools/gradle")
    repositories { google(); mavenCentral(); gradlePluginPortal() }
}
plugins {
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"
    id("com.android.application") version "9.1.0" apply false
    id("org.jetbrains.kotlin.android") version "2.2.20" apply false
    id("com.google.devtools.ksp") version "2.3.6" apply false
}
rootProject.name="MailPilot"
include(":app")
