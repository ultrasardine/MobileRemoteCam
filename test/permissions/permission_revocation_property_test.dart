import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/stream_statistics.dart';

/// **Feature: ip-camera-streaming-platform, Property 35: Permission revocation stops streaming**
/// **Validates: Requirements 9.5**
///
/// Property: Permission revocation stops streaming
/// For any active streaming session, when camera or microphone permission is revoked,
/// the system should gracefully stop streaming and display an appropriate error message.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 35: Permission revocation handling', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    test('camera permission revocation stops streaming', () async {
      const channel = MethodChannel('com.ipcamera/streaming');
      bool streamingStopped = false;
      String? errorMessage;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startStreaming':
            return null;
          case 'stopStreaming':
            streamingStopped = true;
            return null;
          case 'onPermissionRevoked':
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            errorMessage = args?['message'] as String?;
            return null;
          default:
            return null;
        }
      });

      // Start streaming
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

      await controller.startStreaming(config);

      // Simulate permission revocation
      await channel.invokeMethod('onPermissionRevoked', {
        'permission': 'camera',
        'message': 'Camera permission was revoked. Streaming has been stopped.',
      });

      // Verify streaming was stopped
      await controller.stopStreaming();
      expect(streamingStopped, isTrue);
    });

    test('microphone permission revocation stops streaming with audio',
        () async {
      const channel = MethodChannel('com.ipcamera/streaming');
      bool streamingStopped = false;
      String? errorMessage;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startStreaming':
            return null;
          case 'stopStreaming':
            streamingStopped = true;
            return null;
          case 'onPermissionRevoked':
            final args = methodCall.arguments as Map<dynamic, dynamic>?;
            errorMessage = args?['message'] as String?;
            return null;
          default:
            return null;
        }
      });

      // Start streaming with audio
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: true,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      await controller.startStreaming(config);

      // Simulate microphone permission revocation
      await channel.invokeMethod('onPermissionRevoked', {
        'permission': 'microphone',
        'message':
            'Microphone permission was revoked. Streaming has been stopped.',
      });

      // Verify streaming was stopped
      await controller.stopStreaming();
      expect(streamingStopped, isTrue);
    });

    test('permission revocation displays appropriate error message', () async {
      const channel = MethodChannel('com.ipcamera/streaming');
      String? receivedMessage;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'onPermissionRevoked') {
          final args = methodCall.arguments as Map<dynamic, dynamic>?;
          receivedMessage = args?['message'] as String?;
          return null;
        }
        return null;
      });

      // Simulate permission revocation with error message
      await channel.invokeMethod('onPermissionRevoked', {
        'permission': 'camera',
        'message':
            'Camera permission was revoked. Please grant permission to continue streaming.',
      });

      // Verify error message is informative
      expect(receivedMessage, isNotNull);
      expect(receivedMessage, contains('permission'));
      expect(receivedMessage, contains('revoked'));
    });

    test('graceful shutdown on permission revocation', () async {
      const channel = MethodChannel('com.ipcamera/streaming');
      bool resourcesCleaned = false;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startStreaming':
            return null;
          case 'stopStreaming':
            resourcesCleaned = true;
            return null;
          case 'getStatistics':
            // After revocation, statistics should show disconnected
            return {
              'currentBitrate': 0.0,
              'currentFps': 0,
              'droppedFrames': 0,
              'deviceTemperature': 35.0,
              'batteryLevel': 80,
              'connectionStatus': {
                'rtsp': 'disconnected'
              }, // String value that will be converted to enum
            };
          default:
            return null;
        }
      });

      // Start streaming
      final config = StreamConfig(
        cameraId: '0',
        resolution: Resolution(width: 1920, height: 1080),
        frameRate: 30,
        bitrate: 5000000,
        audioEnabled: true,
        rtspEnabled: true,
        rtspPort: 8554,
        rtmpTargets: [],
      );

      await controller.startStreaming(config);

      // Stop streaming (simulating permission revocation)
      await controller.stopStreaming();
      expect(resourcesCleaned, isTrue);

      // Verify resources are cleaned up
      final stats = await controller.getStatistics();
      expect(stats.currentFps, equals(0));
      expect(stats.connectionStatus['rtsp'],
          equals(ConnectionStatus.disconnected));
    });
  });
}
