# Device Testing README

## Overview

This document provides instructions for running platform-specific tests on iOS and Android physical devices. Task 29 of the implementation plan requires comprehensive validation on actual hardware to ensure all features work correctly.

## Quick Start

### Prerequisites

1. **Physical Devices:**
   - iOS: iPhone 12 or later with iOS 15+
   - Android: Pixel 5 or later with Android 11+

2. **Development Environment:**
   - Flutter SDK installed and configured
   - Xcode (for iOS testing) or Android Studio (for Android testing)
   - USB cables for device connection

3. **External Tools:**
   - OBS Studio (for RTSP testing)
   - VLC Media Player (for RTSP testing)
   - YouTube account with streaming enabled
   - Twitch account with streaming enabled

### Running Tests

#### Option 1: Using the Test Runner Script (Recommended)

```bash
# Make the script executable (first time only)
chmod +x scripts/device_test_runner.sh

# Run the test runner
./scripts/device_test_runner.sh
```

The script will guide you through:
1. Selecting the platform (iOS/Android/Both)
2. Choosing test type (Automated/Manual/Both)
3. Running automated validation tests
4. Opening the manual testing guide

#### Option 2: Manual Test Execution

**Run Automated Tests:**
```bash
# On specific device
flutter test test/platform_validation_test.dart -d <device-id>

# On all connected devices
flutter test test/platform_validation_test.dart
```

**Open Manual Testing Guide:**
```bash
# macOS
open docs/PLATFORM_TESTING_GUIDE.md

# Linux
xdg-open docs/PLATFORM_TESTING_GUIDE.md

# Or open manually in your markdown viewer
```

## Test Categories

### 1. Automated Platform Validation Tests

Located in: `test/platform_validation_test.dart`

These tests verify:
- Platform channel communication
- Camera enumeration
- Multi-camera device support
- Resolution availability
- Standard resolution support (720p, 1080p)
- RTSP configuration acceptance
- RTMP configuration acceptance

**Running:**
```bash
flutter test test/platform_validation_test.dart -d <device-id>
```

### 2. Manual Platform Testing

Located in: `docs/PLATFORM_TESTING_GUIDE.md`

These tests verify:
- Hardware encoding (VideoToolbox on iOS, MediaCodec on Android)
- RTSP streaming with OBS Studio
- RTSP streaming with VLC Media Player
- RTMP streaming to YouTube
- RTMP streaming to Twitch
- Multi-protocol simultaneous streaming
- Camera switching on multi-camera devices

**Process:**
1. Open the testing guide
2. Follow step-by-step procedures for each test
3. Document results in the guide
4. Sign off on completed tests

## iOS Device Testing

### Setup

