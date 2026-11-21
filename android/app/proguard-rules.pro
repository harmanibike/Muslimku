# flutter_local_notifications membaca jadwal tersimpan melalui reflection.
# Jangan hapus generic signature atau obfuscate model/receiver plugin.
-keepattributes Signature
-keepattributes *Annotation*
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class com.google.gson.** { *; }
-keep class * extends com.google.gson.reflect.TypeToken { *; }
