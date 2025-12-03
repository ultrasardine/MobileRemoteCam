# Gradle to Flutter Plugin Migration

## Overview

This document describes the migration from a standalone Gradle/Gulp build system to Flutter's standard plugin architecture.

## What Changed

### Before Migration

The project used a custom build system:
- **Standalone Gradle**: Separate Android app with its own build.gradle files
- **Gulp**: JavaScript-based build orchestration for Android
- **Node.js**: Required for running Gulp tasks
- **Custom Package**: `com.samsung.android.scan3d`

### After Migration

The project now uses Flutter's standard architecture:
- **Flutter Plugin**: Android code integrated as a Flutter plugin
- **Standard Gradle**: Gradle managed by Flutter's build system
- **No Node.js**: Removed Gulp and all Node.js dependencies
- **Updated Package**: `com.ipcamera.ip_camera_streaming`

## Migration Steps Performed

### 1. Created Flutter Android Structure

```bash
flutter create --org com.ipcamera --platforms android,ios .
```

This created:
- `android/` directory with Flutter's standard structure
- `android/app/build.gradle.kts` with Flutter Gradle plugin
- `android/app/src/main/kotlin/com/ipcamera/ip_camera_streaming/`

### 2. Migrated Native Code

Moved Android native code to Flutter plugin structure:
- `MainActivity.kt` - Updated with method channel setup
- `serv/NetworkMonitor.kt` - Network monitoring service
- `serv/StreamingManager.kt` - Streaming coordination (placeholder)

Updated package names from `com.samsung.android.scan3d` to `com.ipcamera.ip_camera_streaming`.

### 3. Removed Old Build System

Deleted:
- `build.gradle` (root)
- `settings.gradle`
- `gradle.properties`
- `gradlew` and `gradlew.bat`
- `gulpfile.js`
- `package.json` and `package-lock.json`
- `node_modules/`
- `.gradle/`

### 4. Updated Build Configuration

**android/app/build.gradle.kts:**
```kotlin
android {
    namespace = "com.ipcamera.ip_camera_streaming"
    defaultConfig {
        applicationId = "com.ipcamera.ip_camera_streaming"
        minSdk = 28
        targetSdk = 34
        versionCode = 4
        versionName = "0.0.4"
    }
}
```

### 5. Updated Makefile

Changed from Gulp to Flutter commands:
```makefile
# Before
build-android:
    npx gulp android:build

# After
build-android:
    flutter build apk --release
```

### 6. Updated Documentation

Updated all documentation files:
- **README.md**: Build system, project structure, prerequisites
- **CONTRIBUTING.md**: Development setup, testing, coding standards
- **CHANGELOG.md**: Migration details
- **BUILD_SYSTEM.md**: Complete rewrite for Flutter architecture
- **.gitignore**: Flutter-specific patterns

## Method Channels

The plugin exposes native functionality via method channels:

### Streaming Channel (`com.ipcamera/streaming`)

```dart
// Dart side
final result = await platform.invokeMethod('startStreaming', config);
```

```kotlin
// Kotlin side
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, STREAMING_CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "startStreaming" -> {
                // Handle streaming
            }
        }
    }
```

### Network Channel (`com.ipcamera/network`)

```dart
// Dart side
await platform.invokeMethod('startNetworkMonitoring');
```

```kotlin
// Kotlin side
MethodChannel(flutterEngine.dartExecutor.binaryMessenger, NETWORK_CHANNEL)
    .setMethodCallHandler { call, result ->
        when (call.method) {
            "startNetworkMonitoring" -> {
                networkMonitor?.startMonitoring { type, ip ->
                    // Notify Flutter
                }
            }
        }
    }
```

## Benefits

### For Developers

1. **Simplified Setup**: No Node.js or Gulp installation required
2. **Standard Workflow**: Use familiar Flutter commands
3. **Better IDE Support**: Full Android Studio and VS Code integration
4. **Hot Reload**: Instant UI updates during development
5. **Unified Testing**: Single test command for all platforms

### For Build System

1. **Reduced Dependencies**: Removed Node.js, npm, Gulp
2. **Faster Builds**: Flutter's incremental compilation
3. **Better Caching**: Gradle daemon and Flutter build cache
4. **Standard Tools**: Industry-standard Flutter/Gradle toolchain

### For Maintenance

1. **Less Configuration**: Flutter manages Gradle configuration
2. **Automatic Updates**: Flutter updates include Gradle updates
3. **Better Documentation**: Standard Flutter documentation applies
4. **Community Support**: Larger Flutter community for help

## Breaking Changes

### Build Commands

| Before | After |
|--------|-------|
| `npx gulp android:build` | `flutter build apk` |
| `npx gulp android:clean` | `flutter clean` |
| `npx gulp android:test` | `flutter test` |
| `npm install` | `flutter pub get` |

### Package Names

All Android code moved from:
- `com.samsung.android.scan3d.*`

To:
- `com.ipcamera.ip_camera_streaming.*`

### Directory Structure

| Before | After |
|--------|-------|
| `app/src/main/java/` | `android/app/src/main/kotlin/` |
| `app/build.gradle` | `android/app/build.gradle.kts` |
| Root `build.gradle` | Managed by Flutter |

## Migration Checklist

- [x] Create Flutter Android structure
- [x] Migrate MainActivity with method channels
- [x] Migrate NetworkMonitor service
- [x] Create StreamingManager placeholder
- [x] Update package names
- [x] Remove old Gradle files
- [x] Remove Gulp and Node.js dependencies
- [x] Update Makefile
- [x] Update .gitignore
- [x] Update README.md
- [x] Update CONTRIBUTING.md
- [x] Update CHANGELOG.md
- [x] Update BUILD_SYSTEM.md
- [ ] Migrate remaining streaming components (CameraCapture, VideoEncoder, etc.)
- [ ] Migrate JNI native libraries
- [ ] Update all tests to use new package names
- [ ] Test on physical Android device

## Next Steps

### Immediate

1. **Test Build**: Verify `flutter build apk` works
2. **Test on Device**: Run on physical Android device
3. **Verify Method Channels**: Test platform communication

### Short Term

1. **Migrate Streaming Components**: Move remaining Kotlin classes
2. **Implement Native Libraries**: Set up NDK build for Live555/librtmp
3. **Update Tests**: Ensure all tests pass with new structure

### Long Term

1. **iOS Implementation**: Complete iOS native code
2. **Feature Parity**: Ensure Android matches original functionality
3. **Performance Optimization**: Tune for production use

## Troubleshooting

### Build Fails

```bash
# Clean everything
flutter clean
cd android && ./gradlew clean
cd ../..

# Reinstall dependencies
flutter pub get

# Try building again
flutter build apk
```

### Method Channel Not Working

Check that:
1. Channel names match between Dart and Kotlin
2. MainActivity is properly registered
3. Method names are spelled correctly
4. Arguments are properly serialized

### Package Name Issues

If you see import errors:
1. Verify all files use `com.ipcamera.ip_camera_streaming`
2. Check AndroidManifest.xml has correct package
3. Rebuild: `flutter clean && flutter pub get`

## References

- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Flutter Android Plugin Development](https://docs.flutter.dev/development/platform-integration/platform-channels)
- [Gradle Build Configuration](https://docs.gradle.org/current/userguide/userguide.html)

---

**Migration Date:** December 3, 2025  
**Flutter Version:** 3.35.6  
**Gradle Version:** Managed by Flutter
