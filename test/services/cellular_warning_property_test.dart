import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:ip_camera_streaming/services/network_monitor_service.dart';

/// **Feature: ip-camera-streaming-platform, Property 28: Cellular data triggers warning**
///
/// Property: For any network state where the device is connected via cellular data,
/// the system should display a warning about potential data usage.
///
/// **Validates: Requirements 7.4**
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Property 28: Cellular data triggers warning', () {
    late NetworkMonitorService networkMonitor;

    setUp(() {
      networkMonitor = NetworkMonitorService();

      // Set up method channel mock
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('com.ipcamera/network'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'startNetworkMonitoring':
              return null;
            case 'stopNetworkMonitoring':
              return null;
            case 'getCurrentNetwork':
              return {
                'networkType': 'cellular',
                'ipAddress': '10.0.0.50',
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

    test('Cellular network type is correctly identified', () async {
      await networkMonitor.startMonitoring();

      // Simulate cellular network change
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

      await Future.delayed(const Duration(milliseconds: 100));

      // Verify cellular network is detected
      expect(networkMonitor.isCellular, isTrue,
          reason: 'Should detect cellular network');
      expect(networkMonitor.currentNetworkType, equals(NetworkType.cellular),
          reason: 'Current network type should be cellular');

      await networkMonitor.stopMonitoring();
    });

    test('Non-cellular networks do not trigger cellular flag', () async {
      await networkMonitor.startMonitoring();

      final nonCellularTypes = ['wifi', 'ethernet', 'none', 'unknown'];

      for (final networkType in nonCellularTypes) {
        // Simulate network change
        await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .handlePlatformMessage(
          'com.ipcamera/network',
          const StandardMethodCodec().encodeMethodCall(
            MethodCall('onNetworkChanged', {
              'networkType': networkType,
              'ipAddress': '192.168.1.100',
            }),
          ),
          (ByteData? data) {},
        );

        await Future.delayed(const Duration(milliseconds: 50));

        // Verify cellular flag is false
        expect(networkMonitor.isCellular, isFalse,
            reason: 'Should not detect cellular for $networkType');
      }

      await networkMonitor.stopMonitoring();
    });

    test('Switching from WiFi to cellular triggers cellular flag', () async {
      await networkMonitor.startMonitoring();

      // Start with WiFi
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.ipcamera/network',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onNetworkChanged', {
            'networkType': 'wifi',
            'ipAddress': '192.168.1.100',
          }),
        ),
        (ByteData? data) {},
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkMonitor.isCellular, isFalse,
          reason: 'Should not be cellular initially');

      // Switch to cellular
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

      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkMonitor.isCellular, isTrue,
          reason: 'Should detect cellular after switch');

      await networkMonitor.stopMonitoring();
    });

    test('Switching from cellular to WiFi clears cellular flag', () async {
      await networkMonitor.startMonitoring();

      // Start with cellular
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

      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkMonitor.isCellular, isTrue,
          reason: 'Should be cellular initially');

      // Switch to WiFi
      await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .handlePlatformMessage(
        'com.ipcamera/network',
        const StandardMethodCodec().encodeMethodCall(
          const MethodCall('onNetworkChanged', {
            'networkType': 'wifi',
            'ipAddress': '192.168.1.100',
          }),
        ),
        (ByteData? data) {},
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkMonitor.isCellular, isFalse,
          reason: 'Should not be cellular after switch to WiFi');

      await networkMonitor.stopMonitoring();
    });

    test('getCurrentNetwork correctly identifies cellular connection',
        () async {
      // Mock returns cellular network
      final network = await networkMonitor.getCurrentNetwork();

      expect(network.networkType, equals(NetworkType.cellular),
          reason: 'Should identify cellular network type');

      // Update internal state
      await networkMonitor.startMonitoring();
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

      await Future.delayed(const Duration(milliseconds: 50));

      expect(networkMonitor.isCellular, isTrue,
          reason: 'isCellular should be true for cellular network');

      await networkMonitor.stopMonitoring();
    });

    test('Network changes stream includes cellular network events', () async {
      await networkMonitor.startMonitoring();

      final networkChanges = <NetworkChange>[];
      final subscription = networkMonitor.networkChanges.listen((change) {
        networkChanges.add(change);
      });

      // Simulate various network changes including cellular
      final changes = [
        {'networkType': 'wifi', 'ipAddress': '192.168.1.100'},
        {'networkType': 'cellular', 'ipAddress': '10.0.0.50'},
        {'networkType': 'wifi', 'ipAddress': '192.168.1.101'},
        {'networkType': 'cellular', 'ipAddress': '10.0.0.51'},
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

      await Future.delayed(const Duration(milliseconds: 200));

      // Verify cellular events were captured
      final cellularChanges = networkChanges
          .where((change) => change.networkType == NetworkType.cellular)
          .toList();

      expect(cellularChanges.length, equals(2),
          reason: 'Should capture both cellular network changes');

      expect(cellularChanges[0].ipAddress, equals('10.0.0.50'),
          reason: 'First cellular change should have correct IP');
      expect(cellularChanges[1].ipAddress, equals('10.0.0.51'),
          reason: 'Second cellular change should have correct IP');

      await subscription.cancel();
      await networkMonitor.stopMonitoring();
    });
  });
}
