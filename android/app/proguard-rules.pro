# ProGuard rules for PopCornList release build
# R8/minifyEnabled = true → keep classes needed at runtime

# ========================================
# ANDROID NETWORKING — CRITICAL pour DNS + HTTP
# Sans ces règles, R8 strips les classes réseau → échec DNS
# ========================================
-keep class android.net.** { *; }
-dontwarn android.net.**
-keep class java.net.** { *; }
-dontwarn java.net.**
-keep class javax.net.ssl.** { *; }
-keep class android.system.** { *; }

# ========================================
# Flutter engine
# ========================================
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# ========================================
# Hive — local DB models
# ========================================
-keep class * extends com.hive.** { *; }
-keep class * extends hive.** { *; }
-keep @com.hive.HiveType class * { *; }
-keep @hive.HiveType class * { *; }
-keepclassmembers class * {
    @com.hive.HiveField *;
    @hive.HiveField *;
}

# ========================================
# HTTP client — Dio (uses dart:io + OkHttp internally)
# ========================================
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}
-keep class okhttp3.** { *; }
-dontwarn okhttp3.**
-keep class com.squareup.okhttp.** { *; }

# ========================================
# JSON serialization (gson)
# ========================================
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**

# ========================================
# Model classes used for JSON serialization
# ========================================
-keep class com.bison.films_app.models.** { *; }
-keepclassmembers class com.bison.films_app.models.** { *; }

# ========================================
# Enum classes
# ========================================
-keepclassmembers enum * { *; }

# ========================================
# Keep all classes that might be loaded via reflection
# ========================================
-keep class kotlin.** { *; }
-keep class org.jetbrains.skia.** { *; }
