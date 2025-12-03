import 'package:flutter/services.dart';
import '../models/stream_config.dart';
import '../models/stream_statistics.dart';
import '../models/camera_info.dart';
import '../models/resolution.dart';
import '../models/error_info.dart';
import '../services/error_handling_service.dart';
import '../services/performance_optimization_service.dart';
import '../services/network_monitor_service.dart';

/// Primary interface between Flutter and native code for streaming operations
class StreamingController {
  static const platform = MethodChannel('com.ipcamera/streaming');
  final ErrorHandlingService _errorService = ErrorHandlingService();
  PerformanceOptimizationService? _performanceService;

  /// Start streaming with the provided configuration
  /// Handles encoder fallback automatically if hardware encoder fails
  /// Enables performance optimization if network monitor is provided
  Future<void> startStreaming(
    StreamConfig config, {
    NetworkMonitorService? networkMonitor,
    bool enablePerformanceOptimization = true,
  }) async {
    try {
      await platform.invokeMethod('startStreaming', config.toMap());

      // Start performance optimization if enabled
      if (enablePerformanceOptimization && networkMonitor != null) {
        _performanceService = PerformanceOptimizationService(networkMonitor);
        await _performanceService!.startOptimization(config);
      }
    } on PlatformException catch (e) {
      // Log the error
      if (e.code.contains('CAMERA')) {
        await _errorService.handleCameraError(e);
      } else if (e.code.contains('ENCODER')) {
        await _errorService.handleEncoderError(e);
      } else if (e.code.contains('RTSP')) {
        await _errorService.handleRTSPError(e);
      } else if (e.code.contains('RTMP')) {
        await _errorService.handleRTMPError(e);
      }

      throw PlatformException(
        code: e.code,
        message: 'Failed to start streaming: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Stop all streaming operations
  Future<void> stopStreaming() async {
    try {
      // Stop performance optimization first
      if (_performanceService != null) {
        await _performanceService!.stopOptimization();
        _performanceService = null;
      }

      await platform.invokeMethod('stopStreaming');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to stop streaming: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get current streaming statistics
  Future<StreamStatistics> getStatistics() async {
    try {
      final Map<dynamic, dynamic> result = await platform.invokeMethod(
        'getStatistics',
      );
      return StreamStatistics.fromMap(Map<String, dynamic>.from(result));
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get statistics: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Enumerate all available cameras on the device
  Future<List<CameraInfo>> getCameras() async {
    try {
      final List<dynamic> result = await platform.invokeMethod('getCameras');
      return result
          .map(
            (camera) => CameraInfo.fromMap(Map<String, dynamic>.from(camera)),
          )
          .toList();
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get cameras: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get available resolutions for a specific camera
  Future<List<Resolution>> getResolutions(String cameraId) async {
    try {
      final List<dynamic> result = await platform.invokeMethod(
        'getResolutions',
        {'cameraId': cameraId},
      );
      return result
          .map((res) => Resolution.fromMap(Map<String, dynamic>.from(res)))
          .toList();
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to get resolutions: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Request microphone permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestMicrophonePermission() async {
    try {
      final bool result =
          await platform.invokeMethod('requestMicrophonePermission');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to request microphone permission: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Check if microphone permission is granted
  Future<bool> hasMicrophonePermission() async {
    try {
      final bool result =
          await platform.invokeMethod('hasMicrophonePermission');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to check microphone permission: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Request camera permission
  /// Returns true if permission is granted, false otherwise
  Future<bool> requestCameraPermission() async {
    try {
      final bool result =
          await platform.invokeMethod('requestCameraPermission');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to request camera permission: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Check if camera permission is granted
  Future<bool> hasCameraPermission() async {
    try {
      final bool result = await platform.invokeMethod('hasCameraPermission');
      return result;
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to check camera permission: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Start foreground service for background streaming (Android only)
  Future<void> startForegroundService() async {
    try {
      await platform.invokeMethod('startForegroundService');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to start foreground service: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Stop foreground service (Android only)
  Future<void> stopForegroundService() async {
    try {
      await platform.invokeMethod('stopForegroundService');
    } on PlatformException catch (e) {
      throw PlatformException(
        code: e.code,
        message: 'Failed to stop foreground service: ${e.message}',
        details: e.details,
      );
    }
  }

  /// Get encoder information including fallback status
  Future<EncoderInfo> getEncoderInfo() async {
    return await _errorService.getEncoderInfo();
  }

  /// Check for overheating based on current temperature
  Future<OverheatingWarning> checkOverheating(double temperature) async {
    return await _errorService.checkOverheating(temperature);
  }

  /// Get overheating thresholds
  Future<OverheatingThresholds> getOverheatingThresholds() async {
    return await _errorService.getOverheatingThresholds();
  }

  /// Get error logs
  Future<List<ErrorInfo>> getErrorLogs({
    int limit = 100,
    String? errorType,
  }) async {
    return await _errorService.getErrorLogs(
      limit: limit,
      errorType: errorType,
    );
  }

  /// Clear error logs
  Future<void> clearErrorLogs() async {
    return await _errorService.clearErrorLogs();
  }

  /// Get user-friendly error message
  String getUserFriendlyMessage(String errorCode) {
    return _errorService.getUserFriendlyMessage(errorCode);
  }

  /// Get troubleshooting steps for error
  List<String> getTroubleshootingSteps(String errorCode) {
    return _errorService.getTroubleshootingSteps(errorCode);
  }

  /// Get encoding latency statistics
  Future<EncodingLatencyStats?> getEncodingLatency() async {
    return await _performanceService?.getEncodingLatency();
  }

  /// Get memory usage statistics
  Future<MemoryUsageStats?> getMemoryUsage() async {
    return await _performanceService?.getMemoryUsage();
  }

  /// Manually adjust bitrate for adaptive streaming
  Future<void> adjustBitrate(int targetBitrate) async {
    if (_performanceService != null) {
      await _performanceService!.adjustBitrate(targetBitrate);
    }
  }

  /// Force cleanup of buffers and memory
  Future<void> forceCleanup() async {
    if (_performanceService != null) {
      await _performanceService!.forceCleanup();
    }
  }

  /// Check if performance optimization is active
  bool get isPerformanceOptimizationActive => _performanceService != null;
}
