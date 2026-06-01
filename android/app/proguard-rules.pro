# Flutter
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Gson / JSON (used by some plugins)
-keepattributes Signature
-keepattributes *Annotation*

# Geolocator, image_picker, secure storage plugins
-keep class com.baseflow.geolocator.** { *; }
-keep class io.flutter.plugins.** { *; }
