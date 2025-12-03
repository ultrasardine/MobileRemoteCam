import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/stream_config.dart';
import 'package:ip_camera_streaming/models/resolution.dart';
import 'package:ip_camera_streaming/models/rtmp_target.dart';
import 'package:ip_camera_streaming/models/camera_info.dart';
import 'package:ip_camera_streaming/models/stream_statistics.dart';
import 'dart:math';

/// **Feature: ip-camera-streaming-platform, Property 1: Platform channel communication succeeds**
/// **Validates: Requirements 1.4**
///
/// Property: For any platform-specific feature request made through Flutter platform channels,
/// the native layer should successfully receive the request and return a response of the
/// expected type without throwing exceptions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Platform Channel Communication Property Tests', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    /// Generate random valid StreamConfig for property testing
    StreamConfig generateRandomConfig(int seed) {
      final r = Random(seed);
      final resolutions = [
        Resolution(width: 1280, height: 720),
        Resolution(width: 1920, height: 1080),
        Resolution(width: 3840, height: 2160),
      ];

      return StreamConfig(
        cameraId: r.nextInt(10).toString(),
        resolution: resolutions[r.nextInt(resolutions.length)],
        frameRate: r.nextBool() ? 30 : 60,
        bitrate: 1000000 + r.nextInt(9000000), // 1-10 Mbps
        audioEnabled: r.nextBool(),
        rtspEnabled: r.nextBool(),
        rtspPort: 8000 + r.nextInt(1000),
        rtmpTargets: List.generate(
          r.nextInt(3),
          (i) => RtmpTarget(
            url: 'rtmp://test$i.example.com/live',
            streamKey: 'key_${r.nextInt(10000)}',
            enabled: r.nextBool(),
          ),
        ),
      );
    }

    test(
        'Property 1: startStreaming accepts valid configurations without exceptions',
        () async {
      // Property-based test: Run 100 iterations with different random configurations
      const iterations = 100;
      int successCount = 0;
      List<String> errors = [];

      // Mock the platform channel to simulate native responses
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'startStreaming') {
            // Validate that we received a proper configuration map
            final args = methodCall.arguments as Map<dynamic, dynamic>;

            // Check required fields exist
            expect(args.containsKey('cameraId'), isTrue,
                reason: 'Configuration must contain cameraId');
            expect(args.containsKey('resolution'), isTrue,
                reason: 'Configuration must contain resolution');
            expect(args.containsKey('frameRate'), isTrue,
                reason: 'Configuration must contain frameRate');
            expect(args.containsKey('bitrate'), isTrue,
                reason: 'Configuration must contain bitrate');

            // Simulate successful native response
            return null;
          }
          return null;
        },
      );

      // Run property test with multiple random inputs
      for (int i = 0; i < iterations; i++) {
        try {
          final config = generateRandomConfig(i);
          await controller.startStreaming(config);
          successCount++;
        } catch (e) {
          errors.add('Iteration $i failed: $e');
        }
      }

      // Property should hold for all valid inputs
      expect(successCount, equals(iterations),
          reason:
              'All valid configurations should be accepted. Errors: ${errors.take(5).join(", ")}');
    });

    test('Property 1: stopStreaming communicates successfully', () async {
      // Property-based test: Run 100 iterations
      const iterations = 100;
      int successCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'stopStreaming') {
            return null; // Simulate successful stop
          }
          return null;
        },
      );

      for (int i = 0; i < iterations; i++) {
        try {
          await controller.stopStreaming();
          successCount++;
        } catch (e) {
          // Should not throw
        }
      }

      expect(successCount, equals(iterations),
          reason: 'stopStreaming should succeed for all calls');
    });

    test('Property 1: getStatistics returns valid statistics structure',
        () async {
      // Property-based test: Run 100 iterations with different mock responses
      const iterations = 100;
      int successCount = 0;
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            final r = Random(callCount++);
            // Return random but valid statistics
            return {
              'currentBitrate': r.nextDouble() * 10.0,
              'currentFps': 20 + r.nextInt(40),
              'droppedFrames': r.nextInt(100),
              'deviceTemperature': 20.0 + r.nextDouble() * 30.0,
              'batteryLevel': r.nextInt(101),
              'connectionStatus': {
                'rtsp': [
                  'disconnected',
                  'connecting',
                  'connected',
                  'error'
                ][r.nextInt(4)],
                'rtmp': [
                  'disconnected',
                  'connecting',
                  'connected',
                  'error'
                ][r.nextInt(4)],
              },
            };
          }
          return null;
        },
      );

      List<String> errors = [];
      for (int i = 0; i < iterations; i++) {
        try {
          final stats = await controller.getStatistics();

          // Validate structure
          expect(stats.currentBitrate, isA<double>());
          expect(stats.currentFps, isA<int>());
          expect(stats.droppedFrames, isA<int>());
          expect(stats.deviceTemperature, isA<double>());
          expect(stats.batteryLevel, isA<int>());
          expect(stats.connectionStatus, isA<Map<String, ConnectionStatus>>());

          successCount++;
        } catch (e) {
          errors.add('Iteration $i: $e');
        }
      }

      expect(successCount, equals(iterations),
          reason:
              'getStatistics should parse all valid responses. Errors: ${errors.take(3).join("; ")}');
    });

    test('Property 1: getCameras returns list of valid camera info', () async {
      // Property-based test: Run 100 iterations with different camera configurations
      const iterations = 100;
      int successCount = 0;
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getCameras') {
            final r = Random(callCount++);
            final cameraCount = 1 + r.nextInt(5); // 1-5 cameras

            return List.generate(
                cameraCount,
                (index) => {
                      'id': index.toString(),
                      'name': [
                        'Front',
                        'Back',
                        'Telephoto',
                        'Ultra-wide'
                      ][r.nextInt(4)],
                      'position': ['front', 'back', 'external'][r.nextInt(3)],
                      'capabilities': ['wide-angle', 'telephoto', 'ultra-wide']
                          .where((_) => r.nextBool())
                          .toList(),
                    });
          }
          return null;
        },
      );

      for (int i = 0; i < iterations; i++) {
        try {
          final cameras = await controller.getCameras();

          // Validate structure
          expect(cameras, isA<List<CameraInfo>>());
          expect(cameras.isNotEmpty, isTrue);

          for (final camera in cameras) {
            expect(camera.id, isNotEmpty);
            expect(camera.name, isNotEmpty);
            expect(camera.position, isA<CameraPosition>());
            expect(camera.capabilities, isA<List<String>>());
          }

          successCount++;
        } catch (e) {
          // Should not throw for valid data
        }
      }

      expect(successCount, equals(iterations),
          reason: 'getCameras should parse all valid camera lists');
    });

    test('Property 1: getResolutions returns valid resolution list', () async {
      // Property-based test: Run 100 iterations
      const iterations = 100;
      int successCount = 0;
      int callCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getResolutions') {
            expect(methodCall.arguments, isA<Map>());
            expect(
                (methodCall.arguments as Map).containsKey('cameraId'), isTrue);

            final r = Random(callCount++);
            final resCount = 1 + r.nextInt(10); // 1-10 resolutions

            return List.generate(
                resCount,
                (index) => {
                      'width': [1280, 1920, 3840][r.nextInt(3)],
                      'height': [720, 1080, 2160][r.nextInt(3)],
                    });
          }
          return null;
        },
      );

      for (int i = 0; i < iterations; i++) {
        try {
          final resolutions = await controller.getResolutions(i.toString());

          // Validate structure
          expect(resolutions, isA<List<Resolution>>());
          expect(resolutions.isNotEmpty, isTrue);

          for (final res in resolutions) {
            expect(res.width, greaterThan(0));
            expect(res.height, greaterThan(0));
          }

          successCount++;
        } catch (e) {
          // Should not throw for valid data
        }
      }

      expect(successCount, equals(iterations),
          reason: 'getResolutions should parse all valid resolution lists');
    });

    test('Property 1: Platform exceptions are properly propagated', () async {
      // Test that platform exceptions are caught and re-thrown properly
      const iterations = 50;
      int exceptionCount = 0;

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          // Simulate platform error
          throw PlatformException(
            code: 'TEST_ERROR',
            message: 'Simulated error',
          );
        },
      );

      for (int i = 0; i < iterations; i++) {
        try {
          final config = generateRandomConfig(i);
          await controller.startStreaming(config);
        } on PlatformException catch (e) {
          expect(e.code, isNotEmpty);
          expect(e.message, contains('Failed to start streaming'));
          exceptionCount++;
        }
      }

      expect(exceptionCount, equals(iterations),
          reason: 'All platform exceptions should be caught and re-thrown');
    });

    tearDown(() {
      // Clean up mock handlers
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });
  });

  group('StreamingController Unit Tests', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    group('Method Calls', () {
      test('startStreaming calls platform method with correct arguments',
          () async {
        bool methodCalled = false;
        Map<dynamic, dynamic>? receivedArgs;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'startStreaming') {
              methodCalled = true;
              receivedArgs = methodCall.arguments as Map<dynamic, dynamic>;
            }
            return null;
          },
        );

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

        expect(methodCalled, isTrue);
        expect(receivedArgs, isNotNull);
        expect(receivedArgs!['cameraId'], equals('0'));
        expect(receivedArgs!['frameRate'], equals(30));
        expect(receivedArgs!['bitrate'], equals(5000000));
        expect(receivedArgs!['audioEnabled'], equals(true));
      });

      test('stopStreaming calls platform method', () async {
        bool methodCalled = false;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'stopStreaming') {
              methodCalled = true;
            }
            return null;
          },
        );

        await controller.stopStreaming();

        expect(methodCalled, isTrue);
      });

      test('getStatistics calls platform method and returns statistics',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'getStatistics') {
              return {
                'currentBitrate': 5.2,
                'currentFps': 30,
                'droppedFrames': 5,
                'deviceTemperature': 42.5,
                'batteryLevel': 85,
                'connectionStatus': {
                  'rtsp': 'connected',
                  'rtmp': 'disconnected',
                },
              };
            }
            return null;
          },
        );

        final stats = await controller.getStatistics();

        expect(stats.currentBitrate, equals(5.2));
        expect(stats.currentFps, equals(30));
        expect(stats.droppedFrames, equals(5));
        expect(stats.deviceTemperature, equals(42.5));
        expect(stats.batteryLevel, equals(85));
        expect(
            stats.connectionStatus['rtsp'], equals(ConnectionStatus.connected));
        expect(stats.connectionStatus['rtmp'],
            equals(ConnectionStatus.disconnected));
      });

      test('getCameras calls platform method and returns camera list',
          () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'getCameras') {
              return [
                {
                  'id': '0',
                  'name': 'Back Camera',
                  'position': 'back',
                  'capabilities': ['wide-angle'],
                },
                {
                  'id': '1',
                  'name': 'Front Camera',
                  'position': 'front',
                  'capabilities': [],
                },
              ];
            }
            return null;
          },
        );

        final cameras = await controller.getCameras();

        expect(cameras.length, equals(2));
        expect(cameras[0].id, equals('0'));
        expect(cameras[0].name, equals('Back Camera'));
        expect(cameras[0].position, equals(CameraPosition.back));
        expect(cameras[1].id, equals('1'));
        expect(cameras[1].name, equals('Front Camera'));
        expect(cameras[1].position, equals(CameraPosition.front));
      });

      test('getResolutions calls platform method with camera ID', () async {
        String? receivedCameraId;

        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            if (methodCall.method == 'getResolutions') {
              final args = methodCall.arguments as Map<dynamic, dynamic>;
              receivedCameraId = args['cameraId'] as String;
              return [
                {'width': 1920, 'height': 1080},
                {'width': 1280, 'height': 720},
              ];
            }
            return null;
          },
        );

        final resolutions = await controller.getResolutions('test-camera-id');

        expect(receivedCameraId, equals('test-camera-id'));
        expect(resolutions.length, equals(2));
        expect(resolutions[0].width, equals(1920));
        expect(resolutions[0].height, equals(1080));
      });
    });

    group('Error Handling', () {
      test('startStreaming wraps platform exception with context', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'CAMERA_ERROR',
              message: 'Camera not available',
            );
          },
        );

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

        expect(
          () => controller.startStreaming(config),
          throwsA(isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Camera not available'),
          )),
        );
      });

      test('stopStreaming wraps platform exception with context', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'STOP_ERROR',
              message: 'Failed to stop',
            );
          },
        );

        expect(
          () => controller.stopStreaming(),
          throwsA(isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Failed to stop streaming'),
          )),
        );
      });

      test('getStatistics wraps platform exception with context', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'STATS_ERROR',
              message: 'Stats unavailable',
            );
          },
        );

        expect(
          () => controller.getStatistics(),
          throwsA(isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Failed to get statistics'),
          )),
        );
      });

      test('getCameras wraps platform exception with context', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'CAMERA_ENUM_ERROR',
              message: 'Cannot enumerate cameras',
            );
          },
        );

        expect(
          () => controller.getCameras(),
          throwsA(isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Failed to get cameras'),
          )),
        );
      });

      test('getResolutions wraps platform exception with context', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async {
            throw PlatformException(
              code: 'RESOLUTION_ERROR',
              message: 'Cannot get resolutions',
            );
          },
        );

        expect(
          () => controller.getResolutions('0'),
          throwsA(isA<PlatformException>().having(
            (e) => e.message,
            'message',
            contains('Failed to get resolutions'),
          )),
        );
      });
    });

    group('Configuration Validation', () {
      test('startStreaming accepts valid bitrate range', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async => null,
        );

        // Test minimum bitrate (1 Mbps)
        final config1 = StreamConfig(
          cameraId: '0',
          resolution: Resolution(width: 1920, height: 1080),
          frameRate: 30,
          bitrate: 1000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        await controller.startStreaming(config1);

        // Test maximum bitrate (10 Mbps)
        final config2 = StreamConfig(
          cameraId: '0',
          resolution: Resolution(width: 1920, height: 1080),
          frameRate: 30,
          bitrate: 10000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        await controller.startStreaming(config2);

        // Test mid-range bitrate (5 Mbps)
        final config3 = StreamConfig(
          cameraId: '0',
          resolution: Resolution(width: 1920, height: 1080),
          frameRate: 30,
          bitrate: 5000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        await controller.startStreaming(config3);
      });

      test('startStreaming accepts valid frame rates', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async => null,
        );

        // Test 30 FPS
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

        await controller.startStreaming(config1);

        // Test 60 FPS
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

        await controller.startStreaming(config2);
      });

      test('startStreaming accepts standard resolutions', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async => null,
        );

        // Test 720p
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

        await controller.startStreaming(config1);

        // Test 1080p
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

        await controller.startStreaming(config2);

        // Test 4K
        final config3 = StreamConfig(
          cameraId: '0',
          resolution: Resolution(width: 3840, height: 2160),
          frameRate: 30,
          bitrate: 5000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 8554,
          rtmpTargets: [],
        );

        await controller.startStreaming(config3);
      });

      test('startStreaming accepts valid RTSP port range', () async {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(
          StreamingController.platform,
          (MethodCall methodCall) async => null,
        );

        // Test default port
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

        await controller.startStreaming(config1);

        // Test custom port
        final config2 = StreamConfig(
          cameraId: '0',
          resolution: Resolution(width: 1920, height: 1080),
          frameRate: 30,
          bitrate: 5000000,
          audioEnabled: false,
          rtspEnabled: true,
          rtspPort: 9000,
          rtmpTargets: [],
        );

        await controller.startStreaming(config2);
      });
    });
  });
}
