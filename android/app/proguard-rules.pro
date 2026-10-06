# Google Sign In & Credential Manager
-keep class com.google.android.gms.auth.api.signin.** { *; }
-keep class androidx.credentials.** { *; }
-keep class androidx.credentials.playservices.** { *; }
-dontwarn androidx.credentials.**

# Flutter & Firebase
-keepattributes *Annotation*
-keepattributes Signature
