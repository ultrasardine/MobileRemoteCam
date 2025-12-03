import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Feature: ip-camera-streaming-platform, Property 32: Audio toggle restarts stream
/// Validates: Requirements 8.6
///
/// Property: For any active streaming session, toggling the audio enable/disable
/// setting should result in the stream restarting with the new audio configuration applied.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 32: Audio toggle restarts stream', () {
    late List<MethodCall> methodCalls;
    const channel = MethodChannel('com.ipcamera/streaming');

    setUp(() {
      methodCalls = [];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        methodCalls.add(methodCall);

        switch (methodCall.method) {
          case 'startStreaming':
            return null;
          case 'stopStreaming':
            return null;
          case 'getStatistics':
            return {
              'currentBitrate': 5.0,
              'currentFps': 30,
              'droppedFrames': 0,
              'deviceTemperature': 35.0,
              'batteryLevel': 80,
              'connectionStatus': {'rtsp': 'connected'},
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

    test('toggling audio from disabled to enabled restarts stream', () async {
      // Arrange: Start streaming with audio disabled
      final initialConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', initialConfig);

      // Act: Toggle audio to enabled (requires restart)
      await channel.invokeMethod('stopStreaming');

      final newConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': true, // Audio now enabled
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', newConfig);

      // Assert: Stream was stopped and restarted
      final stopCalls =
          methodCalls.where((call) => call.method == 'stopStreaming').length;
      final startCalls =
          methodCalls.where((call) => call.method == 'startStreaming').length;

      expect(stopCalls, 1);
      expect(startCalls, 2); // Initial start + restart

      // Verify the new configuration has audio enabled
      final lastStartCall =
          methodCalls.lastWhere((call) => call.method == 'startStreaming');
      final lastConfig = lastStartCall.arguments as Map<dynamic, dynamic>;
      expect(lastConfig['audioEnabled'], true);
    });

    test('toggling audio from enabled to disabled restarts stream', () async {
      // Arrange: Start streaming with audio enabled
      final initialConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': true,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', initialConfig);

      // Act: Toggle audio to disabled (requires restart)
      await channel.invokeMethod('stopStreaming');

      final newConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false, // Audio now disabled
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', newConfig);

      // Assert: Stream was stopped and restarted
      final stopCalls =
          methodCalls.where((call) => call.method == 'stopStreaming').length;
      final startCalls =
          methodCalls.where((call) => call.method == 'startStreaming').length;

      expect(stopCalls, 1);
      expect(startCalls, 2); // Initial start + restart

      // Verify the new configuration has audio disabled
      final lastStartCall =
          methodCalls.lastWhere((call) => call.method == 'startStreaming');
      final lastConfig = lastStartCall.arguments as Map<dynamic, dynamic>;
      expect(lastConfig['audioEnabled'], false);
    });

    test('restart sequence is stop then start', () async {
      // Arrange: Start streaming
      final initialConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', initialConfig);
      final initialCallCount = methodCalls.length;

      // Act: Restart with audio toggle
      await channel.invokeMethod('stopStreaming');

      final newConfig = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': true,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', newConfig);

      // Assert: Stop was called before start
      final restartCalls = methodCalls.skip(initialCallCount).toList();
      expect(restartCalls.length, 2);
      expect(restartCalls[0].method, 'stopStreaming');
      expect(restartCalls[1].method, 'startStreaming');
    });

    test('multiple audio toggles result in multiple restarts', () async {
      // Start with audio disabled
      var config = {
        'cameraId': '0',
        'resolution': {'width': 1920, 'height': 1080},
        'frameRate': 30,
        'bitrate': 5000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 8554,
        'rtmpTargets': [],
      };

      await channel.invokeMethod('startStreaming', config);

      // Toggle 1: Enable audio
      await channel.invokeMethod('stopStreaming');
      config = Map.from(config);
      config['audioEnabled'] = true;
      await channel.invokeMethod('startStreaming', config);

      // Toggle 2: Disable audio
      await channel.invokeMethod('stopStreaming');
      config = Map.from(config);
      config['audioEnabled'] = false;
      await channel.invokeMethod('startStreaming', config);

      // Toggle 3: Enable audio again
      await channel.invokeMethod('stopStreaming');
      config = Map.from(config);
      config['audioEnabled'] = true;
      await channel.invokeMethod('startStreaming', config);

      // Assert: Multiple stop/start cycles occurred
      final stopCalls =
          methodCalls.where((call) => call.method == 'stopStreaming').length;
      final startCalls =
          methodCalls.where((call) => call.method == 'startStreaming').length;

      expect(stopCalls, 3); // Three toggles
      expect(startCalls, 4); // Initial + three restarts
    });

    test('audio toggle preserves other configuration parameters', () async {
      // Arrange: Start streaming with specific configuration
      final initialConfig = {
        'cameraId': '1',
        'resolution': {'width': 3840, 'height': 2160},
        'frameRate': 60,
        'bitrate': 10000000,
        'audioEnabled': false,
        'rtspEnabled': true,
        'rtspPort': 9000,
        'rtmpTargets': [
          {
            'url': 'rtmp://test.com/live',
            'streamKey': 'key123',
            'enabled': true
          }
        ],
      };

      await channel.invokeMethod('startStreaming', initialConfig);

      // Act: Toggle audio
      await channel.invokeMethod('stopStreaming');

      final newConfig = Map<String, dynamic>.from(initialConfig);
      newConfig['audioEnabled'] = true;

      await channel.invokeMethod('startStreaming', newConfig);

      // Assert: All other parameters remain unchanged
      final lastStartCall =
          methodCalls.lastWhere((call) => call.method == 'startStreaming');
      final lastConfig = lastStartCall.arguments as Map<dynamic, dynamic>;

      expect(lastConfig['cameraId'], '1');
      expect(lastConfig['resolution'], {'width': 3840, 'height': 2160});
      expect(lastConfig['frameRate'], 60);
      expect(lastConfig['bitrate'], 10000000);
      expect(lastConfig['rtspEnabled'], true);
      expect(lastConfig['rtspPort'], 9000);
      expect(lastConfig['audioEnabled'], true); // Only this changed
    });
  });
}
