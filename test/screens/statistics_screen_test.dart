import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ip_camera_streaming/screens/statistics_screen.dart';
import 'package:ip_camera_streaming/controllers/streaming_controller.dart';
import 'package:ip_camera_streaming/models/stream_statistics.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Statistics Screen Widget Tests', () {
    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(StreamingController.platform, null);
    });

    testWidgets('Statistics screen displays loading indicator initially',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('Statistics screen displays metrics when data is available',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.5,
        currentFps: 30,
        droppedFrames: 5,
        deviceTemperature: 40.0,
        batteryLevel: 75,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
          'rtmp': ConnectionStatus.disconnected,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      // Wait for statistics to load
      await tester.pumpAndSettle();

      // Verify metrics are displayed
      expect(find.text('5.50 Mbps'), findsOneWidget);
      expect(find.text('30 fps'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('40.0°C'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
    });

    testWidgets('Statistics screen displays connection status',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.0,
        currentFps: 30,
        droppedFrames: 0,
        deviceTemperature: 35.0,
        batteryLevel: 80,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
          'rtmp': ConnectionStatus.connecting,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify connection status is displayed
      expect(find.text('RTSP'), findsOneWidget);
      expect(find.text('RTMP'), findsOneWidget);
      expect(find.text('Connected'), findsOneWidget);
      expect(find.text('Connecting'), findsOneWidget);
    });

    testWidgets('Statistics screen shows temperature warning when temp > 45°C',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.0,
        currentFps: 30,
        droppedFrames: 0,
        deviceTemperature: 50.0,
        batteryLevel: 80,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify temperature warning is displayed
      expect(find.text('Performance Warnings'), findsOneWidget);
      expect(find.text('High Temperature'), findsOneWidget);
      expect(find.textContaining('50.0°C'), findsAtLeastNWidgets(1));
    });

    testWidgets('Statistics screen shows battery warning when battery < 15%',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.0,
        currentFps: 30,
        droppedFrames: 0,
        deviceTemperature: 35.0,
        batteryLevel: 10,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify battery warning is displayed
      expect(find.text('Performance Warnings'), findsOneWidget);
      expect(find.text('Low Battery'), findsOneWidget);
      expect(find.textContaining('10%'), findsAtLeastNWidgets(1));
    });

    testWidgets(
        'Statistics screen shows both warnings when both conditions met',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.0,
        currentFps: 30,
        droppedFrames: 0,
        deviceTemperature: 55.0,
        batteryLevel: 8,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify both warnings are displayed
      expect(find.text('Performance Warnings'), findsOneWidget);
      expect(find.text('High Temperature'), findsOneWidget);
      expect(find.text('Low Battery'), findsOneWidget);
    });

    testWidgets(
        'Statistics screen does not show warnings when conditions normal',
        (WidgetTester tester) async {
      final mockStats = StreamStatistics(
        currentBitrate: 5.0,
        currentFps: 30,
        droppedFrames: 0,
        deviceTemperature: 40.0,
        batteryLevel: 75,
        connectionStatus: {
          'rtsp': ConnectionStatus.connected,
        },
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            return mockStats.toMap();
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify no warnings are displayed
      expect(find.text('Performance Warnings'), findsNothing);
      expect(find.text('High Temperature'), findsNothing);
      expect(find.text('Low Battery'), findsNothing);
    });

    testWidgets('Statistics screen displays error message on failure',
        (WidgetTester tester) async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        StreamingController.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'getStatistics') {
            throw PlatformException(
              code: 'ERROR',
              message: 'Failed to get statistics',
            );
          }
          return null;
        },
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      await tester.pumpAndSettle();

      // Verify error message is displayed
      expect(find.textContaining('Failed to get statistics'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('Statistics screen has correct title',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: StatisticsScreen(),
        ),
      );

      expect(find.text('Streaming Statistics'), findsOneWidget);
    });
  });
}
