-dontwarn com.google.mlkit.vision.text.**

# Fix flutter_local_notifications release build crash due to R8 stripping generic signatures of TypeToken
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keep class com.dexterous.flutterlocalnotifications.** { *; }
