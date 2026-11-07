# Flutter Engine & Plugins
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# FFmpegKit Java & JNI Entry Points (Anton Karpenko & Arthenica namespaces)
-keep class com.arthenica.ffmpegkit.** { *; }
-keep class com.antonkarpenko.ffmpegkit.** { *; }
-keep interface com.arthenica.ffmpegkit.** { *; }
-keep interface com.antonkarpenko.ffmpegkit.** { *; }
-dontwarn com.arthenica.ffmpegkit.**
-dontwarn com.antonkarpenko.ffmpegkit.**

# Native methods across all classes
-keepclasseswithmembernames class * {
    native <methods>;
}

# Dart JNI & Kotlin Coroutines runtime reflection
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }

# Google Play Core & Dynamic Delivery warnings
-dontwarn com.google.android.play.core.**

# Flutter Local Notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keepclassmembers class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }

# File Picker Plugin
-keep class com.mr.flutter.plugin.filepicker.** { *; }

# Aturan untuk flutter_local_notifications
-keep class com.dexterous.** { *; }

# Aturan untuk Gson (digunakan oleh flutter_local_notifications untuk scheduled notifications)
-keepattributes Signature
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}
