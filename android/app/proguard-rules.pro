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
