# Flutter's Gradle plugin supplies the Flutter engine keep rules. Preserve only
# the native entry activity and MethodChannel handler added by this app.
-keep class com.precision.calc.MainActivity { *; }

# Keep source/line metadata out of release stack traces while retaining enough
# information for symbolicated crash reports.
-renamesourcefileattribute SourceFile
-keepattributes LineNumberTable
