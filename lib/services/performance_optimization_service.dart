import 'dart:async';
import 'package:flutter/services.dart';
import '../models/stream_config.dart';
import '../models/stream_statistics.dart';
import 'network_monitor_service.dart';

/// Performance optimization service that handles adaptive bitrate,
/// battery optimization, and memory management
class PerformanceOptimizationService {
  static const platform = MethodChannel('com.ipcamera/performance');

  final NetworkMonitorService _networkMonitor;
  StreamConfig? _currentConfig;
  Timer? _optimizationTimer;

  // Performance thresholds
  static const double _lowBatteryThreshold = 20.0;
  static const double _criticalBatteryThreshold = 10.0;
  static const int _highDroppedFramesThreshold = 50;
  static const double _lowBandwidthBitrateThreshold = 2.0; // Mbps

  PerformanceOptimizationService(this._networkMonitor);

  /// Start performance monitoring and optimization
  Future<void> startOptimization(StreamConfig config) async {
    _currentConfig = config;

    // Enable buffer pooling on native side
    await _enableBufferPooling();

    // Start periodic optimization checks
    _optimizationTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _performOptimizationCheck(),
    );
  }

  /// Stop performance optimization
  Future<void> stopOptimization() async {
    _optimizationTimer?.cancel();
    _optimizationTimer = null;
    _currentConfig = null;

    // Disable buffer pooling
    await _disableBufferPooling();
  }

  /// Enable buffer pooling for memory optimization
  Future<void> _enableBufferPooling() async {
    try {
      await platform.invokeMethod('enableBufferPooling');
    } on PlatformException catch (e) {
      // Log but don't fail - buffer pooling is an optimization
      print('Failed to enable buffer pooling: ${e.message}');
    }
  }

  /// Disable buffer pooling
  Future<void> _disableBufferPooling() async {
    try {
      await platform.invokeMethod('disableBufferPooling');
    } on PlatformException catch (e) {
      print('Failed to disable buffer pooling: ${e.message}');
    }
  }

  /// Perform periodic optimization check
  Future<void> _performOptimizationCheck() async {
    if (_currentConfig == null) return;

    try {
      // Get current statistics
      final stats = await _getCurrentStatistics();

      // Check for battery optimization needs
      if (stats.batteryLevel <= _criticalBatteryThreshold) {
        await _applyCriticalBatteryOptimization();
      } else if (stats.batteryLevel <= _lowBatteryThreshold) {
        await _applyLowBatteryOptimization();
      }

      // Check for adaptive bitrate needs
      if (stats.droppedFrames > _highDroppedFramesThreshold ||
          stats.currentBitrate < _lowBandwidthBitrateThreshold) {
        await _applyAdaptiveBitrate(stats);
      }

      // Check for thermal throttling needs
      if (stats.deviceTemperature > 50.0) {
        await _applyThermalThrottling();
      }
    } catch (e) {
      // Log but don't fail - optimization is best-effort
      print('Optimization check failed: $e');
    }
  }

  /// Get current streaming statistics
  Future<StreamStatistics> _getCurrentStatistics() async {
    try {
      final result = await platform.invokeMethod('getStatistics');
      return StreamStatistics.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get statistics: ${e.message}',
      );
    }
  }

  /// Apply critical battery optimization (most aggressive)
  Future<void> _applyCriticalBatteryOptimization() async {
    if (_currentConfig == null) return;

    try {
      // Reduce to minimum viable settings
      await platform.invokeMethod('applyBatteryOptimization', {
        'level': 'critical',
        'reduceFrameRate': true,
        'reduceBitrate': true,
        'disablePreview': true,
        'targetFrameRate': 15,
        'targetBitrate': 1000000, // 1 Mbps
      });
    } on PlatformException catch (e) {
      print('Failed to apply critical battery optimization: ${e.message}');
    }
  }

  /// Apply low battery optimization (moderate)
  Future<void> _applyLowBatteryOptimization() async {
    if (_currentConfig == null) return;

    try {
      await platform.invokeMethod('applyBatteryOptimization', {
        'level': 'low',
        'reduceFrameRate': true,
        'reduceBitrate': true,
        'disablePreview': false,
        'targetFrameRate': 24,
        'targetBitrate': 2000000, // 2 Mbps
      });
    } on PlatformException catch (e) {
      print('Failed to apply low battery optimization: ${e.message}');
    }
  }

  /// Apply adaptive bitrate based on network conditions
  Future<void> _applyAdaptiveBitrate(StreamStatistics stats) async {
    if (_currentConfig == null) return;

    try {
      // Calculate target bitrate based on dropped frames and current bitrate
      final droppedFrameRatio = stats.droppedFrames /
          (stats.currentFps * 2.0); // Frames in last 2 seconds

      int targetBitrate = _currentConfig!.bitrate;

      if (droppedFrameRatio > 0.1) {
        // More than 10% dropped frames - reduce bitrate by 20%
        targetBitrate = (targetBitrate * 0.8).toInt();
      } else if (droppedFrameRatio < 0.02 &&
          stats.currentBitrate < _currentConfig!.bitrate / 1000000) {
        // Less than 2% dropped frames and below target - increase bitrate by 10%
        targetBitrate = (targetBitrate * 1.1).toInt();
      }

      // Clamp to reasonable range (1-10 Mbps)
      targetBitrate = targetBitrate.clamp(1000000, 10000000);

      // Apply adaptive bitrate if changed significantly
      if ((targetBitrate - _currentConfig!.bitrate).abs() > 500000) {
        await platform.invokeMethod('applyAdaptiveBitrate', {
          'targetBitrate': targetBitrate,
        });
      }
    } on PlatformException catch (e) {
      print('Failed to apply adaptive bitrate: ${e.message}');
    }
  }

  /// Apply thermal throttling to prevent overheating
  Future<void> _applyThermalThrottling() async {
    if (_currentConfig == null) return;

    try {
      await platform.invokeMethod('applyThermalThrottling', {
        'reduceFrameRate': true,
        'reduceBitrate': true,
        'targetFrameRate': 24,
        'targetBitrate': 3000000, // 3 Mbps
      });
    } on PlatformException catch (e) {
      print('Failed to apply thermal throttling: ${e.message}');
    }
  }

  /// Manually trigger adaptive bitrate adjustment
  Future<void> adjustBitrate(int targetBitrate) async {
    try {
      await platform.invokeMethod('applyAdaptiveBitrate', {
        'targetBitrate': targetBitrate.clamp(1000000, 10000000),
      });
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to adjust bitrate: ${e.message}',
      );
    }
  }

  /// Get encoding latency statistics
  Future<EncodingLatencyStats> getEncodingLatency() async {
    try {
      final result = await platform.invokeMethod('getEncodingLatency');
      return EncodingLatencyStats.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get encoding latency: ${e.message}',
      );
    }
  }

  /// Get memory usage statistics
  Future<MemoryUsageStats> getMemoryUsage() async {
    try {
      final result = await platform.invokeMethod('getMemoryUsage');
      return MemoryUsageStats.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get memory usage: ${e.message}',
      );
    }
  }

  /// Force garbage collection and buffer pool cleanup
  Future<void> forceCleanup() async {
    try {
      await platform.invokeMethod('forceCleanup');
    } on PlatformException catch (e) {
      print('Failed to force cleanup: ${e.message}');
    }
  }

  void dispose() {
    _optimizationTimer?.cancel();
  }
}

