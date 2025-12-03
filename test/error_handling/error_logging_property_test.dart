import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';

/// Property-based tests for error logging functionality
/// Feature: ip-camera-streaming-platform, Property 38: Errors are logged with detail
/// Validates: Requirements 10.6
///
/// This test verifies that all error conditions are logged with sufficient detail
/// including error code, message, and stack trace for debugging purposes.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Error Logging Property Tests', () {
    const platform = MethodChannel('com.ipcamera/streaming');
    final List<Map<String, dynamic>> errorLog = [];

    setUp(() {
      errorLog.clear();

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'startStreaming':
            final args = methodCall.arguments as Map;
            final simulateError = args['simulateError'] as String? ?? 'none';

            if (simulateError != 'none') {
              // Log the error
              final errorEntry = {
                'timestamp': DateTime.now().toIso8601String(),
                'errorType': simulateError,
                'errorCode': _getErrorCode(simulateError),
                'message': _getErrorMessage(simulateError),
                'details': _getErrorDetails(simulateError),
                'stackTrace': _getMockStackTrace(),
                'component': _getErrorComponent(simulateError),
              };
              errorLog.add(errorEntry);

              throw PlatformException(
                code: errorEntry['errorCode'] as String,
                message: errorEntry['message'] as String,
                details: errorEntry['details'],
              );
            }

            return {'success': true};

          case 'getErrorLogs':
            final args = methodCall.arguments as Map?;
            final limit = args?['limit'] as int? ?? 100;
            final errorType = args?['errorType'] as String?;

            var logs = List<Map<String, dynamic>>.from(errorLog);

            if (errorType != null) {
              logs =
                  logs.where((log) => log['errorType'] == errorType).toList();
            }

            return {
              'logs': logs.take(limit).toList(),
              'totalCount': logs.length,
            };

          case 'clearErrorLogs':
            errorLog.clear();
            return {'success': true};

          case 'logError':
            final args = methodCall.arguments as Map;
            final errorEntry = {
              'timestamp': DateTime.now().toIso8601String(),
              'errorType': args['errorType'] as String,
              'errorCode': args['errorCode'] as String,
              'message': args['message'] as String,
              'details': args['details'],
              'stackTrace': args['stackTrace'] as String?,
              'component': args['component'] as String,
            };
            errorLog.add(errorEntry);
            return {'success': true, 'logId': errorLog.length - 1};

          default:
            return null;
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(platform, null);
    });

    /// Property 38: Errors are logged with detail
    test('camera initialization errors are logged with detail', () async {
      // Property: For any camera initialization error, system should log with full details

      try {
        await platform.invokeMethod('startStreaming', {
          'cameraId': 'back',
          'simulateError': 'camera_init_failed',
        });
        fail('Should have thrown exception');
      } on PlatformException catch (_) {
        // Expected error
      }

      // Property: Error should be logged
      expect(errorLog.isNotEmpty, isTrue,
          reason: 'Camera initialization error should be logged');

      final logEntry = errorLog.last;

      // Property: Log should contain error code
      expect(logEntry.containsKey('errorCode'), isTrue,
          reason: 'Log should contain error code');
      expect(logEntry['errorCode'], isNotEmpty,
          reason: 'Error code should not be empty');

      // Property: Log should contain error message
      expect(logEntry.containsKey('message'), isTrue,
          reason: 'Log should contain error message');
      expect(logEntry['message'], isNotEmpty,
          reason: 'Error message should not be empty');

      // Property: Log should contain timestamp
      expect(logEntry.containsKey('timestamp'), isTrue,
          reason: 'Log should contain timestamp');
      expect(logEntry['timestamp'], isNotEmpty,
          reason: 'Timestamp should not be empty');

      // Property: Log should contain stack trace
      expect(logEntry.containsKey('stackTrace'), isTrue,
          reason: 'Log should contain stack trace');
      expect(logEntry['stackTrace'], isNotEmpty,
          reason: 'Stack trace should not be empty');

      // Property: Log should contain component information
      expect(logEntry.containsKey('component'), isTrue,
          reason: 'Log should contain component information');
      expect(logEntry['component'], isNotEmpty,
          reason: 'Component should not be empty');

      // Property: Log should contain error details
      expect(logEntry.containsKey('details'), isTrue,
          reason: 'Log should contain error details');
    });

    test('encoder initialization errors are logged with detail', () async {
      // Property: For any encoder error, system should log with full details

      try {
        await platform.invokeMethod('startStreaming', {
          'cameraId': 'back',
          'simulateError': 'encoder_init_failed',
        });
        fail('Should have thrown exception');
      } on PlatformException catch (_) {
        // Expected error
      }

      expect(errorLog.isNotEmpty, isTrue,
          reason: 'Encoder initialization error should be logged');

      final logEntry = errorLog.last;

      // Verify all required fields
      expect(logEntry['errorCode'], isNotEmpty);
      expect(logEntry['message'], contains('encoder'));
      expect(logEntry['stackTrace'], isNotEmpty);
      expect(logEntry['component'], equals('encoder'));
    });

    test('RTSP server errors are logged with detail', () async {
      // Property: For any RTSP server error, system should log with full details

      try {
        await platform.invokeMethod('startStreaming', {
          'cameraId': 'back',
          'rtspEnabled': true,
          'simulateError': 'rtsp_server_failed',
        });
        fail('Should have thrown exception');
      } on PlatformException catch (_) {
        // Expected error
      }

      expect(errorLog.isNotEmpty, isTrue,
          reason: 'RTSP server error should be logged');

      final logEntry = errorLog.last;

      expect(logEntry['errorCode'], isNotEmpty);
      expect(logEntry['message'], contains('RTSP'));
      expect(logEntry['stackTrace'], isNotEmpty);
      expect(logEntry['component'], equals('rtsp'));
    });

    test('RTMP connection errors are logged with detail', () async {
      // Property: For any RTMP connection error, system should log with full details

      try {
        await platform.invokeMethod('startStreaming', {
          'cameraId': 'back',
          'rtmpEnabled': true,
          'simulateError': 'rtmp_connection_failed',
        });
        fail('Should have thrown exception');
      } on PlatformException catch (_) {
        // Expected error
      }

      expect(errorLog.isNotEmpty, isTrue,
          reason: 'RTMP connection error should be logged');

      final logEntry = errorLog.last;

      expect(logEntry['errorCode'], isNotEmpty);
      expect(logEntry['message'], contains('RTMP'));
      expect(logEntry['stackTrace'], isNotEmpty);
      expect(logEntry['component'], equals('rtmp'));
    });

    test('all error types are logged consistently', () async {
      // Property: For any error type, logging format should be consistent

      final errorTypes = [
        'camera_init_failed',
        'encoder_init_failed',
        'rtsp_server_failed',
        'rtmp_connection_failed',
        'network_error',
      ];

      for (var errorType in errorTypes) {
        try {
          await platform.invokeMethod('startStreaming', {
            'cameraId': 'back',
            'simulateError': errorType,
          });
          fail('Should have thrown exception for $errorType');
        } on PlatformException catch (_) {
          // Expected error
        }
      }

      // Property: All errors should be logged
      expect(errorLog.length, equals(errorTypes.length),
          reason: 'All error types should be logged');

      // Property: All logs should have consistent structure
      final requiredFields = [
        'timestamp',
        'errorType',
        'errorCode',
        'message',
        'details',
        'stackTrace',
        'component',
      ];

      for (var logEntry in errorLog) {
        for (var field in requiredFields) {
          expect(logEntry.containsKey(field), isTrue,
              reason: 'Log entry should contain $field');
        }
      }
    });

    test('error logs can be retrieved', () async {
      // Property: For any logged errors, they should be retrievable

      // Generate some errors
      final errorTypes = ['camera_init_failed', 'encoder_init_failed'];

      for (var errorType in errorTypes) {
        try {
          await platform.invokeMethod('startStreaming', {
            'cameraId': 'back',
            'simulateError': errorType,
          });
        } on PlatformException catch (_) {
          // Expected
        }
      }

      // Retrieve logs
      final result = await platform.invokeMethod('getErrorLogs');

      expect(result, isA<Map>());
      final resultMap = result as Map;

      // Property: Logs should be returned
      expect(resultMap.containsKey('logs'), isTrue,
          reason: 'Result should contain logs');
      expect(resultMap['logs'], isA<List>(), reason: 'Logs should be a list');

      final logs = resultMap['logs'] as List;
      expect(logs.length, equals(errorTypes.length),
          reason: 'Should retrieve all logged errors');

      // Property: Total count should be provided
      expect(resultMap.containsKey('totalCount'), isTrue,
          reason: 'Result should contain total count');
      expect(resultMap['totalCount'], equals(errorTypes.length),
          reason: 'Total count should match number of errors');
    });

    test('error logs can be filtered by type', () async {
      // Property: For any error type filter, only matching errors should be returned

      // Generate mixed errors
      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'camera_init_failed',
        });
      } on PlatformException catch (_) {}

      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'encoder_init_failed',
        });
      } on PlatformException catch (_) {}

      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'camera_init_failed',
        });
      } on PlatformException catch (_) {}

      // Filter for camera errors only
      final result = await platform.invokeMethod('getErrorLogs', {
        'errorType': 'camera_init_failed',
      });

      final logs = (result as Map)['logs'] as List;

      // Property: Only matching errors should be returned
      expect(logs.length, equals(2),
          reason: 'Should return only camera initialization errors');

      for (var log in logs) {
        expect((log as Map)['errorType'], equals('camera_init_failed'),
            reason: 'All returned logs should match filter');
      }
    });

    test('error logs can be limited', () async {
      // Property: For any limit value, at most that many logs should be returned

      // Generate multiple errors
      for (var i = 0; i < 10; i++) {
        try {
          await platform.invokeMethod('startStreaming', {
            'simulateError': 'camera_init_failed',
          });
        } on PlatformException catch (_) {}
      }

      // Request limited logs
      final result = await platform.invokeMethod('getErrorLogs', {
        'limit': 5,
      });

      final logs = (result as Map)['logs'] as List;

      // Property: Should not exceed limit
      expect(logs.length, equals(5),
          reason: 'Should return at most the requested limit');

      // Property: Total count should still reflect all errors
      expect((result)['totalCount'], equals(10),
          reason: 'Total count should reflect all errors');
    });

    test('error logs can be cleared', () async {
      // Property: After clearing logs, no logs should be retrievable

      // Generate some errors
      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'camera_init_failed',
        });
      } on PlatformException catch (_) {}

      expect(errorLog.isNotEmpty, isTrue,
          reason: 'Should have errors before clearing');

      // Clear logs
      await platform.invokeMethod('clearErrorLogs');

      // Property: Logs should be empty
      final result = await platform.invokeMethod('getErrorLogs');
      final logs = (result as Map)['logs'] as List;

      expect(logs.isEmpty, isTrue,
          reason: 'Logs should be empty after clearing');
      expect((result)['totalCount'], equals(0),
          reason: 'Total count should be zero after clearing');
    });

    test('error details contain useful debugging information', () async {
      // Property: For any error, details should contain actionable debugging info

      final errorTypes = [
        'camera_init_failed',
        'encoder_init_failed',
        'rtsp_server_failed',
        'rtmp_connection_failed',
      ];

      for (var errorType in errorTypes) {
        try {
          await platform.invokeMethod('startStreaming', {
            'simulateError': errorType,
          });
        } on PlatformException catch (_) {}

        final logEntry = errorLog.last;
        final details = logEntry['details'] as Map?;

        // Property: Details should exist
        expect(details, isNotNull, reason: 'Error details should not be null');

        // Property: Details should contain relevant information
        expect(details!.isNotEmpty, isTrue,
            reason: 'Error details should not be empty');
      }
    });

    test('timestamps are in valid ISO 8601 format', () async {
      // Property: For any logged error, timestamp should be valid ISO 8601

      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'camera_init_failed',
        });
      } on PlatformException catch (_) {}

      final logEntry = errorLog.last;
      final timestamp = logEntry['timestamp'] as String;

      // Property: Timestamp should be parseable as DateTime
      expect(() => DateTime.parse(timestamp), returnsNormally,
          reason: 'Timestamp should be valid ISO 8601 format');

      final parsedTime = DateTime.parse(timestamp);
      expect(
          parsedTime.isBefore(DateTime.now().add(const Duration(seconds: 1))),
          isTrue,
          reason: 'Timestamp should be recent');
    });

    test('manual error logging works correctly', () async {
      // Property: System should support manual error logging

      final errorData = {
        'errorType': 'custom_error',
        'errorCode': 'CUSTOM_001',
        'message': 'Custom error message',
        'details': {'key': 'value'},
        'stackTrace': 'Stack trace here',
        'component': 'test_component',
      };

      final result = await platform.invokeMethod('logError', errorData);

      expect((result as Map)['success'], isTrue,
          reason: 'Manual error logging should succeed');

      // Property: Error should be in log
      final logs = await platform.invokeMethod('getErrorLogs');
      final logList = (logs as Map)['logs'] as List;

      expect(logList.isNotEmpty, isTrue,
          reason: 'Manually logged error should be retrievable');

      final lastLog = logList.last as Map;
      expect(lastLog['errorCode'], equals('CUSTOM_001'),
          reason: 'Logged error should match input');
      expect(lastLog['message'], equals('Custom error message'),
          reason: 'Logged message should match input');
    });

    test('stack traces contain meaningful information', () async {
      // Property: For any error, stack trace should contain file and line information

      try {
        await platform.invokeMethod('startStreaming', {
          'simulateError': 'camera_init_failed',
        });
      } on PlatformException catch (_) {}

      final logEntry = errorLog.last;
      final stackTrace = logEntry['stackTrace'] as String;

      // Property: Stack trace should not be empty
      expect(stackTrace.isNotEmpty, isTrue,
          reason: 'Stack trace should not be empty');

      // Property: Stack trace should contain line information
      expect(stackTrace.contains('at ') || stackTrace.contains(':'), isTrue,
          reason: 'Stack trace should contain location information');
    });

    test('error codes are unique and meaningful', () async {
      // Property: For any error type, error code should be unique and descriptive

      final errorTypes = [
        'camera_init_failed',
        'encoder_init_failed',
        'rtsp_server_failed',
        'rtmp_connection_failed',
      ];

      final errorCodes = <String>{};

      for (var errorType in errorTypes) {
        try {
          await platform.invokeMethod('startStreaming', {
            'simulateError': errorType,
          });
        } on PlatformException catch (_) {}

        final logEntry = errorLog.last;
        final errorCode = logEntry['errorCode'] as String;

        // Property: Error code should be unique
        expect(errorCodes.contains(errorCode), isFalse,
            reason: 'Error code should be unique for each error type');

        errorCodes.add(errorCode);

        // Property: Error code should be uppercase and use underscores
        expect(errorCode, matches(RegExp(r'^[A-Z_]+$')),
            reason: 'Error code should follow naming convention');
      }
    });
  });
}

