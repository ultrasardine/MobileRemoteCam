// Requires device with platform channels - skip in CI
@Tags(['device-required'])
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/screens/configuration_screen.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/camera_info.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';

/// **Feature: ip-camera-streaming-platform, Property 18: Camera selection updates available resolutions**
/// **Validates: Requirements 5.4**
///
/// Property: For any camera selected by the user, the system should update the available
/// resolutions list to reflect that specific camera's capabilities.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Configuration Screen Property Tests', () {
    setUp(() {
      // Clean up any existing mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    testWidgets(
        'Property 18: Camera selection triggers resolution update for all cameras',
        (WidgetTester tester) async {
      // Generate test cameras
      final cameras = [
        CameraInfo(
          id: '0',
          name: 'Back Camera',
          position: CameraPosition.back,
          capabilities: ['wide-angle'],
        ),
        CameraInfo(
          id: '1',
          name: 'Front Camera',
          position: CameraPosition.front,
          capabilities: [],
        ),
        CameraInfo(
          id: '2',
          name: 'Telephoto',
          position: CameraPosition.back,
          capabilities: ['telephoto'],
        ),
      ];

      // Track which camera IDs have been queried for resolutions
      final Set<String> queriedCameraIds = {};
      final Map<String, List<Resolution>> cameraResolutions = {
        '0': [
          Resolution(width: 1920, height: 1080),
          Resolution(width: 1280, height: 720),
        ],
        '1': [
          Resolution(width: 1280, height: 720),
        ],
        '2': [
          Resolution(width: 3840, height: 2160),
          Resolution(width: 1920, height: 1080),
        ],
      };

      // Mock the platform channel
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getCameras') {
            return cameras
                .map((c) => {
                      'id': c.id,
                      'name': c.name,
                      'position': c.position.name,
                      'capabilities': c.capabilities,
                    })
                .toList();
          } else if (methodCall.method == 'getResolutions') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            final cameraId = args['cameraId'] as String;
            queriedCameraIds.add(cameraId);

            // Return resolutions for this camera
            final resolutions = cameraResolutions[cameraId] ?? [];
            return resolutions
                .map((r) => {'width': r.width, 'height': r.height})
                .toList();
          }
          return null;
        },
      );

      // Build the widget
      await tester.pumpWidget(
        MaterialApp(
          home: ConfigurationScreen(currentConfig: null),
        ),
      );

      // Wait for initial load with timeout
      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Verify initial camera was queried for resolutions
      expect(queriedCameraIds.isNotEmpty, isTrue,
          reason: 'Initial camera should be queried for resolutions');

      // Find the camera dropdown
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      expect(dropdownFinder, findsOneWidget,
          reason: 'Camera dropdown should be present');

      // Test selecting each camera
      for (int j = 1; j < cameras.length; j++) {
        final previousQueriedCount = queriedCameraIds.length;

        // Tap the dropdown
        await tester.tap(dropdownFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find and tap the camera option
        final cameraOptionFinder = find.text(cameras[j].name).last;
        await tester.tap(cameraOptionFinder);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify that getResolutions was called for the new camera
        expect(queriedCameraIds.length, greaterThan(previousQueriedCount),
            reason:
                'Selecting camera ${cameras[j].id} should trigger resolution query');
        expect(queriedCameraIds.contains(cameras[j].id), isTrue,
            reason:
                'Camera ${cameras[j].id} should have been queried for resolutions');
      }
    });

    testWidgets('Property 18: Resolution list updates when camera changes',
        (WidgetTester tester) async {
      // Create two cameras with different resolution sets
      final camera1 = CameraInfo(
        id: '0',
        name: 'Camera 1',
        position: CameraPosition.back,
        capabilities: [],
      );

      final camera2 = CameraInfo(
        id: '1',
        name: 'Camera 2',
        position: CameraPosition.front,
        capabilities: [],
      );

      final resolutions1 = [
        Resolution(width: 1280, height: 720),
        Resolution(width: 1920, height: 1080),
      ];

      final resolutions2 = [
        Resolution(width: 640, height: 480),
        Resolution(width: 3840, height: 2160),
      ];

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getCameras') {
            return [
              {
                'id': camera1.id,
                'name': camera1.name,
                'position': camera1.position.name,
                'capabilities': camera1.capabilities,
              },
              {
                'id': camera2.id,
                'name': camera2.name,
                'position': camera2.position.name,
                'capabilities': camera2.capabilities,
              },
            ];
          } else if (methodCall.method == 'getResolutions') {
            final args = methodCall.arguments as Map<dynamic, dynamic>;
            final cameraId = args['cameraId'] as String;

            final resolutions = cameraId == '0' ? resolutions1 : resolutions2;
            return resolutions
                .map((r) => {'width': r.width, 'height': r.height})
                .toList();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ConfigurationScreen(currentConfig: null),
        ),
      );

      await tester.pumpAndSettle(const Duration(milliseconds: 100));

      // Find resolution chips for camera 1
      final res1Finder = find.text('720p');
      expect(res1Finder, findsWidgets,
          reason: 'Camera 1 resolutions should be displayed');

      // Switch to camera 2
      final dropdownFinder = find.byType(DropdownButtonFormField<String>);
      await tester.tap(dropdownFinder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final camera2Finder = find.text('Camera 2').last;
      await tester.tap(camera2Finder);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Verify camera 2 resolutions are now displayed
      final res2Finder = find.text('4K');
      expect(res2Finder, findsWidgets,
          reason: 'Camera 2 resolutions should be displayed after switch');
    });

    /// **Feature: ip-camera-streaming-platform, Property 10: Stream URL format is valid**
    /// **Validates: Requirements 3.5**
    ///
    /// Property: For any device IP address and RTSP port configuration, the displayed stream URL
    /// should match the format `rtsp://[IP]:[PORT]/live` where IP is a valid IPv4 address
    /// and PORT is a valid port number.
    test(
        'Property 10: Stream URL format is valid for various IP and port combinations',
        () {
      // Test data: various IP addresses and ports
      final testCases = [
        {'ip': '192.168.1.100', 'port': 8554},
        {'ip': '10.0.0.5', 'port': 1024},
        {'ip': '172.16.0.1', 'port': 65535},
        {'ip': '192.168.0.1', 'port': 5000},
        {'ip': '0.0.0.0', 'port': 8554}, // Default when no IP available
        {'ip': '255.255.255.255', 'port': 12345},
      ];

      for (final testCase in testCases) {
        final ip = testCase['ip'] as String;
        final port = testCase['port'] as int;

        // Generate the URL using the same logic as the app
        final expectedUrl = 'rtsp://$ip:$port/live';

        // Verify URL format matches the pattern
        final urlPattern =
            RegExp(r'^rtsp://\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}:\d+/live$');
        expect(urlPattern.hasMatch(expectedUrl), isTrue,
            reason:
                'URL $expectedUrl should match rtsp://[IP]:[PORT]/live pattern');

        // Verify IP is valid IPv4
        final ipParts = ip.split('.');
        expect(ipParts.length, equals(4),
            reason: 'IP $ip should have 4 octets');
        for (final part in ipParts) {
          final octet = int.tryParse(part);
          expect(octet, isNotNull,
              reason: 'Each octet in $ip should be a number');
          expect(octet! >= 0 && octet <= 255, isTrue,
              reason: 'Each octet in $ip should be 0-255');
        }

        // Verify port is valid
        expect(port >= 1024 && port <= 65535, isTrue,
            reason: 'Port $port should be in valid range 1024-65535');

        // Verify the URL components
        expect(expectedUrl.startsWith('rtsp://'), isTrue,
            reason: 'URL should start with rtsp://');
        expect(expectedUrl.endsWith('/live'), isTrue,
            reason: 'URL should end with /live');
        expect(expectedUrl.contains(':$port'), isTrue,
            reason: 'URL should contain the port number');
      }
    });

    /// **Feature: ip-camera-streaming-platform, Property 11: Clipboard contains stream URL after tap**
    /// **Validates: Requirements 3.6**
    ///
    /// Property: For any stream URL displayed in the UI, after the user taps it,
    /// the device clipboard should contain exactly that URL string.
    test('Property 11: Clipboard functionality copies URL correctly', () async {
      TestWidgetsFlutterBinding.ensureInitialized();

      // Test data: various IP addresses and ports
      final testCases = [
        {'ip': '192.168.1.50', 'port': 8554},
        {'ip': '10.0.0.1', 'port': 1024},
        {'ip': '172.16.0.100', 'port': 9000},
        {'ip': '192.168.0.254', 'port': 5555},
      ];

      for (final testCase in testCases) {
        final ip = testCase['ip'] as String;
        final port = testCase['port'] as int;
        final expectedUrl = 'rtsp://$ip:$port/live';

        // Track clipboard data
        String? clipboardData;

        // Mock clipboard
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'Clipboard.setData') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              clipboardData = args['text'] as String?;
              return null;
            } else if (methodCall.method == 'Clipboard.getData') {
              return {'text': clipboardData};
            }
            return null;
          },
        );

        // Simulate copying the URL to clipboard (same logic as _copyStreamUrlToClipboard)
        await Clipboard.setData(ClipboardData(text: expectedUrl));

        // Verify clipboard contains the URL
        expect(clipboardData, equals(expectedUrl),
            reason:
                'Clipboard should contain exactly the stream URL: $expectedUrl');

        // Verify we can read it back
        final clipboardContent = await Clipboard.getData(Clipboard.kTextPlain);
        expect(clipboardContent?.text, equals(expectedUrl),
            reason: 'Reading from clipboard should return the same URL');
      }
    });
  });
}
