-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

-keep class com.dexterous.** { *; }       # flutter_local_notifications
-dontwarn com.dexterous.**

-keep class androidx.work.** { *; }        # si alguna lib usa WorkManager
-dontwarn androidx.work.**

-keepattributes *Annotation*
