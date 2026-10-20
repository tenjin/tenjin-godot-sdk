# Godot looks up the plugin class by name from the manifest and calls its
# @UsedByGodot methods reflectively.
-keep class com.tenjin.godot.TenjinGodotPlugin { *; }
-keep class com.tenjin.android.** { *; }
-keep interface com.tenjin.android.** { *; }
-keepattributes Signature
-keepattributes *Annotation*
