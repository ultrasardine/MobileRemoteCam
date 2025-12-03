import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/rtmp_target.dart';

/// Integration test for configuration change detection
void main() {
  group('Configuration Change Detection', () {
    test('detects resolution change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1280, height: 720),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects frame rate change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 60,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects bitrate change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 8000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects camera change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '1',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects audio enabled change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: true,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects RTSP enabled change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: false,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects RTSP port change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8555,
        rtmpTargets: [],
      );

      expect(config1 == config2, isFalse);
    });

    test('detects RTMP targets change', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [
          RtmpTarget(
            url: 'rtmp://a.rtmp.youtube.com/live2',
            streamKey: 'test-key',
            enabled: true,
          ),
        ],
      );

      expect(config1 == config2, isFalse);
    });

    test('recognizes identical configurations', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      expect(config1 == config2, isTrue);
    });

    test('copyWith creates modified configuration', () {
      final config1 = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: false,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      final config2 = config1.copyWith(frameRate: 60);

      expect(config2.frameRate, equals(60));
      expect(config2.cameraId, equals(config1.cameraId));
      expect(config2.resolution, equals(config1.resolution));
      expect(config1 == config2, isFalse);
    });
  });
}
