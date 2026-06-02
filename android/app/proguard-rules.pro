# ProGuard rules for PopCornList release build

# Flutter specific
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.embedding.** { *; }
-dontwarn io.flutter.embedding.**

# Hive — keep annotated model classes and type adapters
-keep class * extends com.hive.** { *; }
-keep class * extends hive.** { *; }
-keep @com.hive.HiveType class * { *; }
-keep @hive.HiveType class * { *; }
-keepclassmembers class * {
    @com.hive.HiveField *;
    @hive.HiveField *;
}

# Retrofit / Dio (HTTP client)
-keepattributes Signature
-keepattributes *Annotation*
-keep class retrofit2.** { *; }
-keepclassmembers class * {
    @retrofit2.http.* <methods>;
}

# Keep model classes used for JSON serialization
-keep class com.bison.films_app.models.** { *; }
-keepclassmembers class com.bison.films_app.models.** { *; }

# Keep enum classes used in the app
-keepclassmembers enum * { *; }
