# Build System Guide

## Overview

The IP Camera Streaming Platform uses Flutter's standard build system with native plugins:

- **Flutter**: Standard Flutter build system for UI layer and build orchestration
- **iOS**: CocoaPods for native dependencies
- **Android**: Gradle (via Flutter) for native plugin compilation

## Quick Start

### Install Dependencies

```bash
make install-deps
```

This will install:
- Flutter packages (`flutter pub get`)
- iOS dependencies (`pod install`)

### Build Commands

#### iOS
```bash
# Development build
make dev-ios

# Production build
make build-ios
```

#### Android
```bash
# Development build
make dev-android

# Production build (using Flutter)
make build-android
```

#### Both Platforms
```bash
# Build everything
make all
```

### Clean Build Artifacts

```bash
# Clean all platforms
make clean

# Clean Android only
cd android && ./gradlew clean

# Clean iOS only
cd ios && rm -rf Pods build
```

### Run Tests

```bash
# Run all tests
make test

# Run Flutter tests only
flutter test

# Run iOS native tests
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner
```

## Android Build System (Flutter + Gradle)

### Flutter Plugin Architecture

The Android native code is structured as a Flutter plugin using method channels:

```
android/
├── app/
│   ├── src/main/kotlin/com/ipcamera/ip_camera_streaming/
│   │   ├── MainActivity.kt          # Method channel setup
│   │   ├── serv/
│   │   │   ├── StreamingManager.kt  # Streaming coordination
│   │   │   └── NetworkMonitor.kt    # Network monitoring
│   │   └── streaming/               # Streaming components (future)
│   └── build.gradle.kts             # Gradle build configuration
└── build.gradle.kts                 # Root Gradle configuration
```

### Method Channels

The plugin exposes two method channels:

1. **Streaming Channel** (`com.ipcamera/streaming`):
   - `getCameras()` - Enumerate available cameras
   - `getResolutions(cameraId)` - Get supported resolutions
   - `startStreaming(config)` - Start streaming
   - `stopStreaming()` - Stop streaming
   - `getStatistics()` - Get streaming statistics
   - Permission management methods

2. **Network Channel** (`com.ipcamera/network`):
   - `startNetworkMonitoring()` - Start monitoring network changes
   - `stopNetworkMonitoring()` - Stop monitoring
   - `getCurrentNetwork()` - Get current network info
   - `onNetworkChanged` - Callback for network changes

### Building Android

Flutter handles the Gradle build automatically:

```bash
# Development build
flutter run -d android

# Release APK
flutter build apk --release

# Release App Bundle
flutter build appbundle --release
```

### Gradle Configuration

The `android/app/build.gradle.kts` file configures:
- Application ID: `com.ipcamera.ip_camera_streaming`
- Min SDK: 28 (Android 9.0)
- Target SDK: 34 (Android 14)
- Kotlin JVM target: 11

### Environment Variables

#### Required
- `ANDROID_HOME` or `ANDROID_SDK_ROOT`: Path to Android SDK

#### Optional
- `NDK_HOME`: Path to Android NDK (for future native library compilation)

## iOS Build System

### CocoaPods Dependencies

The iOS project uses CocoaPods for native dependencies:

```ruby
# Podfile
pod 'Live555', '~> 1.0'  # RTSP server
pod 'librtmp', '~> 2.4'  # RTMP client
```

### Building iOS

```bash
# Install pods
cd ios && pod install

# Build with Flutter
flutter build ios --release

# Or use Makefile
make build-ios
```

### Running on Device

```bash
# Development mode
flutter run -d ios

# Or use Makefile
make dev-ios
```

## Flutter Build System

### Standard Flutter Commands

```bash
# Get dependencies
flutter pub get

# Run in development
flutter run

# Build for release
flutter build ios --release
flutter build apk --release

# Run tests
flutter test

# Analyze code
flutter analyze

# Format code
dart format lib/ test/
```

## Troubleshooting

### Android SDK Not Found

