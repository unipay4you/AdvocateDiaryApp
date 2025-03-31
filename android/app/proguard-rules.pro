# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Keep your application classes
-keep class com.example.my_legal_diary_app.** { *; }

# Keep shared preferences
-keep class com.google.gson.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep HTTP client
-keep class okhttp3.** { *; }
-keep class okio.** { *; }

# Keep secure storage
-keep class com.tekartik.sqflite.** { *; }
-keep class com.tekartik.sqflite_common.** { *; }

# Keep Play Core classes
-keep class com.google.android.play.core.** { *; }
-keep class com.google.android.play.core.splitcompat.** { *; }
-keep class com.google.android.play.core.splitinstall.** { *; }
-keep class com.google.android.play.core.tasks.** { *; }

# Suppress warnings
-dontwarn com.google.errorprone.annotations.CanIgnoreReturnValue
-dontwarn com.google.errorprone.annotations.CheckReturnValue
-dontwarn com.google.errorprone.annotations.Immutable
-dontwarn com.google.errorprone.annotations.RestrictedApi
-dontwarn javax.annotation.Nullable
-dontwarn javax.annotation.concurrent.GuardedBy

# Keep native methods
-keepclasseswithmembernames class * {
    native <methods>;
}

# Keep Parcelable implementations
-keep class * implements android.os.Parcelable {
    static ** CREATOR;
}

# Keep Serializable implementations
-keepnames class * implements java.io.Serializable

# Keep R8 full mode
-keepattributes SourceFile,LineNumberTable
-keepattributes *Annotation*
