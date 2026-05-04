# [UPDATE #5] ProGuard rules for CDN-NETCHAT
# Ensures minification doesn't break reflection-heavy libraries

# ===== Flutter =====
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# ===== Play Core (referenced by Flutter but not always included) =====
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.**

# ===== Supabase =====
-keep class com.supabase.** { *; }
-keep class io.supabase.** { *; }
-dontwarn com.supabase.**

# ===== Firebase =====
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**

# ===== WebRTC =====
-keep class org.webrtc.** { *; }
-dontwarn org.webrtc.**

# ===== Isar =====
-keep class isar.** { *; }
-keep class com.isar.** { *; }
-keepclassmembers class * { @isar.* <methods>; }
-dontwarn isar.**

# ===== Gson / JSON =====
-keepattributes Signature
-keepattributes *Annotation*
-keep class sun.misc.Unsafe { *; }

# ===== Keep all serializable models =====
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    !static !transient <fields>;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}

# ===== V2Ray =====
-keep class com.v2ray.** { *; }
-dontwarn com.v2ray.**

# ===== AndroidX =====
-keep class androidx.** { *; }
-keep interface androidx.** { *; }
-dontwarn androidx.**

# ===== Keep native methods =====
-keepclasseswithmembernames class * {
    native <methods>;
}

# ===== Keep enums =====
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# ===== Keep parcelable =====
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}