**Error:** `ANDROID_HOME or ANDROID_SDK_ROOT environment variable not set`

**Solution:**
```bash
# macOS/Linux
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$PATH:$ANDROID_HOME/tools:$ANDROID_HOME/platform-tools

# Add to ~/.zshrc or ~/.bashrc for persistence
```

### Gradle Build Failed

**Error:** Gradle build errors

**Solution:**
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter build apk

# Or manually clean Gradle
cd android && ./gradlew clean
```

### NDK Build Failed (Future)

**Error:** `ndk-build not found`

**Solution:**
```bash
# Install Android NDK via Android Studio
# Or set NDK_HOME
export NDK_HOME=$ANDROID_HOME/ndk/25.1.8937393
```

### CocoaPods Issues

**Error:** `pod install` fails

**Solution:**
```bash
# Update CocoaPods
sudo gem install cocoapods

# Clean and reinstall
cd ios
rm -rf Pods Podfile.lock
pod install
```

### Flutter Not Found

**Error:** `flutter: command not found`

**Solution:**
```bash
# Install Flutter SDK
# Follow instructions at https://docs.flutter.dev/get-started/install

# Verify installation
flutter doctor
```

## Advanced Usage

### Custom Build Configurations

#### Modify Gradle Configuration

Edit `android/app/build.gradle.kts` to customize build behavior:

```kotlin
android {
    defaultConfig {
        minSdk = 28
        targetSdk = 34
        versionCode = 5
        versionName = "0.0.5"
    }
    
    buildTypes {
        release {
            // Add custom release configuration
            isMinifyEnabled = true
            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"))
        }
    }
}
```

#### Modify Makefile

Edit `Makefile` to add custom targets:

```makefile
# Example: Add a release build target
release: clean
	flutter build ios --release
	flutter build apk --release
```

### Continuous Integration

#### GitHub Actions Example

```yaml
name: Build

on: [push, pull_request]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: actions/setup-java@v2
        with:
          java-version: '11'
      - uses: subosito/flutter-action@v2
      - run: make install-deps
      - run: make test
      - run: make build-android
```

## Performance Tips

### Faster Builds

1. **Use Hot Reload**: Use `flutter run` for development (instant updates)
2. **Incremental Builds**: Flutter and Gradle automatically use incremental compilation
3. **Skip Tests**: Use `make build-android` instead of `make test && make build-android`
4. **Gradle Daemon**: Gradle daemon is enabled by default for faster builds

### Reduce Build Size

1. **Enable ProGuard/R8**: Add code shrinking (future enhancement)
2. **Remove Unused Resources**: Use resource shrinking
3. **Optimize Images**: Compress assets before building

## References

- [Flutter Build Modes](https://docs.flutter.dev/testing/build-modes)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)
- [Android Build Tools](https://developer.android.com/studio/command-line)
- [Gradle Build Configuration](https://docs.gradle.org/current/userguide/userguide.html)
- [CocoaPods Guide](https://guides.cocoapods.org/)

## Migration from Gulp to Flutter

### What Changed

The project migrated from a custom Gulp-based build system to Flutter's standard plugin architecture:

**Before:**
- Standalone Gradle configuration
- Gulp for Android build orchestration
- Node.js dependencies
- Custom build scripts

**After:**
- Flutter plugin architecture
- Standard Flutter/Gradle build
- Method channels for platform communication
- No Node.js dependencies

### Migration Benefits

1. **Simplified Dependencies**: No need for Node.js or Gulp
2. **Standard Flutter Workflow**: Use familiar Flutter commands
3. **Better IDE Support**: Full Android Studio and VS Code integration
4. **Hot Reload**: Instant UI updates during development
5. **Unified Build System**: One build system for all platforms

## Support

For build system issues:
1. Check this guide first
2. Run `flutter doctor` to verify setup
3. Open an issue on GitHub
4. Ask in Discussions

---

**Last Updated:** December 3, 2025  
**Build System Version:** 0.0.4 (Flutter Plugin Architecture)
