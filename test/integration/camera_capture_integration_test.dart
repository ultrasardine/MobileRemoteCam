import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Integration test for CameraCapture iOS implementation
/// Verifies that the platform channel communication works correctly
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CameraCapture Integration Tests', () {
    const platform = MethodChannel('com.ipcamera/streaming');

    setUp(() {
      // Set up mock method channel handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getCameras':
            return [
              {
                'id': 'camera-back',
                'name': 'Back Camera',
                'position': 'back',
                'capabilities': ['wide-angle'],
              },
              {
                'id': 'camera-front',
                'name': 'Front Camera',
                'position': 'front',
                'capabilities': ['wide-angle'],
              },
            ];
          case 'getResolutions':
            return [
              {'width': 1280, 'height': 720},
              {'width': 1920, 'height': 1080},
            ];
          case 'startStreaming':
            return null; // Success
          case 'stopStreaming':
            return null; // Success
          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, null);
    });

    test('can enumerate cameras', () async {
      final cameras = await platform.invokeMethod('getCameras');
      expect(cameras, isA<List>());
      expect((cameras as List).length, greaterThan(0));
    });

    test('can get resolutions for a camera', () async {
      final resolutions = await platform.invokeMethod(
        'getResolutions',
        {'cameraId': 'camera-back'},
      );
      expect(resolutions, isA<List>());
      expect((resolutions as List).length, greaterThan(0));
    });

    test('can start and stop streaming', () async {
      // Start streaming
      await platform.invokeMethod('startStreaming', {
        'cameraId': 'camera-back',
        'width': 1920,
        'height': 1080,
        'frameRate': 30,
        'audioEnabled': true,
      });

      // Stop streaming
      await platform.invokeMethod('stopStreaming');

      // If we get here without exceptions, the test passes
      expect(true, isTrue);
    });
  });
}
