-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn io.flutter.embedding.**

# Firebase
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# Supabase and HTTP/Websockets
-keep class io.supabase.** { *; }
-keep class com.google.gson.** { *; }

# Flutter Plugins
-keep class com.dexterous.flutterlocalnotifications.** { *; }
