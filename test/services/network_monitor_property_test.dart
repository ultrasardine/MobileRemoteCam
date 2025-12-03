import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ip_camera_streaming/services/network_monitor_service.dart';
import 'dart:async';

/// **Feature: ip-camera-streaming-platform, Property 26: Network changes update IP address**
///
/// Property: For any network change event (WiFi to cellular, network reconnection),
/// the system should detect the change and update the displayed IP address within 5 seconds.
///
/// **Validates: Requirements 7.1**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 26: Network changes update IP address', () {
    late NetworkMonitorService networkMonitor;
    late List<MethodCall> methodCalls;

    setUp(() {
      methodCalls = [];
      networkMonitor = NetworkMonitorService();

      // Set up method channel mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ipcamera/network'),
        (MethodCall methodCall) async {
          methodCalls.add(methodCall);

          switch (methodCall.method) {
            case 'startNetworkMonitoring':
              return null;
            case 'stopNetworkMonitoring':
              return null;
            case 'getCurrentNetwork':
              return {
                'networkType': 'wifi',
                'ipAddress': '192.168.1.100',
              };
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ipcamera/network'),
        null,
      );
    });

    test('Network change event updates IP address', () async {
      // Start monitoring
      await networkMonitor.startMonitoring();

      // Verify startNetworkMonitoring was called
      expect(
        methodCalls.any((call) => call.method == 'startNetworkMonitoring'),
        isTrue,
        reason: 'startNetworkMonitoring should be called',
      );

      // Set up stream listener
      final networkChanges = <NetworkChange>[];
      final subscription = networkMonitor.networkChanges.listen((change) {
        networkChanges.add(change);
      });

      // Simulate network change from platform
      final completer = Completer<void>();

      // Simulate network change callback
      Future.delayed(const Duration(milliseconds: 100), () async {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.ipcamera/network',
          const StandardMethodCodec().encodeMethodCall(
            const MethodCall('onNetworkChanged', {
              'networkType': 'cellular',
              'ipAddress': '10.0.0.50',
            }),
          ),
          (ByteData? data) {},
        );

        // Wait a bit for the event to propagate
        await Future.delayed(const Duration(milliseconds: 100));
        completer.complete();
      });

      await completer.future;

      // Verify network change was detected
      expect(networkChanges.length, greaterThan(0),
          reason: 'Network change should be detected');

      if (networkChanges.isNotEmpty) {
        final change = networkChanges.first;
        expect(change.networkType, equals(NetworkType.cellular),
            reason: 'Network type should be updated to cellular');
        expect(change.ipAddress, equals('10.0.0.50'),
            reason: 'IP address should be updated');
      }

      await subscription.cancel();
      await networkMonitor.stopMonitoring();
    });

    test('Multiple network changes update IP address correctly', () async {
      await networkMonitor.startMonitoring();

      final networkChanges = <NetworkChange>[];
      final subscription = networkMonitor.networkChanges.listen((change) {
        networkChanges.add(change);
      });

      // Simulate multiple network changes
      final changes = [
        {'networkType': 'wifi', 'ipAddress': '192.168.1.100'},
        {'networkType': 'cellular', 'ipAddress': '10.0.0.50'},
        {'networkType': 'wifi', 'ipAddress': '192.168.1.101'},
      ];

      for (final changeData in changes) {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.ipcamera/network',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onNetworkChanged', changeData),
          ),
          (ByteData? data) {},
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      // Wait for all events to propagate
      await Future.delayed(const Duration(milliseconds: 200));

      // Verify all changes were detected
      expect(networkChanges.length, equals(changes.length),
          reason: 'All network changes should be detected');

      // Verify IP addresses were updated correctly
      for (int i = 0; i < networkChanges.length; i++) {
        expect(networkChanges[i].ipAddress, equals(changes[i]['ipAddress']),
            reason: 'IP address should match for change $i');
      }

      await subscription.cancel();
      await networkMonitor.stopMonitoring();
    });

    test('getCurrentNetwork returns current network information', () async {
      final network = await networkMonitor.getCurrentNetwork();

      expect(network.networkType, equals(NetworkType.wifi),
          reason: 'Should return current network type');
      expect(network.ipAddress, equals('192.168.1.100'),
          reason: 'Should return current IP address');

      // Verify getCurrentNetwork was called
      expect(
        methodCalls.any((call) => call.method == 'getCurrentNetwork'),
        isTrue,
        reason: 'getCurrentNetwork should be called',
      );
    });

    test('Network type is correctly parsed', () async {
      await networkMonitor.startMonitoring();

      final networkChanges = <NetworkChange>[];
      final subscription = networkMonitor.networkChanges.listen((change) {
        networkChanges.add(change);
      });

      // Test different network types
      final networkTypes = [
        {'type': 'wifi', 'expected': NetworkType.wifi},
        {'type': 'cellular', 'expected': NetworkType.cellular},
        {'type': 'ethernet', 'expected': NetworkType.ethernet},
        {'type': 'none', 'expected': NetworkType.none},
        {'type': 'unknown', 'expected': NetworkType.unknown},
      ];

      for (final typeData in networkTypes) {
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.ipcamera/network',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onNetworkChanged', {
              'networkType': typeData['type'],
              'ipAddress': '192.168.1.1',
            }),
          ),
          (ByteData? data) {},
        );
        await Future.delayed(const Duration(milliseconds: 50));
      }

      await Future.delayed(const Duration(milliseconds: 200));

      // Verify all network types were parsed correctly
      expect(networkChanges.length, equals(networkTypes.length),
          reason: 'All network type changes should be detected');

      for (int i = 0; i < networkChanges.length; i++) {
        expect(
            networkChanges[i].networkType, equals(networkTypes[i]['expected']),
            reason:
                'Network type should be parsed correctly for ${networkTypes[i]['type']}');
      }

      await subscription.cancel();
      await networkMonitor.stopMonitoring();
    });
  });
}
