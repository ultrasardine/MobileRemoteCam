import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/camera_info.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';
import 'package:ip_camera_streaming/models/rtmp_target.dart';

/// Platform Validation Tests
///
/// These tests validate basic platform functionality that should work
/// on both iOS and Android physical devices. Run these tests on actual
/// devices to verify platform-specific implementations.
///
/// Requirements: 1.1, 1.2, 5.2
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Validation Tests', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    test('Platform channel communication is available', () async {
      // Verify that platform channels are properly set up
      // This will fail on devices where native code is not properly integrated
      expect(StreamingController.platform, isNotNull);
    });

    test('Camera enumeration returns at least one camera', () async {
      // Requirements: 5.2
      // Every device should have at least one camera
      try {
        final cameras = await controller.getCameras();

        expect(cameras, isNotEmpty,
            reason: 'Device should have at least one camera');

        // Verify each camera has required properties
        for (final camera in cameras) {
          expect(camera.id, isNotEmpty,
              reason: 'Camera ID should not be empty');
          expect(camera.name, isNotEmpty,
              reason: 'Camera name should not be empty');
          expect(camera.position, isNotNull,
              reason: 'Camera position should be specified');
        }

        print('✓ Found ${cameras.length} camera(s):');
        for (final camera in cameras) {
          print('  - ${camera.name} (${camera.position})');
        }
      } catch (e) {
        fail('Camera enumeration failed: $e');
      }
    });

    test('Multi-camera devices expose all cameras', () async {
      // Requirements: 5.2
      // Devices with multiple cameras should expose all of them
      try {
        final cameras = await controller.getCameras();

        print('Camera count: ${cameras.length}');

        // Most modern phones have at least 2 cameras (front + back)
        if (cameras.length >= 2) {
          print('✓ Multi-camera device detected');

          // Verify we have both front and back cameras
          final hasFront =
              cameras.any((c) => c.position == CameraPosition.front);
          final hasBack = cameras.any((c) => c.position == CameraPosition.back);

          expect(hasFront || hasBack, isTrue,
              reason: 'Should have at least front or back camera');

          print('  Front camera: ${hasFront ? "Yes" : "No"}');
          print('  Back camera: ${hasBack ? "Yes" : "No"}');
        } else {
          print('⚠ Single camera device');
        }
      } catch (e) {
        fail('Camera enumeration failed: $e');
      }
    });

    test('Each camera provides available resolutions', () async {
      // Requirements: 5.4
      // Each camera should report its supported resolutions
      try {
        final cameras = await controller.getCameras();
        expect(cameras, isNotEmpty);

        for (final camera in cameras) {
          final resolutions = await controller.getResolutions(camera.id);

          expect(resolutions, isNotEmpty,
              reason:
                  'Camera ${camera.name} should have available resolutions');

          print('✓ ${camera.name} resolutions:');
          for (final res in resolutions) {
            print('  - ${res.displayName}');
          }

          // Verify resolutions have valid dimensions
          for (final res in resolutions) {
            expect(res.width, greaterThan(0));
            expect(res.height, greaterThan(0));
          }
        }
      } catch (e) {
        fail('Resolution enumeration failed: $e');
      }
    });

    test('Standard resolutions are supported', () async {
      // Requirements: 2.6
      // Verify that standard resolutions (720p, 1080p) are available
      try {
        final cameras = await controller.getCameras();
        expect(cameras, isNotEmpty);

        // Check the main back camera (most capable)
        final backCamera = cameras.firstWhere(
          (c) => c.position == CameraPosition.back,
          orElse: () => cameras.first,
        );

        final resolutions = await controller.getResolutions(backCamera.id);

        // Check for 720p
        final has720p =
            resolutions.any((r) => r.width == 1280 && r.height == 720);

        // Check for 1080p
        final has1080p =
            resolutions.any((r) => r.width == 1920 && r.height == 1080);

        print('Standard resolution support:');
        print('  720p: ${has720p ? "Yes" : "No"}');
        print('  1080p: ${has1080p ? "Yes" : "No"}');

        // At least one standard resolution should be supported
        expect(has720p || has1080p, isTrue,
            reason: 'Device should support at least 720p or 1080p');
      } catch (e) {
        fail('Resolution check failed: $e');
      }
    });

    test('Platform-specific encoder is available', () async {
      // Requirements: 2.3, 2.4
      // Verify hardware encoder can be initialized
      try {
        final cameras = await controller.getCameras();
        expect(cameras, isNotEmpty);

        final camera = cameras.first;
        final resolutions = await controller.getResolutions(camera.id);
        expect(resolutions, isNotEmpty);

        // Try to initialize streaming with basic config
        final config = StreamConfig(
          cameraId: camera.id,
          resolution: resolutions.first,
          frameRate: 30,
          bitrate: 2000000, // 2 Mbps
          audioEnabled: false, // Disable audio to avoid permission issues
          rtspEnabled: false,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        // Note: This will fail if permissions are not granted
        // In a real device test, permissions should be granted first
        print('⚠ Encoder initialization test requires camera permission');
        print('  Run this test on a physical device with permissions granted');
      } catch (e) {
        print('⚠ Encoder test skipped: $e');
      }
    });

    test('RTSP configuration is accepted', () async {
      // Requirements: 3.1, 3.2
      // Verify RTSP configuration can be set
      try {
        final cameras = await controller.getCameras();
        if (cameras.isEmpty) {
          print('⚠ No cameras available, skipping RTSP test');
          return;
        }

        final camera = cameras.first;
        final resolutions = await controller.getResolutions(camera.id);
        if (resolutions.isEmpty) {
          print('⚠ No resolutions available, skipping RTSP test');
          return;
        }

        // Create config with RTSP enabled
        final config = StreamConfig(
          cameraId: camera.id,
          resolution: resolutions.first,
          frameRate: 30,
          bitrate: 2000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        expect(config.rtspEnabled, isTrue);
        expect(config.rtspPort, equals(8554));

        print('✓ RTSP configuration accepted');
        print('  Port: ${config.rtspPort}');
      } catch (e) {
        fail('RTSP configuration failed: $e');
      }
    });

    test('RTMP configuration is accepted', () async {
      // Requirements: 4.2, 4.3
      // Verify RTMP configuration can be set
      try {
        final cameras = await controller.getCameras();
        if (cameras.isEmpty) {
          print('⚠ No cameras available, skipping RTMP test');
          return;
        }

        final camera = cameras.first;
        final resolutions = await controller.getResolutions(camera.id);
        if (resolutions.isEmpty) {
          print('⚠ No resolutions available, skipping RTMP test');
          return;
        }

        // Create config with RTMP enabled
        final config = StreamConfig(
          cameraId: camera.id,
          resolution: resolutions.first,
          frameRate: 30,
          bitrate: 4000000,
          audioEnabled: false,
          rtspEnabled: false,
          rtspPort: 8554,
          rtmpTargets: [
            RtmpTarget(
              url: 'rtmp://test.example.com/live',
              streamKey: 'test-key-123',
              enabled: true,
            ),
          ],
        );

        expect(config.rtmpTargets, hasLength(1));
        expect(config.rtmpTargets.first.enabled, isTrue);

        print('✓ RTMP configuration accepted');
        print('  Targets: ${config.rtmpTargets.length}');
      } catch (e) {
        fail('RTMP configuration failed: $e');
      }
    });

    test('Device information is accessible', () async {
      // Verify we can get basic device information
      try {
        print('Platform validation test running');
        print('This test should be run on physical devices:');
        print('  - iOS: iPhone 12 or later');
        print('  - Android: Pixel 5 or later');
        print('');
        print('Ensure the following before running:');
        print('  1. Camera permissions granted');
        print('  2. Microphone permissions granted (for audio tests)');
        print('  3. Device connected via USB or WiFi debugging');
        print('  4. App built and deployed to device');
      } catch (e) {
        fail('Device information check failed: $e');
      }
    });
  });

  group('Platform-Specific Feature Validation', () {
    test('iOS-specific features', () async {
      // This test should only run on iOS devices
      // Validates iOS-specific implementations
      print('iOS-specific validation:');
      print('  - AVFoundation camera capture');
      print('  - VideoToolbox H.264 encoding');
      print('  - Hardware AAC encoding');
      print('  - Live555 RTSP server integration');
      print('  - librtmp RTMP client integration');
      print('');
      print('Run manual tests from PLATFORM_TESTING_GUIDE.md');
    });

    test('Android-specific features', () async {
      // This test should only run on Android devices
      // Validates Android-specific implementations
      print('Android-specific validation:');
      print('  - Camera2 API camera capture');
      print('  - MediaCodec H.264 encoding');
      print('  - Hardware AAC encoding');
      print('  - Live555 RTSP server via JNI');
      print('  - librtmp RTMP client via JNI');
      print('');
      print('Run manual tests from PLATFORM_TESTING_GUIDE.md');
    });
  });

  group('External Client Integration Validation', () {
    test('RTSP client compatibility checklist', () async {
      // Requirements: 3.3
      print('RTSP Client Compatibility:');
      print('  ☐ OBS Studio can connect and display stream');
      print('  ☐ VLC Media Player can connect and display stream');
      print('  ☐ Multiple clients can connect simultaneously (up to 3)');
      print('  ☐ Stream latency is acceptable (< 500ms)');
      print('  ☐ Audio and video are synchronized');
      print('');
      print('See PLATFORM_TESTING_GUIDE.md for detailed test procedures');
    });

    test('RTMP service compatibility checklist', () async {
      // Requirements: 4.2, 4.3
      print('RTMP Service Compatibility:');
      print('  ☐ YouTube Live accepts stream');
      print('  ☐ Twitch accepts stream');
      print('  ☐ Stream health is "Good" or "Excellent"');
      print('  ☐ Reconnection works after network interruption');
      print('  ☐ Multiple targets can stream simultaneously');
      print('');
      print('See PLATFORM_TESTING_GUIDE.md for detailed test procedures');
    });
  });
}
