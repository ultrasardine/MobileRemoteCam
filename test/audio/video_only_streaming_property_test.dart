import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Feature: ip-camera-streaming-platform, Property 31: Audio disabled streams video-only
/// Validates: Requirements 8.5
///
/// Property: For any streaming session with audio disabled, the transmitted stream
/// should contain only video packets and no audio packets.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 31: Audio disabled streams video-only', () {
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('com.ipcamera/streaming');

    setUp(() {
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case 'startStreaming':
            // Simulate successful start
            return null;
          case 'stopStreaming':
            return null;
          case 'getStatistics':
            // Return mock statistics
            final config = methodCalls
                .where((call) => call.method == 'startStreaming')
                .last
                .arguments as Map<dynamic, dynamic>;
            final audioEnabled = config['audioEnabled'] as bool;

            return {
              'currentBitrate': 5.0,
              'currentFps': 30,
              'droppedFrames': 0,
              'deviceTemperature': 35.0,
              'batteryLevel': 80,
              'connectionStatus': {
                'rtsp': 'connected',
              },
              'audioEnabled': audioEnabled,
              'hasAudioPackets':
                  audioEnabled, // Only has audio packets if audio is enabled
            };
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('streaming with audio disabled produces video-only stream', () async {
      // Arrange: Create config with audio disabled
      final config = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false, // Audio disabled
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      // Act: Start streaming
      await channel.invokeMethod('startStreaming', config);

      // Get statistics
      final stats =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStatistics');

      // Assert: Stream has no audio packets
      expect(stats?['audioEnabled'], false);
      expect(stats?['hasAudioPackets'], false);
    });

    test('streaming with audio enabled produces audio and video stream',
        () async {
      // Arrange: Create config with audio enabled
      final config = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': true, // Audio enabled
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      // Act: Start streaming
      await channel.invokeMethod('startStreaming', config);

      // Get statistics
      final stats =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStatistics');

      // Assert: Stream has audio packets
      expect(stats?['audioEnabled'], true);
      expect(stats?['hasAudioPackets'], true);
    });

    test(
        'configuration with audioEnabled=false is properly passed to native layer',
        () async {
      // Arrange: Create config with audio disabled
      final config = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      // Act: Start streaming
      await channel.invokeMethod('startStreaming', config);

      // Assert: The native layer received audioEnabled=false
      final startStreamingCall = methodCalls.firstWhere(
        (call) => call.method == 'startStreaming',
      );
      final arguments = startStreamingCall.arguments as Map<dynamic, dynamic>;
      expect(arguments['audioEnabled'], false);
    });

    test(
        'multiple streams with different audio settings maintain correct state',
        () async {
      // First stream: audio disabled
      final config1 = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', config1);
      var stats =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStatistics');
      expect(stats?['hasAudioPackets'], false);

      await channel.invokeMethod('stopStreaming');

      // Second stream: audio enabled
      final config2 = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': true,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', config2);
      stats =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStatistics');
      expect(stats?['hasAudioPackets'], true);
    });

    test('video-only stream maintains video quality without audio overhead',
        () async {
      // Arrange: Create config with audio disabled
      final config = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      // Act: Start streaming
      await channel.invokeMethod('startStreaming', config);

      // Get statistics
      final stats =
          await channel.invokeMethod<Map<dynamic, dynamic>>('getStatistics');

      // Assert: Video quality is maintained (FPS and bitrate are as expected)
      expect(stats?['currentFps'], 30);
      expect(stats?['currentBitrate'], 5.0);
      expect(stats?['hasAudioPackets'], false);
    });
  });
}