1. Connect iPhone via USB to Mac
2. Open Xcode and trust the device
3. Build and deploy:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run -d <ios-device-id>
   ```
4. Grant camera and microphone permissions

### Key Tests

- **Camera Enumeration:** Verify all cameras (front, back, telephoto, ultra-wide) are detected
- **VideoToolbox Encoding:** Verify hardware H.264 encoding works
- **RTSP Server:** Test with OBS and VLC on local network
- **RTMP Client:** Test streaming to YouTube and Twitch

### Expected Results

- All physical cameras accessible
- Hardware encoding with low CPU usage (< 40%)
- Device temperature stays reasonable (< 45°C)
- RTSP clients can connect and view stream
- RTMP streams successfully to cloud services

## Android Device Testing

### Setup

1. Enable Developer Options on Android device
2. Enable USB Debugging
3. Connect device via USB
4. Build and deploy:
   ```bash
   flutter run -d <android-device-id>
   ```
5. Grant camera and microphone permissions

### Key Tests

- **Camera Enumeration:** Verify all cameras detected via Camera2 API
- **MediaCodec Encoding:** Verify hardware H.264 encoding works
- **RTSP Server:** Test with OBS and VLC on local network
- **RTMP Client:** Test streaming to YouTube and Twitch

### Expected Results

- All physical cameras accessible
- Hardware encoding with low CPU usage (< 40%)
- Device temperature stays reasonable (< 45°C)
- RTSP clients can connect and view stream
- RTMP streams successfully to cloud services

## RTSP Testing with External Clients

### OBS Studio Testing

1. Start streaming on device
2. Note the RTSP URL (e.g., rtsp://192.168.1.50:8554/live)
3. In OBS:
   - Add Media Source
   - Enter RTSP URL
   - Verify video and audio playback
4. Test for 2+ minutes of continuous streaming

**Expected:** Smooth playback, low latency (< 500ms), synchronized audio

### VLC Media Player Testing

1. Start streaming on device
2. In VLC:
   - Media → Open Network Stream
   - Enter RTSP URL
   - Click Play
3. Test multiple VLC instances (up to 3 concurrent)

**Expected:** All clients connect successfully, smooth playback

## RTMP Testing with Cloud Services

### YouTube Live Testing

1. Get Stream URL and Key from YouTube Studio
2. Configure in app's RTMP Setup screen
3. Start streaming
4. Verify stream appears in YouTube Studio
5. Check stream health indicators
6. Test for 5+ minutes

**Expected:** "Excellent" or "Good" stream health, stable connection

### Twitch Testing

1. Get Server URL and Stream Key from Twitch Dashboard
2. Configure in app's RTMP Setup screen
3. Start streaming
4. Verify stream appears in Twitch Dashboard
5. Check stream health and bitrate
6. Test for 5+ minutes

**Expected:** Stable bitrate, good quality, no disconnections

## Multi-Camera Device Testing

### Camera Switching Test

1. Start streaming with one camera
2. Switch to each available camera:
   - Front camera
   - Back camera (main)
   - Telephoto (if available)
   - Ultra-wide (if available)
3. Verify smooth transitions
4. Check that stream continues without errors

**Expected:** Seamless camera switching, stream restarts with new camera

## Performance Benchmarking

### Metrics to Collect

For each configuration (720p30, 1080p30, 1080p60):

- **CPU Usage:** Should be < 40% on mid-range devices
- **Memory Usage:** Should be < 200MB
- **Battery Drain:** Should be < 15% per hour
- **Device Temperature:** Should stay < 45°C during normal streaming
- **Frame Drops:** Should be minimal (< 1% of frames)

### How to Measure

1. Start streaming with specific configuration
2. Monitor device performance for 10 minutes
3. Record metrics in PLATFORM_TESTING_GUIDE.md
4. Compare against expected values

## Troubleshooting

### Common Issues

**Camera not detected:**
- Verify permissions are granted
- Restart the app
- Check device camera works in native camera app

**RTSP connection fails:**
- Verify device and computer on same network
- Check firewall settings
- Try different port number

**RTMP connection fails:**
- Verify stream URL and key are correct
- Check internet connection
- Verify streaming enabled on account

**Poor performance:**
- Reduce resolution to 720p
- Lower frame rate to 30 FPS
- Reduce bitrate
- Check device is not overheating

## Test Results Documentation

### Recording Results

1. Open `docs/PLATFORM_TESTING_GUIDE.md`
2. Fill in test results for each test case
3. Mark tests as Pass/Fail
4. Document any issues found
5. Record performance metrics
6. Sign off when complete

### Test Summary Template

```
Platform: iOS / Android
Device Model: _______________
OS Version: _______________
Test Date: _______________

Automated Tests: Pass / Fail
Manual Tests: Pass / Fail
RTSP Tests: Pass / Fail
RTMP Tests: Pass / Fail

Overall Result: Pass / Pass with Issues / Fail

Notes:
_______________
```

## Requirements Validation

This testing validates the following requirements:

- **1.1:** iOS device provides full streaming functionality
- **1.2:** Android device provides full streaming functionality
- **3.3:** RTSP server serves H.264/AAC to clients
- **4.2:** YouTube RTMP streaming works
- **4.3:** Twitch RTMP streaming works
- **5.2:** All cameras are enumerated and accessible

## Next Steps After Testing

1. **Review Results:** Analyze all test results and performance metrics
2. **Document Issues:** Record any bugs or issues found
3. **Performance Tuning:** Optimize based on performance data
4. **User Acceptance:** Get sign-off from stakeholders
5. **Production Release:** Prepare for deployment

## Support and Questions

If you encounter issues during testing:

1. Check the Troubleshooting section above
2. Review the detailed PLATFORM_TESTING_GUIDE.md
3. Check existing test implementations for examples
4. Consult the design document for expected behavior

## Continuous Testing

These tests should be run:

- Before each release
- After major platform updates (iOS/Android)
- When adding new camera support
- After modifying encoding or streaming code
- When investigating user-reported issues

## Conclusion

Comprehensive device testing ensures the IP Camera Streaming Platform works reliably across different devices and integrates properly with external streaming clients. Follow this guide to validate all platform-specific functionality and document results for future reference.
