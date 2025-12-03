# Streaming Modes

The IP Camera Streaming Platform supports three distinct streaming modes to accommodate different use cases.

## Available Modes

### 1. RTSP Only Mode 📡

**Description:** Stream to local network only (OBS, VLC)

**Use Case:** 
- Local production setups
- Low-latency streaming to nearby devices
- No internet connection required
- Privacy-focused streaming (stays on local network)

**Configuration:**
- RTSP server is enabled
- No RTMP targets are enabled
- Stream URL: `rtsp://[device-ip]:8554/live`

**Example:**
```dart
StreamConfig(
  cameraId: '0',
  resolution: Resolution(width: 1920, height: 1080),
  frameRate: 30,
  bitrate: 5000000,
  audioEnabled: true,
  rtspEnabled: true,
  rtspPort: 8554,
  rtmpTargets: [],
)
```

### 2. RTMP Only Mode ☁️

**Description:** Stream to cloud platforms only (YouTube, Twitch)

**Use Case:**
- Direct streaming to social media platforms
- Public broadcasting
- Cloud-based recording
- No local network streaming needed

**Configuration:**
- RTSP server is disabled
- One or more RTMP targets are enabled
- Requires internet connection

**Example:**
```dart
StreamConfig(
  cameraId: '0',
  resolution: Resolution(width: 1920, height: 1080),
  frameRate: 30,
  bitrate: 5000000,
  audioEnabled: true,
  rtspEnabled: false,
  rtspPort: 8554,
  rtmpTargets: [
    RtmpTarget(
      url: 'rtmp://a.rtmp.youtube.com/live2',
      streamKey: 'your-stream-key',
      enabled: true,
    ),
  ],
)
```

### 3. Simultaneous Mode 🌐

**Description:** Stream to both local network and cloud platforms

**Use Case:**
- Professional productions requiring both local monitoring and cloud streaming
- Backup streaming (local + cloud)
- Multi-destination broadcasting
- Maximum flexibility

**Configuration:**
- RTSP server is enabled
- One or more RTMP targets are enabled
- Can stream to multiple RTMP destinations simultaneously

**Example:**
```dart
StreamConfig(
  cameraId: '0',
  resolution: Resolution(width: 1920, height: 1080),
  frameRate: 30,
  bitrate: 5000000,
  audioEnabled: true,
  rtspEnabled: true,
  rtspPort: 8554,
  rtmpTargets: [
    RtmpTarget(
      url: 'rtmp://a.rtmp.youtube.com/live2',
      streamKey: 'youtube-key',
      enabled: true,
    ),
    RtmpTarget(
      url: 'rtmp://live.twitch.tv/app',
      streamKey: 'twitch-key',
      enabled: true,
    ),
  ],
)
```

## Mode Selection in UI

The configuration screen provides a visual mode selector that:

1. **Shows all three modes** with icons and descriptions
2. **Disables RTMP modes** when no RTMP targets are configured
3. **Automatically updates** when RTMP targets are added or removed
4. **Provides clear feedback** about why a mode cannot be selected

### Mode Selection Logic

The system automatically determines the current mode based on:
- `rtspEnabled` flag
- Presence of enabled RTMP targets

```dart
StreamingMode.fromEnabledStates(
  rtspEnabled: config.rtspEnabled,
  hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
)
```

## Implementation Details

### StreamingMode Enum

```dart
enum StreamingMode {
  rtspOnly,
  rtmpOnly,
  simultaneous,
}
```

### Extension Methods

- `rtspEnabled`: Returns true if RTSP should be active for this mode
- `rtmpEnabled`: Returns true if RTMP should be active for this mode
- `displayName`: Human-readable name for the mode
- `description`: Detailed description of the mode
- `icon`: Emoji icon representing the mode

### Mode Validation

Before selecting a mode, the UI checks:
- **RTSP Only**: Always available
- **RTMP Only**: Requires at least one configured RTMP target
- **Simultaneous**: Requires at least one configured RTMP target

## Requirements Validation

This implementation satisfies the following requirements:

- **Requirement 5.9**: WHEN the user enables RTSP mode THEN the System SHALL activate only the RTSP server
- **Requirement 5.10**: WHEN the user enables RTMP mode THEN the System SHALL activate only the RTMP client
- **Requirement 5.11**: WHEN the user enables both modes THEN the System SHALL activate both RTSP server and RTMP client simultaneously

## Testing

The streaming modes feature is tested through:

1. **Unit tests** (`test/models/streaming_mode_test.dart`):
   - Mode properties and behavior
   - Mode detection from enabled states
   - Display names and descriptions

2. **Integration tests** (`test/integration/streaming_mode_integration_test.dart`):
   - StreamConfig respects mode settings
   - Multiple RTMP targets in simultaneous mode
   - Mode determination from configuration

## Performance Considerations

### Simultaneous Mode

When streaming in simultaneous mode:
- **CPU Usage**: Encoding happens once; frames are duplicated to multiple outputs
- **Network Usage**: Bandwidth = RTSP bandwidth + (RTMP bandwidth × number of targets)
- **Battery Impact**: Higher than single-mode streaming due to multiple network connections

### Recommendations

- **Mobile Data**: Use RTSP-only mode on cellular to avoid data charges
- **Battery Life**: Use single-mode streaming for extended sessions
- **Quality**: Reduce bitrate or resolution when using simultaneous mode on older devices
