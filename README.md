# IP Camera Streaming Platform

Transform your iOS or Android device into a professional IP camera with support for RTSP local streaming and RTMP cloud streaming to YouTube, Twitch, and custom servers.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](https://opensource.org/licenses/MIT)
[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20Android-lightgrey.svg)](https://github.com/yourusername/ip-camera-streaming)
[![Test](https://github.com/yourusername/ip-camera-streaming/actions/workflows/test.yml/badge.svg)](https://github.com/yourusername/ip-camera-streaming/actions/workflows/test.yml)
[![Build and Release](https://github.com/yourusername/ip-camera-streaming/actions/workflows/build-and-release.yml/badge.svg)](https://github.com/yourusername/ip-camera-streaming/actions/workflows/build-and-release.yml)

## ✨ Features

### 🎥 Professional Streaming
- **H.264/AAC Hardware Encoding**: Efficient, high-quality video and audio encoding
- **RTSP Server**: Stream to OBS, VLC, or any RTSP client on your local network
- **RTMP Client**: Stream directly to YouTube, Twitch, or custom RTMP servers
- **Multi-Protocol**: Run RTSP and RTMP simultaneously

### 📱 Multi-Camera Support
- Access **all device cameras**: front, back, telephoto, ultra-wide, and more
- Switch cameras on the fly
- Device-specific optimizations for iPhone and Android flagships

### ⚙️ Flexible Configuration
- **Resolution**: 720p, 1080p, and all device-supported resolutions
- **Frame Rate**: 30 FPS or 60 FPS
- **Bitrate**: 1-10 Mbps with real-time adjustment
- **Audio**: Toggle audio on/off, select microphone source

### 📊 Real-Time Monitoring
- Live bitrate and FPS display
- Dropped frame counter
- Connection status for each protocol
- Performance warnings (temperature, battery)
- Network status and bandwidth estimates

### 🔒 Security & Privacy
- Secure credential storage (iOS Keychain, Android EncryptedSharedPreferences)
- Optional RTSP authentication
- No analytics or telemetry by default
- Open source and auditable

### 🌐 Network Resilience
- Automatic reconnection with exponential backoff
- Network change detection
- Cellular data warnings
- Graceful degradation under poor conditions

## 🚀 Quick Start

### Prerequisites

**For Users:**
- iOS 15.0+ or Android 11+ device
- WiFi or cellular connection
- Camera and microphone permissions

**For Developers:**
- Flutter SDK 3.0+
- Xcode 14+ (for iOS development)
- Android SDK with NDK (for Android development)
- CocoaPods (for iOS dependencies)

### Installation

#### From Releases (Users)

**iOS:**
1. Download the latest `.ipa` from [Releases](https://github.com/yourusername/ip-camera-streaming/releases)
2. Install via TestFlight or sideload with AltStore

**Android:**
1. Download the latest `.apk` from [Releases](https://github.com/yourusername/ip-camera-streaming/releases)
2. Enable "Install from Unknown Sources"
3. Install the APK

#### From Source (Developers)

```bash
# Clone the repository
git clone https://github.com/yourusername/ip-camera-streaming.git
cd ip-camera-streaming

# Install dependencies
make install-deps

# Build for iOS
make build-ios

# Build for Android
make build-android

# Run in development mode
make dev-ios    # or make dev-android
```

## 📖 Usage

### Basic Streaming

1. **Launch the app** and grant camera/microphone permissions
2. **Select your camera** from the dropdown
3. **Configure quality** (resolution, FPS, bitrate)
4. **Choose streaming mode**:
   - **RTSP**: For local network streaming to OBS/VLC
   - **RTMP**: For cloud streaming to YouTube/Twitch
   - **Both**: Stream locally and to the cloud simultaneously
5. **Tap "Start Streaming"**

### RTSP Streaming (Local Network)

1. Enable RTSP in settings
2. Note the displayed stream URL (e.g., `rtsp://192.168.1.50:8554/live`)
3. Tap the URL to copy to clipboard
4. In OBS:
   - Add "Media Source"
   - Uncheck "Local File"
   - Input: `rtsp://YOUR_PHONE_IP:8554/live`
   - Click OK

### RTMP Streaming (YouTube/Twitch)

**YouTube:**
1. Go to [YouTube Studio](https://studio.youtube.com) → Go Live
2. Copy your Stream URL and Stream Key
3. In the app, go to RTMP Settings
4. Enter YouTube URL and Stream Key
5. Enable YouTube target
6. Start streaming

**Twitch:**
1. Go to [Twitch Dashboard](https://dashboard.twitch.tv/settings/stream)
2. Copy your Stream Key
3. In the app, go to RTMP Settings
4. Enter `rtmp://live.twitch.tv/app` and your Stream Key
5. Enable Twitch target
6. Start streaming

### Advanced Configuration

**Custom RTSP Port:**
- Settings → RTSP → Port (default: 8554)

**Multiple RTMP Targets:**
- Add up to 2 simultaneous RTMP destinations
- Each target can be enabled/disabled independently

**Streaming Presets:**
- Save your favorite configurations as presets
- Quick-switch between different setups

## 🏗️ Architecture

### High-Level Overview

```
┌─────────────────────────────────────┐
│       Flutter UI Layer (Dart)       │
│  • Configuration                    │
│  • Controls                         │
│  • Statistics Display               │
└─────────────────────────────────────┘
              ↕ Platform Channels
┌─────────────────────────────────────┐
│   Native Layer (Swift/Kotlin)       │
│  ┌─────────────────────────────┐   │
│  │   Camera Capture            │   │
│  │   • AVFoundation (iOS)      │   │
│  │   • Camera2 (Android)       │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │   Hardware Encoding         │   │
│  │   • VideoToolbox (iOS)      │   │
│  │   • MediaCodec (Android)    │   │
│  └─────────────────────────────┘   │
│  ┌─────────────────────────────┐   │
│  │   Streaming Protocols       │   │
│  │   • RTSP (Live555)          │   │
│  │   • RTMP (librtmp)          │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Key Technologies

- **Flutter**: Cross-platform UI framework
- **AVFoundation**: iOS camera and audio capture
- **Camera2**: Android camera capture
- **VideoToolbox**: iOS hardware H.264 encoding
- **MediaCodec**: Android hardware H.264 encoding
- **Live555**: LGPL RTSP server library
- **librtmp**: LGPL RTMP client library

## 🛠️ Development

### Project Structure

```
ip-camera-streaming/
├── lib/                    # Flutter/Dart code
│   ├── main.dart
│   ├── controllers/
│   ├── models/
│   ├── screens/
│   └── services/
├── ios/                    # iOS native code
│   ├── Runner/
│   │   ├── StreamingManager.swift
│   │   ├── CameraCapture.swift
│   │   ├── VideoEncoder.swift
│   │   ├── RTSPServer.swift
│   │   └── RTMPClient.swift
│   └── Podfile
├── android/                # Android native code (Flutter plugin)
│   ├── app/src/main/kotlin/
│   │   └── com/ipcamera/ip_camera_streaming/
│   │       ├── MainActivity.kt
│   │       ├── serv/
│   │       │   ├── StreamingManager.kt
│   │       │   └── NetworkMonitor.kt
│   │       └── streaming/
│   │           ├── CameraCapture.kt
│   │           ├── VideoEncoder.kt
│   │           ├── RTSPServer.kt
│   │           └── RTMPClient.kt
│   └── app/build.gradle.kts
├── Makefile               # Build automation
├── .kiro/specs/           # Feature specifications
└── docs/                  # Additional documentation
```

### Build System

The project uses Flutter's standard build system with native plugins:
- **Flutter**: Standard Flutter build for UI layer and build orchestration
- **iOS**: CocoaPods for native dependencies
- **Android**: Gradle (via Flutter) for native plugin compilation

**Common Commands:**

```bash
# Install all dependencies
make install-deps

# Build for production
make build-ios
make build-android

# Development builds
make dev-ios
make dev-android

# Run tests
make test

# Clean build artifacts
make clean
```

### Testing

The project uses a comprehensive testing strategy:

**Property-Based Testing:**
- 41 correctness properties validated
- Uses fast-check (Dart), SwiftCheck (iOS), kotlinx-quickcheck (Android)
- Each test runs 100+ iterations

**Unit Testing:**
- Component-level tests for critical functionality
- Mock-free testing where possible

**Integration Testing:**
- End-to-end workflow validation
- Real device testing on iOS and Android

```bash
# Run all tests
flutter test

# Run iOS native tests
cd ios && xcodebuild test -workspace Runner.xcworkspace -scheme Runner

# Run tests via Makefile
make test
```

### CI/CD Pipeline

The project uses GitHub Actions for automated testing and releases:

**Automated Testing:**
- Runs on all branches except `main`
- Flutter tests with code coverage
- Android lint and unit tests
- iOS build validation and unit tests

**Automated Releases:**
- Triggered when PRs are merged to `main`
- Builds iOS and Android binaries automatically
- Creates GitHub releases with semantic versioning
- Attaches APK, AAB, and IPA files

**Semantic Versioning:**
- Version format: `MAJOR.MINOR.PATCH+BUILD`
- Automatic version bumping based on PR labels:
  - `major` or `breaking` → Major version bump
  - `feature`, `minor`, or `enhancement` → Minor version bump
  - `patch` or no label → Patch version bump

```bash
# Bump version locally
./scripts/bump_version.sh [major|minor|patch]

# Example: bump minor version
./scripts/bump_version.sh minor
```

See [docs/CI_CD_WORKFLOW.md](docs/CI_CD_WORKFLOW.md) for complete CI/CD documentation.

## 📋 Roadmap

See [ROADMAP.md](ROADMAP.md) for detailed development plans.

**Current Phase:** Foundation (Months 1-2)
- ✅ Requirements and design complete
- 🚧 Flutter project structure
- 🚧 Build system migration
- ⏳ iOS native implementation
- ⏳ Android native implementation

**Next Milestones:**
- Month 3: iOS streaming functional
- Month 4: Android streaming functional
- Month 5: Feature complete
- Month 6: Public release

## 🤝 Contributing

We welcome contributions! Please see [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

Before contributing, please read our [Code of Conduct](CODE_OF_CONDUCT.md).

**Ways to Contribute:**
- 🐛 Report bugs via [GitHub Issues](https://github.com/yourusername/ip-camera-streaming/issues)
- 💡 Suggest features via [Discussions](https://github.com/yourusername/ip-camera-streaming/discussions)
- 📝 Improve documentation
- 🔧 Submit pull requests
- 🌍 Translate the app

**Development Setup:**
1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Make your changes
4. Run tests (`make test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## 📄 License

This project is licensed under the **MIT License**.

This means:
- ✅ You can use this software for any purpose
- ✅ You can modify the software
- ✅ You can distribute the software
- ✅ You can use it in commercial applications
- ✅ You can sublicense the software
- ⚠️ You must include copyright and license notices

See [LICENSE](LICENSE) for full details.

### Third-Party Licenses

- **Flutter**: BSD 3-Clause License
- **Live555**: LGPL v2.1
- **librtmp**: LGPL v2.1
- **AVFoundation, VideoToolbox, Camera2, MediaCodec**: Proprietary platform SDKs (allowed dependencies)

## 🙏 Acknowledgments

This project builds upon:
- **RemoteCam** - Original Android MJPEG streaming app
- **Live555** - RTSP server library by Live Networks, Inc.
- **librtmp** - RTMP client library from RTMPDump project
- **Flutter** - Google's UI framework
- The open source community

## 📞 Support

- **Documentation**: [Wiki](https://github.com/yourusername/ip-camera-streaming/wiki)
- **Issues**: [GitHub Issues](https://github.com/yourusername/ip-camera-streaming/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/ip-camera-streaming/discussions)
- **Email**: support@example.com

## 🌟 Star History

If you find this project useful, please consider giving it a star! ⭐

## 📊 Project Status

![GitHub release](https://img.shields.io/github/v/release/yourusername/ip-camera-streaming)
![GitHub issues](https://img.shields.io/github/issues/yourusername/ip-camera-streaming)
![GitHub pull requests](https://img.shields.io/github/issues-pr/yourusername/ip-camera-streaming)
![GitHub contributors](https://img.shields.io/github/contributors/yourusername/ip-camera-streaming)

---

**Made with ❤️ by the open source community**
