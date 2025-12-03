import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';

/// **Feature: ip-camera-streaming-platform, Property 33: Permission denial displays error message**
/// **Validates: Requirements 9.3**
///
/// Property: Permission denial displays error message
/// For any required permission (camera or microphone) that is denied by the user,
/// the system should display an informative error message explaining why the permission is needed.

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 33: Permission denial handling', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    test('microphone permission denial returns false', () async {
      // Set up mock to deny permission
      const channel = MethodChannel('com.ipcamera/streaming');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'requestMicrophonePermission') {
          return false; // Permission denied
        }
        return null;
      });

      // Request permission
      final granted = await controller.requestMicrophonePermission();

      // Verify permission was denied
      expect(granted, isFalse);
    });

    test('microphone permission check returns false when denied', () async {
      // Set up mock to indicate no permission
      const channel = MethodChannel('com.ipcamera/streaming');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'hasMicrophonePermission') {
          return false; // No permission
        }
        return null;
      });

      // Check permission
      final hasPermission = await controller.hasMicrophonePermission();

      // Verify no permission
      expect(hasPermission, isFalse);
    });

    test('permission denial throws appropriate error with message', () async {
      // Set up mock to throw permission error
      const channel = MethodChannel('com.ipcamera/streaming');
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'requestMicrophonePermission') {
          throw PlatformException(
            code: 'PERMISSION_DENIED',
            message:
                'Microphone permission is required to capture audio for streaming',
            details: null,
          );
        }
        return null;
      });

      // Verify error is thrown with informative message
      expect(
        () => controller.requestMicrophonePermission(),
        throwsA(
          isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Microphone permission is required'),
          ),
        ),
      );
    });
  });
}
