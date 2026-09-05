# Reglas de ProGuard para Bellota App
# Flutter ya maneja la mayoría de reglas automáticamente.

# Mantener clases de Google Sign-In
-keep class com.google.android.gms.** { *; }
-keep class com.google.firebase.** { *; }

# Mantener clases de flutter_local_notifications
-keep class com.dexterous.** { *; }

# Mantener clases de sqflite
-keep class com.tekartik.sqflite.** { *; }

# No ofuscar modelos serializados
-keepattributes *Annotation*
-keepattributes Signature
