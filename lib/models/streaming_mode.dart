/// Represents the streaming protocol mode
enum StreamingMode {
  /// RTSP-only mode - local network streaming only
  rtspOnly,

  /// RTMP-only mode - cloud streaming only
  rtmpOnly,

  /// Simultaneous mode - both RTSP and RTMP streaming
  simultaneous,
}

extension StreamingModeExtension on StreamingMode {
  /// Get display name for the mode
  String get displayName {
    switch (this) {
      case StreamingMode.rtspOnly:
        return 'RTSP Only';
      case StreamingMode.rtmpOnly:
        return 'RTMP Only';
      case StreamingMode.simultaneous:
        return 'RTSP + RTMP';
    }
  }

  /// Get description for the mode
  String get description {
    switch (this) {
      case StreamingMode.rtspOnly:
        return 'Stream to local network only (OBS, VLC)';
      case StreamingMode.rtmpOnly:
        return 'Stream to cloud platforms only (YouTube, Twitch)';
      case StreamingMode.simultaneous:
        return 'Stream to both local network and cloud platforms';
    }
  }

  /// Get icon for the mode
  String get icon {
    switch (this) {
      case StreamingMode.rtspOnly:
        return '📡';
      case StreamingMode.rtmpOnly:
        return '☁️';
      case StreamingMode.simultaneous:
        return '🌐';
    }
  }

  /// Check if RTSP should be enabled for this mode
  bool get rtspEnabled {
    return this == StreamingMode.rtspOnly || this == StreamingMode.simultaneous;
  }

  /// Check if RTMP should be enabled for this mode
  bool get rtmpEnabled {
    return this == StreamingMode.rtmpOnly || this == StreamingMode.simultaneous;
  }

  /// Create mode from RTSP and RTMP enabled states
  static StreamingMode fromEnabledStates({
    required bool rtspEnabled,
    required bool hasEnabledRtmpTargets,
  }) {
    if (rtspEnabled && hasEnabledRtmpTargets) {
      return StreamingMode.simultaneous;
    } else if (rtspEnabled) {
      return StreamingMode.rtspOnly;
    } else if (hasEnabledRtmpTargets) {
      return StreamingMode.rtmpOnly;
    } else {
      // Default to RTSP only if nothing is enabled
      return StreamingMode.rtspOnly;
    }
  }
}
