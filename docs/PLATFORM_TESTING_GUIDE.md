# Platform-Specific Testing and Validation Guide

## Overview

This document provides comprehensive testing procedures for validating the IP Camera Streaming Platform on physical iOS and Android devices. These tests verify that all features work correctly across different platforms and integrate properly with external streaming clients.

## Prerequisites

### Hardware Requirements

**iOS Testing:**
- iPhone 12 or later
- iOS 15.0 or later
- Multi-camera device (iPhone 12 Pro or later recommended)
- USB cable for device connection
- Mac with Xcode installed

**Android Testing:**
- Pixel 5 or later (or equivalent device with Camera2 API support)
- Android 11 or later
- Multi-camera device recommended
- USB cable for device connection
- Android Studio or ADB tools installed

### Software Requirements

**Streaming Clients:**
- OBS Studio (latest version) - for RTSP testing
- VLC Media Player (latest version) - for RTSP testing
- YouTube account with streaming enabled - for RTMP testing
- Twitch account with streaming enabled - for RTMP testing

**Network Setup:**
- WiFi network with both device and testing computer connected
- Stable internet connection for RTMP testing
- Router with port forwarding capabilities (optional, for advanced testing)

## Test Procedures

### 1. iOS Physical Device Testing

#### 1.1 Device Setup

1. Connect iPhone to Mac via USB
2. Open Xcode and select the connected device as target
3. Build and deploy the application:
   ```bash
   cd ios
   pod install
   cd ..
   flutter run -d <device-id>
   ```
4. Grant camera and microphone permissions when prompted
5. Verify app launches successfully

#### 1.2 Camera Enumeration Test

**Objective:** Verify all physical cameras are detected and accessible
**Requirements:** 5.2

**Test Steps:**
1. Open the Configuration screen
2. Tap on Camera Selection dropdown
3. Verify all cameras are listed:
   - Front Camera (Wide)
   - Back Camera (Wide)
   - Back Camera (Telephoto) - if available
   - Back Camera (Ultra Wide) - if available
4. For each camera:
   - Select the camera
   - Verify preview shows correct camera feed
   - Verify available resolutions update for that camera
   - Take note of supported resolutions

**Expected Results:**
- All physical cameras appear in the list
- Each camera has a unique identifier
- Preview switches correctly when camera is changed
- Resolution list updates based on camera capabilities

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Device Model: _______________
Cameras Detected: _______________
Issues Found: _______________
```

#### 1.3 Hardware Encoding Test (iOS)

**Objective:** Verify VideoToolbox H.264 and AAC encoding
**Requirements:** 2.3, 2.5

**Test Steps:**
1. Configure streaming with:
   - Resolution: 1080p
   - Frame Rate: 30 FPS
   - Bitrate: 5 Mbps
   - Audio: Enabled
2. Start streaming
3. Monitor device temperature and CPU usage
4. Stream for 5 minutes continuously
5. Check statistics screen for:
   - Actual bitrate (should be ~5 Mbps ±20%)
   - Actual FPS (should be ~30 FPS ±10%)
   - Dropped frames (should be minimal)

**Expected Results:**
- Streaming starts without errors
- Hardware encoder initializes successfully
- Device remains cool (< 45°C)
- CPU usage reasonable (< 40%)
- Statistics match configured values

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Device Temperature: _______________
CPU Usage: _______________
Actual Bitrate: _______________
Actual FPS: _______________
Dropped Frames: _______________
```

### 2. Android Physical Device Testing

#### 2.1 Device Setup

1. Enable Developer Options on Android device
2. Enable USB Debugging
3. Connect device via USB
4. Build and deploy the application:
   ```bash
   flutter run -d <device-id>
   ```
5. Grant camera and microphone permissions when prompted
6. Verify app launches successfully

#### 2.2 Camera Enumeration Test

**Objective:** Verify all physical cameras are detected via Camera2 API
**Requirements:** 5.2

**Test Steps:**
1. Open the Configuration screen
2. Tap on Camera Selection dropdown
3. Verify all cameras are listed:
   - Front Camera
   - Back Camera (Main)
   - Back Camera (Telephoto) - if available
   - Back Camera (Ultra Wide) - if available
