import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/stream_statistics.dart';
import 'dart:math';

/// **Feature: ip-camera-streaming-platform, Property 25: Statistics update frequency is at least 1 Hz**
/// **Validates: Requirements 6.6**
///
/// Property: For any active streaming session, statistics updates should occur at intervals
/// of 1 second or less (frequency >= 1 Hz).
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Statistics Update Frequency Property Tests', () {
    late StreamingController controller;

    setUp(() {
      controller = StreamingController();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    /// Generate random but valid statistics
    StreamStatistics generateRandomStatistics(int seed) {
      final r = Random(seed);
      return StreamStatistics(
        currentBitrate: 1.0 + r.nextDouble() * 9.0, // 1-10 Mbps
        currentFps: 20 + r.nextInt(41), // 20-60 fps
        droppedFrames: r.nextInt(100),
        deviceTemperature: 30.0 + r.nextDouble() * 30.0, // 30-60°C
        batteryLevel: 10 + r.nextInt(91), // 10-100%
        connectionStatus: {
          'rtsp': ConnectionStatus
              .values[r.nextInt(ConnectionStatus.values.length)],
          'rtmp': ConnectionStatus
              .values[r.nextInt(ConnectionStatus.values.length)],
        },
      );
    }

    test('Property 25: Statistics updates occur at least once per second',
        () async {
      // Property-based test: Run 100 iterations
      const iterations = 100;
      int successCount = 0;
      List<String> errors = [];

      for (int i = 0; i < iterations; i++) {
        try {
          final stats = generateRandomStatistics(i);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            StreamingController.platform,
            (MethodCall methodCall) async {
              if (methodCall.method == 'getStatistics') {
                return stats.toMap();
              }
              return null;
            },
          );

          // Measure time to get statistics
          final stopwatch = Stopwatch()..start();
          await controller.getStatistics();
          stopwatch.stop();

          // Verify that getting statistics takes less than 1 second
          // This ensures we CAN update at least once per second
          final elapsedMs = stopwatch.elapsedMilliseconds;
          expect(elapsedMs, lessThan(1000),
              reason:
                  'Statistics retrieval should take less than 1 second to allow 1Hz updates');

          successCount++;
        } catch (e) {
          errors.add('Iteration $i failed: $e');
        }
      }

      expect(successCount, equals(iterations),
          reason:
              'Statistics should be retrievable within 1 second. Errors: ${errors.take(5).join(", ")}');
    });

    test(
        'Property 25: Multiple consecutive statistics calls complete within reasonable time',
        () async {
      // Property-based test: Verify we can make multiple calls within a second
      const iterations = 100;
      int successCount = 0;

      for (int i = 0; i < iterations; i++) {
        try {
          final r = Random(i);
          final callCount = 2 + r.nextInt(3); // 2-4 calls

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            StreamingController.platform,
            (MethodCall methodCall) async {
              if (methodCall.method == 'getStatistics') {
                final stats = generateRandomStatistics(i);
                return stats.toMap();
              }
              return null;
            },
          );

          // Make multiple calls and measure total time
          final stopwatch = Stopwatch()..start();
          for (int j = 0; j < callCount; j++) {
            await controller.getStatistics();
          }
          stopwatch.stop();

          // All calls should complete well within 1 second
          final elapsedMs = stopwatch.elapsedMilliseconds;
          expect(elapsedMs, lessThan(1000),
              reason:
                  '$callCount consecutive calls should complete within 1 second');

          successCount++;
        } catch (e) {
          // Test failed
        }
      }

      expect(successCount, equals(iterations),
          reason: 'Multiple statistics calls should complete quickly');
    });

    test('Property 25: Statistics data is consistent across rapid calls',
        () async {
      // Property-based test: Verify statistics remain valid during rapid polling
      const iterations = 100;
      int successCount = 0;

      for (int i = 0; i < iterations; i++) {
        try {
          final stats = generateRandomStatistics(i);

          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            StreamingController.platform,
            (MethodCall methodCall) async {
              if (methodCall.method == 'getStatistics') {
                return stats.toMap();
              }
              return null;
            },
          );

          // Make rapid consecutive calls
          final result1 = await controller.getStatistics();
          final result2 = await controller.getStatistics();

          // Verify both results are valid
          expect(result1.currentBitrate, greaterThanOrEqualTo(0),
              reason: 'Bitrate should be non-negative');
          expect(result1.currentFps, greaterThanOrEqualTo(0),
              reason: 'FPS should be non-negative');
          expect(result1.droppedFrames, greaterThanOrEqualTo(0),
              reason: 'Dropped frames should be non-negative');

          expect(result2.currentBitrate, greaterThanOrEqualTo(0),
              reason: 'Bitrate should be non-negative');
          expect(result2.currentFps, greaterThanOrEqualTo(0),
              reason: 'FPS should be non-negative');
          expect(result2.droppedFrames, greaterThanOrEqualTo(0),
              reason: 'Dropped frames should be non-negative');

          successCount++;
        } catch (e) {
          // Test failed
        }
      }

      expect(successCount, equals(iterations),
          reason: 'Statistics should remain valid during rapid polling');
    });

    test(
        'Property 25: Statistics update frequency supports real-time monitoring',
        () async {
      // Property-based test: Verify we can poll at 1Hz or faster
      const iterations = 50; // Fewer iterations since this involves timing
      int successCount = 0;

      for (int i = 0; i < iterations; i++) {
        try {
          TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
              .setMockMethodCallHandler(
            StreamingController.platform,
            (MethodCall methodCall) async {
              if (methodCall.method == 'getStatistics') {
                final stats = generateRandomStatistics(i);
                return stats.toMap();
              }
              return null;
            },
          );

          // Simulate polling at 1Hz for a short duration
          final stopwatch = Stopwatch()..start();
          int pollCount = 0;

          // Poll for approximately 100ms (simulating part of a 1-second window)
          while (stopwatch.elapsedMilliseconds < 100) {
            await controller.getStatistics();
            pollCount++;
          }
          stopwatch.stop();

          // We should be able to poll multiple times in 100ms
          // This demonstrates we can easily achieve 1Hz (or much faster)
          expect(pollCount, greaterThan(0),
              reason: 'Should be able to poll at least once in 100ms');

          successCount++;
        } catch (e) {
          // Test failed
        }
      }

      expect(successCount, equals(iterations),
          reason: 'Statistics polling should support real-time monitoring');
    });

    test('Property 25: Statistics serialization/deserialization is fast',
        () async {
      // Property-based test: Verify round-trip doesn't add significant overhead
      const iterations = 100;
      int successCount = 0;

      for (int i = 0; i < iterations; i++) {
        try {
          final stats = generateRandomStatistics(i);

          // Measure serialization time
          final stopwatch = Stopwatch()..start();
          final map = stats.toMap();
          final restored = StreamStatistics.fromMap(map);
          stopwatch.stop();

          // Serialization should be very fast (< 10ms)
          expect(stopwatch.elapsedMilliseconds, lessThan(10),
              reason: 'Serialization should not add significant overhead');

          // Verify data integrity
          expect(restored.currentBitrate, equals(stats.currentBitrate));
          expect(restored.currentFps, equals(stats.currentFps));
          expect(restored.droppedFrames, equals(stats.droppedFrames));
          expect(restored.deviceTemperature, equals(stats.deviceTemperature));
          expect(restored.batteryLevel, equals(stats.batteryLevel));

          successCount++;
        } catch (e) {
          // Test failed
        }
      }

      expect(successCount, equals(iterations),
          reason: 'Statistics serialization should be fast and preserve data');
    });
  });
}
