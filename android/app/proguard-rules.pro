# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# flutter_local_notifications
-keep class com.dexterous.** { *; }

# home_widget
-keep class es.antonborri.** { *; }

# shared_preferences
-keep class io.flutter.plugins.sharedpreferences.** { *; }

# Gson / JSON (used internally by some plugins)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Flutter deferred components (not used in this app)
-dontwarn com.google.android.play.core.**
