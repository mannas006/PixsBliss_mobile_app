# Add project specific ProGuard rules here.
# You can control the set of applied configuration files using the
# proguardFiles setting in build.gradle.
#
# For more details, see
#   http://developer.android.com/guide/developing/tools/proguard.html

# If your project uses WebView with JS, uncomment the following
# and specify the fully qualified class name to the JavaScript interface
# class:
#-keepclassmembers class fqcn.of.javascript.interface.for.webview {
#   public *;
#}

# Uncomment this to preserve the line number information for
# debugging stack traces.
#-keepattributes SourceFile,LineNumberTable

# If you keep the line number information, uncomment this to
# hide the original source file name.
#-renamesourcefileattribute SourceFile

# Razorpay ProGuard rules
-keep class com.razorpay.** {*;}
-keep class com.google.android.gms.** {*;}
-dontwarn com.razorpay.**
-dontwarn com.google.android.gms.**

# Keep ProGuard annotations
-keep @proguard.annotation.Keep class * { *; }
-keep,allowobfuscation @interface proguard.annotation.Keep
-keep,allowobfuscation @interface proguard.annotation.KeepClassMembers
-keep @proguard.annotation.Keep class * { *; }
-keepclassmembers class * {
    @proguard.annotation.Keep *;
}

# Keep classes that are referenced but not found
-dontwarn proguard.annotation.Keep
-dontwarn proguard.annotation.KeepClassMembers

# Flutter specific rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Firebase rules
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# Permission handler rules
-keep class com.baseflow.permissionhandler.** { *; }
-dontwarn com.baseflow.permissionhandler.**

# Open file rules
-keep class com.crazecoder.openfile.** { *; }
-dontwarn com.crazecoder.openfile.**

# Device info plus rules
-keep class dev.fluttercommunity.plus.device_info.** { *; }
-dontwarn dev.fluttercommunity.plus.device_info.**

# Package info plus rules
-keep class dev.fluttercommunity.plus.package_info.** { *; }
-dontwarn dev.fluttercommunity.plus.package_info.**

# Keep Play Core classes for Flutter deferred components (even if not used)
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

# Suppress deprecated API warnings for third-party libraries
-dontwarn **.deprecated.**
-dontnote **.deprecated.**

# Suppress Java version warnings
-dontwarn **.options.**
-dontnote **.options.**

# Suppress all warnings for third-party libraries
-dontwarn com.razorpay.**
-dontwarn com.google.android.gms.**
-dontwarn io.flutter.**
-dontwarn androidx.** 