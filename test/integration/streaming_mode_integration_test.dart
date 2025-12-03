import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/rtmp_target.dart';
import 'package:ip_camera_streaming/models/streaming_mode.dart';

void main() {
  group('Streaming Mode Integration Tests', () {
    test('StreamingMode enum has correct enabled states', () {
      // Test RTSP-only mode
      expect(StreamingMode.rtspOnly.rtspEnabled, isTrue);
      expect(StreamingMode.rtspOnly.rtmpEnabled, isFalse);

      // Test RTMP-only mode
      expect(StreamingMode.rtmpOnly.rtspEnabled, isFalse);
      expect(StreamingMode.rtmpOnly.rtmpEnabled, isTrue);

      // Test simultaneous mode
      expect(StreamingMode.simultaneous.rtspEnabled, isTrue);
      expect(StreamingMode.simultaneous.rtmpEnabled, isTrue);
    });

    test('fromEnabledStates correctly determines mode', () {
      // RTSP only
      var mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: true,
        hasEnabledRtmpTargets: false,
      );
      expect(mode, equals(StreamingMode.rtspOnly));

      // RTMP only
      mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: false,
        hasEnabledRtmpTargets: true,
      );
      expect(mode, equals(StreamingMode.rtmpOnly));

      // Simultaneous
      mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: true,
        hasEnabledRtmpTargets: true,
      );
      expect(mode, equals(StreamingMode.simultaneous));

      // Default to RTSP only when nothing enabled
      mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: false,
        hasEnabledRtmpTargets: false,
      );
      expect(mode, equals(StreamingMode.rtspOnly));
    });

    test('StreamConfig respects RTSP-only mode settings', () {
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config.rtspEnabled, isTrue);
      expect(config.rtmpTargets.any((t) => t.enabled), isFalse);

      // Verify mode detection
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: config.rtspEnabled,
        hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
      );
      expect(mode, equals(StreamingMode.rtspOnly));
    });

    test('StreamConfig respects RTMP-only mode settings', () {
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: false,
        rtspPort: 8554,
        rtmpTargets: [
          RtmpTarget(
            url: 'rtmp://test.com/live',
            streamKey: 'key',
            enabled: true,
          ),
        ],
      );

      expect(config.rtspEnabled, isFalse);
      expect(config.rtmpTargets.any((t) => t.enabled), isTrue);

      // Verify mode detection
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: config.rtspEnabled,
        hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
      );
      expect(mode, equals(StreamingMode.rtmpOnly));
    });

    test('StreamConfig respects simultaneous mode settings', () {
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [
          RtmpTarget(
            url: 'rtmp://test.com/live',
            streamKey: 'key',
            enabled: true,
          ),
        ],
      );

      expect(config.rtspEnabled, isTrue);
      expect(config.rtmpTargets.any((t) => t.enabled), isTrue);

      // Verify mode detection
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: config.rtspEnabled,
        hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
      );
      expect(mode, equals(StreamingMode.simultaneous));
    });

    test('Multiple RTMP targets can be enabled in simultaneous mode', () {
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [
          RtmpTarget(
            url: 'rtmp://youtube.com/live',
            streamKey: 'youtube-key',
            enabled: true,
          ),
          RtmpTarget(
            url: 'rtmp://twitch.tv/live',
            streamKey: 'twitch-key',
            enabled: true,
          ),
        ],
      );

      expect(config.rtspEnabled, isTrue);
      expect(config.rtmpTargets.where((t) => t.enabled).length, equals(2));

      // Verify mode detection
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: config.rtspEnabled,
        hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
      );
      expect(mode, equals(StreamingMode.simultaneous));
    });

    test('Mode can be determined from config with disabled RTMP targets', () {
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [
          RtmpTarget(
            url: 'rtmp://test.com/live',
            streamKey: 'key',
            enabled: false, // Disabled
          ),
        ],
      );

      expect(config.rtspEnabled, isTrue);
      expect(config.rtmpTargets.any((t) => t.enabled), isFalse);

      // Should be RTSP-only since no RTMP targets are enabled
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: config.rtspEnabled,
        hasEnabledRtmpTargets: config.rtmpTargets.any((t) => t.enabled),
      );
      expect(mode, equals(StreamingMode.rtspOnly));
    });
  });
}