/// Encoding latency statistics
class EncodingLatencyStats {
  final double averageLatencyMs;
  final double maxLatencyMs;
  final double minLatencyMs;
  final int sampleCount;

  EncodingLatencyStats({
    required this.averageLatencyMs,
    required this.maxLatencyMs,
    required this.minLatencyMs,
    required this.sampleCount,
  });

  factory EncodingLatencyStats.fromMap(Map<String, dynamic> map) {
    return EncodingLatencyStats(
      averageLatencyMs: (map['averageLatencyMs'] as num).toDouble(),
      maxLatencyMs: (map['maxLatencyMs'] as num).toDouble(),
      minLatencyMs: (map['minLatencyMs'] as num).toDouble(),
      sampleCount: map['sampleCount'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'averageLatencyMs': averageLatencyMs,
      'maxLatencyMs': maxLatencyMs,
      'minLatencyMs': minLatencyMs,
      'sampleCount': sampleCount,
    };
  }
}

/// Memory usage statistics
class MemoryUsageStats {
  final int bufferPoolSizeBytes;
  final int activeBuffersCount;
  final int totalAllocatedBytes;
  final int peakMemoryBytes;

  MemoryUsageStats({
    required this.bufferPoolSizeBytes,
    required this.activeBuffersCount,
    required this.totalAllocatedBytes,
    required this.peakMemoryBytes,
  });

  factory MemoryUsageStats.fromMap(Map<String, dynamic> map) {
    return MemoryUsageStats(
      bufferPoolSizeBytes: map['bufferPoolSizeBytes'] as int,
      activeBuffersCount: map['activeBuffersCount'] as int,
      totalAllocatedBytes: map['totalAllocatedBytes'] as int,
      peakMemoryBytes: map['peakMemoryBytes'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'bufferPoolSizeBytes': bufferPoolSizeBytes,
      'activeBuffersCount': activeBuffersCount,
      'totalAllocatedBytes': totalAllocatedBytes,
      'peakMemoryBytes': peakMemoryBytes,
    };
  }
}
