import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/models/streaming_mode.dart';

void main() {
  group('StreamingMode', () {
    test('RTSP-only mode enables only RTSP', () {
      const mode = StreamingMode.rtspOnly;

      expect(mode.rtspEnabled, isTrue);
      expect(mode.rtmpEnabled, isFalse);
      expect(mode.displayName, equals('RTSP Only'));
    });

    test('RTMP-only mode enables only RTMP', () {
      const mode = StreamingMode.rtmpOnly;

      expect(mode.rtspEnabled, isFalse);
      expect(mode.rtmpEnabled, isTrue);
      expect(mode.displayName, equals('RTMP Only'));
    });

    test('Simultaneous mode enables both RTSP and RTMP', () {
      const mode = StreamingMode.simultaneous;

      expect(mode.rtspEnabled, isTrue);
      expect(mode.rtmpEnabled, isTrue);
      expect(mode.displayName, equals('RTSP + RTMP'));
    });

    test('fromEnabledStates creates correct mode for RTSP only', () {
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: true,
        hasEnabledRtmpTargets: false,
      );

      expect(mode, equals(StreamingMode.rtspOnly));
    });

    test('fromEnabledStates creates correct mode for RTMP only', () {
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: false,
        hasEnabledRtmpTargets: true,
      );

      expect(mode, equals(StreamingMode.rtmpOnly));
    });

    test('fromEnabledStates creates correct mode for simultaneous', () {
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: true,
        hasEnabledRtmpTargets: true,
      );

      expect(mode, equals(StreamingMode.simultaneous));
    });

    test('fromEnabledStates defaults to RTSP only when nothing enabled', () {
      final mode = StreamingModeExtension.fromEnabledStates(
        rtspEnabled: false,
        hasEnabledRtmpTargets: false,
      );

      expect(mode, equals(StreamingMode.rtspOnly));
    });

    test('All modes have display names', () {
      for (final mode in StreamingMode.values) {
        expect(mode.displayName, isNotEmpty);
      }
    });

    test('All modes have descriptions', () {
      for (final mode in StreamingMode.values) {
        expect(mode.description, isNotEmpty);
      }
    });

    test('All modes have icons', () {
      for (final mode in StreamingMode.values) {
        expect(mode.icon, isNotEmpty);
      }
    });
  });
}
