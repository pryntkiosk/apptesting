# Flutter / plugins
-keep class io.flutter.** { *; }
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# Keep generic signatures (gson/json reflection)
-keepattributes Signature
-keepattributes *Annotation*

# Google Play Core (referenced by Flutter engine, not used in this app)
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }
