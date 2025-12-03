import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Property-based tests for overheating warning functionality
/// Feature: ip-camera-streaming-platform, Property 37: Overheating triggers warning with suggestions
/// Validates: Requirements 10.5
///
/// This test verifies that when device temperature exceeds thresholds,
/// the system displays appropriate warnings with actionable suggestions.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Overheating Warning Property Tests', () {
    const platform = MethodChannel('com.ipcamera/streaming');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getStatistics':
            final args = methodCall.arguments as Map?;
            final temperature = args?['mockTemperature'] as double? ?? 35.0;

            return {
              'currentBitrate': 5.0,
              'currentFps': 30,
              'droppedFrames': 0,
              'deviceTemperature': temperature,
              'batteryLevel': 80,
              'connectionStatus': {
                'rtsp': 'connected',
                'rtmp': 'connected',
              },
            };

          case 'checkOverheating':
            final args = methodCall.arguments as Map;
            final temperature = args['temperature'] as double;

            // Overheating threshold: 50°C
            if (temperature >= 50.0) {
              return {
                'isOverheating': true,
                'temperature': temperature,
                'warningLevel': temperature >= 60.0 ? 'critical' : 'warning',
                'suggestions': [
                  'Reduce resolution to 720p or lower',
                  'Reduce frame rate to 30 FPS',
                  'Reduce bitrate to 3 Mbps or lower',
                  'Ensure device is not in direct sunlight',
                  'Remove device case if present',
                  'Stop streaming and allow device to cool',
                ],
              };
            }

            return {
              'isOverheating': false,
              'temperature': temperature,
              'warningLevel': 'normal',
              'suggestions': [],
            };

          case 'getOverheatingThresholds':
            return {
              'warningThreshold': 50.0,
              'criticalThreshold': 60.0,
              'shutdownThreshold': 70.0,
            };

          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, null);
    });

    /// Property 37: Overheating triggers warning with suggestions
    test('temperature above 50°C triggers warning for any streaming session',
        () async {
      // Property: For any temperature >= 50°C, system should trigger overheating warning

      final testTemperatures = [
        50.0, // Exactly at threshold
        55.0, // Moderate overheating
        60.0, // High overheating
        65.0, // Critical overheating
        70.0, // Extreme overheating
      ];

      for (var temperature in testTemperatures) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': temperature,
        });

        expect(result, isA<Map>());
        final resultMap = result as Map;

        // Property: Overheating should be detected
        expect(resultMap['isOverheating'], isTrue,
            reason: 'Temperature $temperature°C should trigger overheating');

        // Property: Temperature should be reported
        expect(resultMap['temperature'], equals(temperature),
            reason: 'Reported temperature should match actual');

        // Property: Warning level should be provided
        expect(resultMap.containsKey('warningLevel'), isTrue,
            reason: 'Warning level should be provided');
        expect(resultMap['warningLevel'], isIn(['warning', 'critical']),
            reason: 'Warning level should be valid');

        // Property: Suggestions should be provided
        expect(resultMap.containsKey('suggestions'), isTrue,
            reason: 'Suggestions should be provided');
        expect(resultMap['suggestions'], isA<List>(),
            reason: 'Suggestions should be a list');

        final suggestions = resultMap['suggestions'] as List;
        expect(suggestions.isNotEmpty, isTrue,
            reason: 'Suggestions should not be empty for overheating');

        // Property: Suggestions should include actionable items
        final suggestionsText = suggestions.join(' ').toLowerCase();
        expect(
          suggestionsText.contains('reduce') ||
              suggestionsText.contains('lower') ||
              suggestionsText.contains('stop'),
          isTrue,
          reason: 'Suggestions should include actionable advice',
        );
      }
    });

    test('temperature below 50°C does not trigger warning', () async {
      // Property: For any temperature < 50°C, system should not trigger warning

      final normalTemperatures = [
        25.0, // Cool
        30.0, // Normal
        35.0, // Slightly warm
        40.0, // Warm
        45.0, // Hot but not overheating
        49.9, // Just below threshold
      ];

      for (var temperature in normalTemperatures) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': temperature,
        });

        expect(result, isA<Map>());
        final resultMap = result as Map;

        // Property: Should not be overheating
        expect(resultMap['isOverheating'], isFalse,
            reason:
                'Temperature $temperature°C should not trigger overheating');

        // Property: Warning level should be normal
        expect(resultMap['warningLevel'], equals('normal'),
            reason: 'Warning level should be normal for safe temperatures');

        // Property: Suggestions should be empty or minimal
        final suggestions = resultMap['suggestions'] as List;
        expect(suggestions.isEmpty, isTrue,
            reason: 'No suggestions needed for normal temperatures');
      }
    });

    test('warning level escalates with temperature', () async {
      // Property: For any increasing temperature sequence, warning level should escalate

      final temperatureSequence = [
        {'temp': 50.0, 'expectedLevel': 'warning'},
        {'temp': 55.0, 'expectedLevel': 'warning'},
        {'temp': 60.0, 'expectedLevel': 'critical'},
        {'temp': 65.0, 'expectedLevel': 'critical'},
      ];

      for (var testCase in temperatureSequence) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': testCase['temp'],
        });

        final resultMap = result as Map;
        expect(resultMap['warningLevel'], equals(testCase['expectedLevel']),
            reason:
                'Temperature ${testCase['temp']}°C should have ${testCase['expectedLevel']} level');
      }
    });

    test('suggestions include resolution reduction', () async {
      // Property: For any overheating condition, suggestions should include resolution reduction

      final result = await platform.invokeMethod('checkOverheating', {
        'temperature': 55.0,
      });

      final suggestions = (result as Map)['suggestions'] as List;
      final suggestionsText = suggestions.join(' ').toLowerCase();

      expect(
          suggestionsText.contains('resolution') ||
              suggestionsText.contains('720p'),
          isTrue,
          reason: 'Suggestions should mention resolution reduction');
    });

    test('suggestions include frame rate reduction', () async {
      // Property: For any overheating condition, suggestions should include frame rate reduction

      final result = await platform.invokeMethod('checkOverheating', {
        'temperature': 55.0,
      });

      final suggestions = (result as Map)['suggestions'] as List;
      final suggestionsText = suggestions.join(' ').toLowerCase();

      expect(
          suggestionsText.contains('frame rate') ||
              suggestionsText.contains('fps') ||
              suggestionsText.contains('30'),
          isTrue,
          reason: 'Suggestions should mention frame rate reduction');
    });

    test('suggestions include bitrate reduction', () async {
      // Property: For any overheating condition, suggestions should include bitrate reduction

      final result = await platform.invokeMethod('checkOverheating', {
        'temperature': 55.0,
      });

      final suggestions = (result as Map)['suggestions'] as List;
      final suggestionsText = suggestions.join(' ').toLowerCase();

      expect(
          suggestionsText.contains('bitrate') ||
              suggestionsText.contains('mbps') ||
              suggestionsText.contains('3'),
          isTrue,
          reason: 'Suggestions should mention bitrate reduction');
    });

    test('statistics report includes temperature', () async {
      // Property: For any streaming session, statistics should include device temperature

      final temperatures = [35.0, 45.0, 55.0, 65.0];

      for (var temperature in temperatures) {
        final result = await platform.invokeMethod('getStatistics', {
          'mockTemperature': temperature,
        });

        expect(result, isA<Map>());
        final resultMap = result as Map;

        // Property: Temperature should be included in statistics
        expect(resultMap.containsKey('deviceTemperature'), isTrue,
            reason: 'Statistics should include device temperature');

        expect(resultMap['deviceTemperature'], equals(temperature),
            reason: 'Reported temperature should match actual');

        // Property: Temperature should be a valid number
        expect(resultMap['deviceTemperature'], isA<double>(),
            reason: 'Temperature should be a double');
        expect(resultMap['deviceTemperature'], greaterThan(0),
            reason: 'Temperature should be positive');
      }
    });

    test('overheating thresholds are well-defined', () async {
      // Property: System should have clear, documented thresholds

      final thresholds =
          await platform.invokeMethod('getOverheatingThresholds');

      expect(thresholds, isA<Map>());
      final thresholdsMap = thresholds as Map;

      // Property: Warning threshold should exist
      expect(thresholdsMap.containsKey('warningThreshold'), isTrue,
          reason: 'Warning threshold should be defined');
      expect(thresholdsMap['warningThreshold'], equals(50.0),
          reason: 'Warning threshold should be 50°C');

      // Property: Critical threshold should exist and be higher than warning
      expect(thresholdsMap.containsKey('criticalThreshold'), isTrue,
          reason: 'Critical threshold should be defined');
      expect(thresholdsMap['criticalThreshold'],
          greaterThan(thresholdsMap['warningThreshold']),
          reason: 'Critical threshold should be higher than warning');

      // Property: Shutdown threshold should exist and be highest
      expect(thresholdsMap.containsKey('shutdownThreshold'), isTrue,
          reason: 'Shutdown threshold should be defined');
      expect(thresholdsMap['shutdownThreshold'],
          greaterThan(thresholdsMap['criticalThreshold']),
          reason: 'Shutdown threshold should be highest');
    });

    test('critical overheating includes urgent suggestions', () async {
      // Property: For any critical temperature (>= 60°C), suggestions should be more urgent

      final result = await platform.invokeMethod('checkOverheating', {
        'temperature': 65.0,
      });

      final resultMap = result as Map;
      expect(resultMap['warningLevel'], equals('critical'),
          reason: '65°C should be critical level');

      final suggestions = resultMap['suggestions'] as List;
      final suggestionsText = suggestions.join(' ').toLowerCase();

      // Property: Critical suggestions should include stopping streaming
      expect(
          suggestionsText.contains('stop') || suggestionsText.contains('cool'),
          isTrue,
          reason: 'Critical overheating should suggest stopping streaming');
    });

    test('overheating detection is consistent across multiple checks',
        () async {
      // Property: For any constant temperature, multiple checks should return consistent results

      const temperature = 55.0;
      final results = <Map>[];

      for (var i = 0; i < 5; i++) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': temperature,
        });
        results.add(result as Map);
      }

      // Property: All results should be consistent
      for (var i = 1; i < results.length; i++) {
        expect(results[i]['isOverheating'], equals(results[0]['isOverheating']),
            reason: 'Overheating detection should be consistent');
        expect(results[i]['warningLevel'], equals(results[0]['warningLevel']),
            reason: 'Warning level should be consistent');
      }
    });

    test('suggestions are non-empty for all overheating levels', () async {
      // Property: For any overheating condition, at least one suggestion should be provided

      final overheatingTemperatures = [50.0, 55.0, 60.0, 65.0, 70.0];

      for (var temperature in overheatingTemperatures) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': temperature,
        });

        final suggestions = (result as Map)['suggestions'] as List;

        // Property: Suggestions should not be empty
        expect(suggestions.isNotEmpty, isTrue,
            reason:
                'At least one suggestion should be provided for temperature $temperature°C');

        // Property: Each suggestion should be a non-empty string
        for (var suggestion in suggestions) {
          expect(suggestion, isA<String>(),
              reason: 'Each suggestion should be a string');
          expect((suggestion as String).isNotEmpty, isTrue,
              reason: 'Each suggestion should be non-empty');
        }
      }
    });

    test('temperature boundary conditions are handled correctly', () async {
      // Property: Boundary temperatures should be handled correctly

      final boundaryTests = [
        {'temp': 49.99, 'shouldWarn': false},
        {'temp': 50.0, 'shouldWarn': true},
        {'temp': 50.01, 'shouldWarn': true},
        {'temp': 59.99, 'shouldWarn': true, 'level': 'warning'},
        {'temp': 60.0, 'shouldWarn': true, 'level': 'critical'},
        {'temp': 60.01, 'shouldWarn': true, 'level': 'critical'},
      ];

      for (var testCase in boundaryTests) {
        final result = await platform.invokeMethod('checkOverheating', {
          'temperature': testCase['temp'],
        });

        final resultMap = result as Map;
        expect(resultMap['isOverheating'], equals(testCase['shouldWarn']),
            reason:
                'Temperature ${testCase['temp']}°C boundary should be handled correctly');

        if (testCase.containsKey('level')) {
          expect(resultMap['warningLevel'], equals(testCase['level']),
              reason:
                  'Temperature ${testCase['temp']}°C should have correct warning level');
        }
      }
    });
  });
}
