import 'dart:async';
import 'package:flutter/services.dart';

/// Network connection type
enum NetworkType {
  wifi,
  cellular,
  ethernet,
  none,
  unknown,
}

/// Network monitoring service that detects network changes
class NetworkMonitorService {
  static const platform = MethodChannel('com.ipcamera/network');

  final _networkChangeController = StreamController<NetworkChange>.broadcast();

  /// Stream of network change events
  Stream<NetworkChange> get networkChanges => _networkChangeController.stream;

  NetworkType _currentNetworkType = NetworkType.unknown;
  String _currentIpAddress = '';

  NetworkMonitorService() {
    _setupMethodCallHandler();
  }

  void _setupMethodCallHandler() {
    platform.setMethodCallHandler((call) async {
      if (call.method == 'onNetworkChanged') {
        final Map<dynamic, dynamic> data = call.arguments;
        final networkType = _parseNetworkType(data['networkType'] as String);
        final ipAddress = data['ipAddress'] as String? ?? '';

        _currentNetworkType = networkType;
        _currentIpAddress = ipAddress;

        _networkChangeController.add(NetworkChange(
          networkType: networkType,
          ipAddress: ipAddress,
        ));
      }
    });
  }

  /// Start monitoring network changes
  Future<void> startMonitoring() async {
    try {
      await platform.invokeMethod('startNetworkMonitoring');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to start network monitoring: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Stop monitoring network changes
  Future<void> stopMonitoring() async {
    try {
      await platform.invokeMethod('stopNetworkMonitoring');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to stop network monitoring: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get current network information
  Future<NetworkChange> getCurrentNetwork() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getCurrentNetwork',
      );

      final networkType = _parseNetworkType(result['networkType'] as String);
      final ipAddress = result['ipAddress'] as String? ?? '';

      _currentNetworkType = networkType;
      _currentIpAddress = ipAddress;

      return NetworkChange(
        networkType: networkType,
        ipAddress: ipAddress,
      );
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get current network: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Check if currently on cellular data
  bool get isCellular => _currentNetworkType == NetworkType.cellular;

  /// Get current IP address
  String get currentIpAddress => _currentIpAddress;

  /// Get current network type
  NetworkType get currentNetworkType => _currentNetworkType;

  NetworkType _parseNetworkType(String type) {
    switch (type.toLowerCase()) {
      case 'wifi':
        return NetworkType.wifi;
      case 'cellular':
        return NetworkType.cellular;
      case 'ethernet':
        return NetworkType.ethernet;
      case 'none':
        return NetworkType.none;
      default:
        return NetworkType.unknown;
    }
  }

  void dispose() {
    _networkChangeController.close();
  }
}

/// Network change event data
class NetworkChange {
  final NetworkType networkType;
  final String ipAddress;

  NetworkChange({
    required this.networkType,
    required this.ipAddress,
  });

  @override
  String toString() => 'NetworkChange(type: $networkType, ip: $ipAddress)';
}