4. For each camera:
   - Select the camera
   - Verify preview shows correct camera feed
   - Verify available resolutions update for that camera
   - Take note of supported resolutions

**Expected Results:**
- All physical cameras appear in the list
- Each camera has a unique identifier
- Preview switches correctly when camera is changed
- Resolution list updates based on camera capabilities

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Device Model: _______________
Cameras Detected: _______________
Issues Found: _______________
```

#### 2.3 Hardware Encoding Test (Android)

**Objective:** Verify MediaCodec H.264 and AAC encoding
**Requirements:** 2.4, 2.5

**Test Steps:**
1. Configure streaming with:
   - Resolution: 1080p
   - Frame Rate: 30 FPS
   - Bitrate: 5 Mbps
   - Audio: Enabled
2. Start streaming
3. Monitor device temperature and CPU usage
4. Stream for 5 minutes continuously
5. Check statistics screen for:
   - Actual bitrate (should be ~5 Mbps ±20%)
   - Actual FPS (should be ~30 FPS ±10%)
   - Dropped frames (should be minimal)

**Expected Results:**
- Streaming starts without errors
- Hardware encoder initializes successfully
- Device remains cool (< 45°C)
- CPU usage reasonable (< 40%)
- Statistics match configured values

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Device Temperature: _______________
CPU Usage: _______________
Actual Bitrate: _______________
Actual FPS: _______________
Dropped Frames: _______________
```

### 3. RTSP Streaming with OBS Studio

#### 3.1 OBS Setup

1. Launch OBS Studio on testing computer
2. Ensure computer is on same WiFi network as device
3. Add new Media Source:
   - Click "+" in Sources panel
   - Select "Media Source"
   - Name it "IP Camera Stream"

#### 3.2 RTSP Streaming Test

**Objective:** Verify RTSP server serves valid H.264/AAC streams to OBS
**Requirements:** 3.3

