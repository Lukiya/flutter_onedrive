-keepclassmembers class * {
    @androidx.annotation.Keep <methods>;
}
-keepclassmembers class * {
    @androidx.annotation.Keep <fields>;
}
-keepclassmembers class * {
    @androidx.annotation.Keep <init>(...);
}
-keep @androidx.annotation.Keep class * {*;}

-keepclasseswithmembernames class * {
    native <methods>;
}

-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

-keep class * implements android.os.Parcelable {
  public static final android.os.Parcelable$Creator *;
}

-dontwarn androidx.**
-keep class com.google.firebase.** { *; }