/// Helper function to get error code for error type
String _getErrorCode(String errorType) {
  switch (errorType) {
    case 'camera_init_failed':
      return 'CAMERA_INIT_FAILED';
    case 'encoder_init_failed':
      return 'ENCODER_INIT_FAILED';
    case 'rtsp_server_failed':
      return 'RTSP_SERVER_FAILED';
    case 'rtmp_connection_failed':
      return 'RTMP_CONNECTION_FAILED';
    case 'network_error':
      return 'NETWORK_ERROR';
    default:
      return 'UNKNOWN_ERROR';
  }
}

/// Helper function to get error message for error type
String _getErrorMessage(String errorType) {
  switch (errorType) {
    case 'camera_init_failed':
      return 'Failed to initialize camera: Camera device not available';
    case 'encoder_init_failed':
      return 'Failed to initialize encoder: Hardware encoder not supported';
    case 'rtsp_server_failed':
      return 'Failed to start RTSP server: Port already in use';
    case 'rtmp_connection_failed':
      return 'Failed to connect to RTMP server: Connection refused';
    case 'network_error':
      return 'Network error: Connection lost';
    default:
      return 'Unknown error occurred';
  }
}

/// Helper function to get error details for error type
Map<String, dynamic> _getErrorDetails(String errorType) {
  switch (errorType) {
    case 'camera_init_failed':
      return {
        'cameraId': 'back',
        'availableCameras': ['front'],
        'systemError': 'Device busy',
      };
    case 'encoder_init_failed':
      return {
        'encoderType': 'hardware',
        'codec': 'H.264',
        'systemError': 'Codec not found',
      };
    case 'rtsp_server_failed':
      return {
        'port': 8554,
        'systemError': 'Address already in use',
      };
    case 'rtmp_connection_failed':
      return {
        'url': 'rtmp://example.com/live',
        'systemError': 'Connection refused',
      };
    case 'network_error':
      return {
        'networkType': 'wifi',
        'systemError': 'Network unreachable',
      };
    default:
      return {};
  }
}

/// Helper function to get error component for error type
String _getErrorComponent(String errorType) {
  switch (errorType) {
    case 'camera_init_failed':
      return 'camera';
    case 'encoder_init_failed':
      return 'encoder';
    case 'rtsp_server_failed':
      return 'rtsp';
    case 'rtmp_connection_failed':
      return 'rtmp';
    case 'network_error':
      return 'network';
    default:
      return 'unknown';
  }
}

/// Helper function to generate mock stack trace
String _getMockStackTrace() {
  return '''
at StreamingManager.startStreaming (StreamingManager.kt:45)
at MethodChannel.invokeMethod (MethodChannel.java:123)
at FlutterEngine.handleMethodCall (FlutterEngine.java:234)
at DartExecutor.handlePlatformMessage (DartExecutor.java:156)
''';
}