**Test Steps:**
1. On device, configure RTSP:
   - Enable RTSP
   - Set port to 8554 (default)
   - Note the displayed stream URL (e.g., rtsp://192.168.1.50:8554/live)
2. Tap the stream URL to copy to clipboard
3. Start streaming on device
4. In OBS Media Source settings:
   - Uncheck "Local File"
   - Paste RTSP URL in "Input" field
   - Check "Restart playback when source becomes active"
   - Click OK
5. Verify video appears in OBS preview
6. Check audio levels in OBS mixer
7. Test for 2 minutes of continuous streaming

**Expected Results:**
- OBS connects to RTSP stream successfully
- Video displays with correct resolution and frame rate
- Audio is present and synchronized with video
- No buffering or stuttering
- Latency < 500ms

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Stream URL: _______________
Connection Time: _______________
Observed Latency: _______________
Video Quality: _______________
Audio Quality: _______________
Issues: _______________
```

### 4. RTSP Streaming with VLC Media Player

#### 4.1 VLC Streaming Test

**Objective:** Verify RTSP compatibility with VLC client
**Requirements:** 3.3

**Test Steps:**
1. Launch VLC Media Player
2. On device, ensure RTSP streaming is active
3. In VLC:
   - Go to Media → Open Network Stream
   - Paste RTSP URL (e.g., rtsp://192.168.1.50:8554/live)
   - Click Play
4. Verify video playback starts
5. Check audio playback
6. Test for 2 minutes of continuous streaming
7. Test with multiple VLC instances (up to 3 concurrent connections)

**Expected Results:**
- VLC connects and plays stream successfully
- Video displays smoothly
- Audio is synchronized
- Multiple clients can connect simultaneously (up to 3)
- No connection errors

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Number of Concurrent Clients Tested: _______________
Connection Success Rate: _______________
Playback Quality: _______________
Issues: _______________
```

### 5. RTMP Streaming to YouTube

#### 5.1 YouTube Setup

1. Log into YouTube Studio
2. Go to "Go Live" section
3. Select "Stream" option
4. Copy the Stream URL (e.g., rtmp://a.rtmp.youtube.com/live2)
5. Copy the Stream Key (keep this private)

#### 5.2 YouTube RTMP Test

**Objective:** Verify RTMP client successfully streams to YouTube
**Requirements:** 4.2

**Test Steps:**
1. On device, open RTMP Setup screen
2. Configure YouTube target:
   - Enter Stream URL
   - Enter Stream Key
   - Enable YouTube target
3. Configure streaming:
   - Resolution: 1080p
   - Frame Rate: 30 FPS
   - Bitrate: 4-6 Mbps (YouTube recommended)
4. Start streaming
5. In YouTube Studio, verify stream appears in preview
6. Check stream health indicators
7. Stream for 5 minutes
8. Monitor for connection stability

**Expected Results:**
- RTMP connection establishes successfully
- YouTube shows "Excellent" or "Good" stream health
- Video and audio quality are acceptable
- No disconnections or buffering
- Reconnection works if connection is interrupted

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Stream Health: _______________
Connection Time: _______________
Disconnections: _______________
Reconnection Success: _______________
Issues: _______________
```

### 6. RTMP Streaming to Twitch

#### 6.1 Twitch Setup

1. Log into Twitch
2. Go to Creator Dashboard
3. Navigate to Settings → Stream
4. Copy the Server URL (e.g., rtmp://live.twitch.tv/app)
5. Copy the Stream Key (keep this private)

#### 6.2 Twitch RTMP Test

**Objective:** Verify RTMP client successfully streams to Twitch
**Requirements:** 4.3

**Test Steps:**
1. On device, open RTMP Setup screen
2. Configure Twitch target:
   - Enter Stream URL
   - Enter Stream Key
   - Enable Twitch target
3. Configure streaming:
   - Resolution: 1080p
   - Frame Rate: 30 FPS
   - Bitrate: 4-6 Mbps (Twitch recommended)
4. Start streaming
5. In Twitch Dashboard, verify stream appears
6. Check stream health and bitrate
7. Stream for 5 minutes
8. Monitor for connection stability

**Expected Results:**
- RTMP connection establishes successfully
- Twitch shows stable bitrate and quality
- Video and audio quality are acceptable
- No disconnections or buffering
- Reconnection works if connection is interrupted

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Stream Health: _______________
Connection Time: _______________
Disconnections: _______________
Reconnection Success: _______________
Issues: _______________
```

### 7. Multi-Protocol Simultaneous Streaming

#### 7.1 Simultaneous RTSP + RTMP Test

**Objective:** Verify device can stream to RTSP and RTMP simultaneously
**Requirements:** 5.11

**Test Steps:**
1. Configure both RTSP and RTMP:
   - Enable RTSP (port 8554)
   - Enable YouTube or Twitch RTMP
2. Start streaming
3. Connect OBS to RTSP stream
4. Verify RTMP stream appears on YouTube/Twitch
5. Monitor device performance:
   - CPU usage
   - Temperature
   - Battery drain
   - Memory usage
6. Stream for 5 minutes
7. Verify both streams remain stable

**Expected Results:**
- Both protocols stream simultaneously
- Device performance remains acceptable
- No significant frame drops
- Both streams maintain quality
- Statistics show healthy metrics for both

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
CPU Usage: _______________
Device Temperature: _______________
Battery Drain Rate: _______________
RTSP Quality: _______________
RTMP Quality: _______________
Issues: _______________
```

### 8. Multi-Camera Device Testing

#### 8.1 Camera Switching Test

**Objective:** Verify seamless switching between cameras
**Requirements:** 5.2, 5.4

**Test Steps:**
1. Start streaming with back camera (main)
2. While streaming, switch to:
   - Front camera
   - Telephoto camera (if available)
   - Ultra-wide camera (if available)
3. For each switch:
   - Verify preview updates immediately
   - Verify stream continues without interruption
   - Check that resolution options update
   - Monitor for any errors

**Expected Results:**
- Camera switches smoothly
- Stream restarts with new camera
- No crashes or errors
- Preview and stream match selected camera
- Resolution list updates correctly

**Pass/Fail:** ☐ Pass ☐ Fail

**Notes:**
```
Cameras Tested: _______________
Switch Time: _______________
Issues: _______________
```

## Test Results Summary

### iOS Testing

| Test | Status | Notes |
|------|--------|-------|
| Camera Enumeration | ☐ Pass ☐ Fail | |
| Hardware Encoding | ☐ Pass ☐ Fail | |
| RTSP with OBS | ☐ Pass ☐ Fail | |
| RTSP with VLC | ☐ Pass ☐ Fail | |
| RTMP to YouTube | ☐ Pass ☐ Fail | |
| RTMP to Twitch | ☐ Pass ☐ Fail | |
| Multi-Protocol | ☐ Pass ☐ Fail | |
| Camera Switching | ☐ Pass ☐ Fail | |

### Android Testing

| Test | Status | Notes |
|------|--------|-------|
| Camera Enumeration | ☐ Pass ☐ Fail | |
| Hardware Encoding | ☐ Pass ☐ Fail | |
| RTSP with OBS | ☐ Pass ☐ Fail | |
| RTSP with VLC | ☐ Pass ☐ Fail | |
| RTMP to YouTube | ☐ Pass ☐ Fail | |
| RTMP to Twitch | ☐ Pass ☐ Fail | |
| Multi-Protocol | ☐ Pass ☐ Fail | |
| Camera Switching | ☐ Pass ☐ Fail | |

## Known Issues and Limitations

Document any issues discovered during testing:

```
Issue 1:
Description: _______________
Platform: _______________
Severity: _______________
Workaround: _______________

Issue 2:
Description: _______________
Platform: _______________
Severity: _______________
Workaround: _______________
```

## Performance Benchmarks

Record performance metrics from testing:

### iOS Performance

```
Device Model: _______________
iOS Version: _______________

1080p30 Streaming:
- CPU Usage: _______________
- Memory Usage: _______________
- Battery Drain: _______________
- Device Temperature: _______________
- Frame Drops: _______________

1080p60 Streaming:
- CPU Usage: _______________
- Memory Usage: _______________
- Battery Drain: _______________
- Device Temperature: _______________
- Frame Drops: _______________
```

### Android Performance

```
Device Model: _______________
Android Version: _______________

1080p30 Streaming:
- CPU Usage: _______________
- Memory Usage: _______________
- Battery Drain: _______________
- Device Temperature: _______________
- Frame Drops: _______________

1080p60 Streaming:
- CPU Usage: _______________
- Memory Usage: _______________
- Battery Drain: _______________
- Device Temperature: _______________
- Frame Drops: _______________
```

## Sign-Off

### iOS Testing

Tester Name: _______________
Date: _______________
Overall Result: ☐ Pass ☐ Fail ☐ Pass with Issues
Signature: _______________

### Android Testing

Tester Name: _______________
Date: _______________
Overall Result: ☐ Pass ☐ Fail ☐ Pass with Issues
Signature: _______________

## Appendix

### Troubleshooting Common Issues

**Issue: RTSP stream won't connect in OBS/VLC**
- Verify device and computer are on same network
- Check firewall settings on computer
- Verify RTSP port is not blocked
- Try different port number

**Issue: RTMP connection fails**
- Verify stream URL and key are correct
- Check internet connection stability
- Verify streaming is enabled on YouTube/Twitch account
- Check for any account restrictions

**Issue: Camera not appearing in list**
- Verify camera permissions are granted
- Restart the application
- Check device camera functionality in native camera app
- Update iOS/Android to latest version

**Issue: Poor stream quality**
- Reduce resolution or frame rate
- Lower bitrate
- Check network bandwidth
- Verify device is not overheating

**Issue: High battery drain**
- Reduce resolution to 720p
- Lower frame rate to 30 FPS
- Disable audio if not needed
- Reduce bitrate

### Reference Links

- OBS Studio: https://obsproject.com/
- VLC Media Player: https://www.videolan.org/
- YouTube Live Streaming: https://support.google.com/youtube/answer/2474026
- Twitch Streaming: https://help.twitch.tv/s/article/guide-to-broadcast-health-and-using-twitch-inspector
